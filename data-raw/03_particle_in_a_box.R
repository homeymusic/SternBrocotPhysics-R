# 03_particle_in_a_box.R
here::i_am("data-raw/03_particle_in_a_box.R")

library(data.table)
library(future.apply)
library(Rcpp)

# --- CONFIGURATION ---
DEBUG_MODE <- FALSE
RUN_ALL    <- FALSE
original_P <- c(0.5, 1.01, 2.01, 3.5, 10.27, 12.12, 25.47)
sampled_P  <- seq(0.01, 300, length.out = 10)

# Combine, round to 2 digits, sort, and remove duplicates
target_P <- sort(unique(round(c(original_P, sampled_P), 2)))
# normalized_momentum_step <- 0.01
# normalized_momentum_min  <- 0.0 + normalized_momentum_step
# normalized_momentum_max  <- 35
# target_P       <- seq(from = normalized_momentum_min,
#                       to = normalized_momentum_max,
#                       by = normalized_momentum_step)


workers_to_use <- max(1, parallel::detectCores() - 1)
future::plan(future::multisession, workers = workers_to_use)

raw_dir  <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir  <- here::here("data-raw", "outputs", "03_particle_in_a_box")
hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "03_aggregated_summary.csv.gz")
all_files    <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# --- WORKER LOGIC ---
process_file_full <- function(f, out_path, debug_on) {

  if (!exists("find_nodes_cpp", mode = "function")) {
    Rcpp::sourceCpp(code = '
      #include <Rcpp.h>
      using namespace Rcpp;
      // [[Rcpp::export]]
      List find_nodes_cpp(DataFrame sub_df, double thresh, double global_h_range) {
        NumericVector x = sub_df["x"];
        NumericVector y = sub_df["y"];
        int n = x.size();
        std::vector<double> res_x;
        std::vector<double> res_y;
        bool ready_to_fire = true;
        double accumulator = 0;

        for(int i = 0; i < (n - 1); ++i) {
          double local_change = (y[i+1] - y[i]) / global_h_range;
          accumulator += local_change;

          if (ready_to_fire) {
            if (accumulator < -thresh) accumulator = -thresh;
            if (accumulator >= thresh) {
              res_x.push_back(x[i+1]);
              res_y.push_back(y[i+1]);
              ready_to_fire = false;
              accumulator = 0;
            }
          } else {
            if (accumulator > thresh) accumulator = thresh;
            if (accumulator <= -thresh) {
              ready_to_fire = true;
              accumulator = 0;
            }
          }
        }
        return List::create(_["nodes"] = DataFrame::create(_["x"] = res_x, _["y"] = res_y));
      }
    ')

  }

  tryCatch({
    P_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(P_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    dt <- data.table::fread(f, select = c("found", "fluctuation", "kolmogorov_complexity",
                                          "shannon_entropy", "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    # --- UPDATED DYNAMIC BINNING + JITTER FILTER ---
    L <- 1.0
    action <- P_val * 1.0
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)

    # 1. Scale resolution and oversample for anti-aliasing headroom
    target_bins <- round(402 * max(1, sqrt(P_val)))
    oversample <- 11

    # 2. Create high-res master tile
    h_single <- graphics::hist(raw_fluc,
                               breaks = seq(f_rng[1], f_rng[2], length.out = (target_bins * oversample)),
                               plot = FALSE)

    # 3. Tile the histogram P times
    num_tiles <- max(1, floor(P_val / L))
    tiled_counts <- rep(h_single$counts, times = num_tiles)
    tiled_mids <- seq(f_rng[1], f_rng[2], length.out = length(tiled_counts))
    tiled_hist <- data.table(x = tiled_mids, y = tiled_counts)

    # 4. Rebin and Smooth (Digital Low-Pass Filter)
    bins_per_group <- num_tiles * oversample
    tiled_hist[, bin_group := rep(1:target_bins, each = bins_per_group, length.out = .N)]

    # Aggregate to target resolution
    plot_df <- tiled_hist[, .(x = mean(x), y = sum(y)), by = bin_group]

    # Apply 5-bin rolling mean to suppress jitter before node detection
    # Using data.table::frollmean for high performance
    plot_df[, y := data.table::frollmean(y, n = 5, align = "center", fill = mean(y, na.rm=TRUE))]
    plot_df <- plot_df[, .(x, y)]


    mean_y <- mean(plot_df$y, na.rm = TRUE)
    is_dc_case <- all(abs(plot_df$y - mean_y) < (mean_y / (4 * pi)))

    if (is_dc_case) {
      node_count_final <- NA_real_
      dot_df <- data.table(x = numeric(0), y = numeric(0))
    } else {
      global_h_range <- max(plot_df$y, na.rm = TRUE) - min(plot_df$y, na.rm = TRUE)
      run_detection <- function(sub_df, scan_dir, label = "") {
        if (is.null(sub_df) || nrow(sub_df) < 2) return(NULL)
        sub_df <- if(scan_dir == "right") sub_df[order(x), ] else sub_df[order(-x), ]
        x_sd <- sqrt(sum(sub_df$y * (sub_df$x - (sum(sub_df$x * sub_df$y)/sum(sub_df$y)))^2) / sum(sub_df$y))
        thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
        out <- find_nodes_cpp(sub_df, thresh, global_h_range)
        return(as.data.table(out$nodes))
      }
      res_r <- run_detection(plot_df[x >= 0], "right")
      res_l <- run_detection(plot_df[x < 0], "left")
      dot_df <- unique(rbind(res_l, res_r, fill = TRUE)[complete.cases(x, y)])

      if (nrow(res_l) > 0 && nrow(res_r) > 0) {
        left_inner <- res_l[which.max(x)]
        right_inner <- res_r[which.min(x)]
        gap_df <- plot_df[x > left_inner$x & x < right_inner$x]
        center_scan <- run_detection(gap_df, "right")
        if (nrow(center_scan) == 0) {
          dot_df <- dot_df[!(x == left_inner$x | x == right_inner$x)]
          y_center <- plot_df$y[which.min(abs(plot_df$x))]
          dot_df <- rbind(dot_df, data.table(x = 0, y = y_center))[order(x)]
        }
      }
      node_count_final <- as.numeric(nrow(dot_df))
    }

    # --- BACKWARD COMPATIBLE FILE SAVE ---
    # We add 'node_count' as a proper column to all types
    hist_out <- data.table(type="hist", x=plot_df$x, y=plot_df$y, node_count=node_count_final)
    node_out <- data.table(type="node", x=dot_df$x, y=dot_df$y, node_count=node_count_final)

    data.table::fwrite(rbind(hist_out, node_out, fill=TRUE), full_hist_path, compress="gzip")

    # --- SUMMARY AGGREGATION ---
    summary_cols <- setdiff(names(dt), "found")
    res_dt <- dt[, c(
      list(max_momentum = P_val, node_count = node_count_final),
      setNames(lapply(.SD, mean, na.rm=TRUE),   paste0(summary_cols, "_mean")),
      setNames(lapply(.SD, median, na.rm=TRUE), paste0(summary_cols, "_median")),
      setNames(lapply(.SD, min, na.rm=TRUE),    paste0(summary_cols, "_min")),
      setNames(lapply(.SD, max, na.rm=TRUE),    paste0(summary_cols, "_max")),
      setNames(lapply(.SD, sd, na.rm=TRUE),     paste0(summary_cols, "_sd"))
    ), .SDcols = summary_cols]

    return(res_dt)
  }, error = function(e) { return(NULL) })
}

# --- EXECUTION LOGIC ---
all_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
files_to_process <- if(RUN_ALL) all_files else all_files[sapply(all_momenta, function(m) any(abs(m - target_P) < 1e-7))]

if (length(files_to_process) > 0) {
  results <- future.apply::future_lapply(files_to_process, process_file_full, out_path = hist_dir, debug_on = DEBUG_MODE, future.seed = TRUE)
  final_dt <- data.table::rbindlist(results, fill = TRUE)
  data.table::fwrite(final_dt[order(max_momentum)], summary_file, compress = "gzip")
  message("Done.")
}
