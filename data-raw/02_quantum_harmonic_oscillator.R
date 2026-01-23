# 02_quantum_harmonic_oscillator.R
here::i_am("data-raw/02_quantum_harmonic_oscillator.R")

library(data.table)
library(future.apply)
library(Rcpp)

# --- CONFIGURATION ---
RUN_ALL <- TRUE # We use this to determine the pool, but logic below handles skips
workers_to_use <- max(1, parallel::detectCores() - 1)
future::plan(future::multisession, workers = workers_to_use)

raw_dir  <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir  <- here::here("data-raw", "outputs", "02_quantum_harmonic_oscillator")
hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_aggregated_summary.csv.gz")

# --- FILE SELECTION & SKIP LOGIC ---
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
all_p     <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))

# 1. Identify which histograms already exist
existing_hists <- list.files(hist_dir, pattern = "histogram_P_")
existing_p     <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_hists))

# 2. Determine which files actually need processing
# We process if: The histogram file is missing OR it's not in our summary
to_process_mask <- !round(all_p, 6) %in% round(existing_p, 6)
files_to_process <- all_files[to_process_mask]

cat("Audit: Found", length(all_files), "raw files.\n")
cat("Audit:", length(existing_p), "histograms already exist.\n")
cat("Audit:", length(files_to_process), "new files to process.\n\n")

# --- WORKER LOGIC ---
process_file_full <- function(f, out_path) {
  # Re-source C++ inside worker if needed
  if (!exists("find_nodes_cpp", mode = "function")) {
    Rcpp::sourceCpp(code = '
      #include <Rcpp.h>
      using namespace Rcpp;
      // [[Rcpp::export]]
      List find_nodes_cpp(DataFrame sub_df, double thresh, double global_h_range) {
        NumericVector x = sub_df["x"]; NumericVector y = sub_df["y"];
        int n = x.size(); std::vector<double> res_x; std::vector<double> res_y;
        bool ready_to_fire = true; double accumulator = 0;
        for(int i = 0; i < (n - 1); ++i) {
          double local_change = (y[i+1] - y[i]) / global_h_range;
          accumulator += local_change;
          if (ready_to_fire) {
            if (accumulator < -thresh) accumulator = -thresh;
            if (accumulator >= thresh) { res_x.push_back(x[i+1]); res_y.push_back(y[i+1]); ready_to_fire = false; accumulator = 0; }
          } else {
            if (accumulator > thresh) accumulator = thresh;
            if (accumulator <= -thresh) { ready_to_fire = true; accumulator = 0; }
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

    # Double check skip inside worker for safety
    if (file.exists(full_hist_path)) return(NULL)

    dt <- data.table::fread(f, select = c("found", "fluctuation", "kolmogorov_complexity",
                                          "shannon_entropy", "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    action <- P_val * P_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)

    mean_y <- mean(plot_df$y, na.rm = TRUE)
    is_dc_case <- all(abs(plot_df$y - mean_y) < (mean_y / (4 * pi)))

    if (is_dc_case) {
      node_count_final <- NA_real_
      dot_df <- data.table(x = numeric(0), y = numeric(0))
    } else {
      global_h_range <- max(plot_df$y, na.rm = TRUE) - min(plot_df$y, na.rm = TRUE)
      run_detection <- function(sub_df, scan_dir) {
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
      node_count_final <- as.numeric(nrow(dot_df))
    }

    # Save Histogram
    data.table::fwrite(rbind(data.table(type="hist", x=plot_df$x, y=plot_df$y, node_count=node_count_final),
                             data.table(type="node", x=dot_df$x, y=dot_df$y, node_count=node_count_final), fill=TRUE),
                       full_hist_path, compress="gzip")

    # Return Summary Row
    summary_cols <- setdiff(names(dt), "found")
    return(dt[, c(list(max_momentum = P_val, node_count = node_count_final),
                  setNames(lapply(.SD, mean, na.rm=TRUE), paste0(summary_cols, "_mean")),
                  setNames(lapply(.SD, sd, na.rm=TRUE),   paste0(summary_cols, "_sd"))), .SDcols = summary_cols])
  }, error = function(e) return(NULL))
}

# --- EXECUTION ---
if (length(files_to_process) > 0) {
  new_results <- future.apply::future_lapply(files_to_process, process_file_full, out_path = hist_dir, future.seed = TRUE)
  new_dt <- data.table::rbindlist(new_results, fill = TRUE)

  # Merge with existing summary if it exists
  if (file.exists(summary_file)) {
    old_dt <- data.table::fread(summary_file)
    final_dt <- rbind(old_dt, new_dt, fill = TRUE)
    final_dt <- unique(final_dt, by = "max_momentum") # Safety deduplication
  } else {
    final_dt <- new_dt
  }

  data.table::fwrite(final_dt[order(max_momentum)], summary_file, compress = "gzip")
  message("Update Complete.")
} else {
  message("Nothing new to process.")
}

future::plan(future::sequential)
