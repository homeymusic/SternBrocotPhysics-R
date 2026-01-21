# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

library(data.table)
library(future.apply)
library(Rcpp)

# --- CONFIGURATION ---
target_P <- c(1.0, 1.01, 10.27, 12.12)
workers_to_use <- parallel::detectCores() / 2
future::plan(future::multisession, workers = workers_to_use)

raw_dir  <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir  <- here::here("data-raw", "outputs", "02_aggregated_summary")
hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_aggregated_summary.csv.gz")
all_files    <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# --- WORKER LOGIC ---
process_file_full <- function(f, out_path) {
  if (!exists("find_nodes_cpp")) {
    try(Rcpp::sourceCpp(code = '
      #include <Rcpp.h>
      using namespace Rcpp;
      // [[Rcpp::export]]
      List find_nodes_cpp(DataFrame sub_df, double thresh, double global_h_range) {
        NumericVector x = sub_df["x"]; NumericVector y = sub_df["y"];
        int n = x.size(); std::vector<double> res_x; std::vector<double> res_y;
        bool ready_to_fire = true; double accumulator = 0; double max_acc = 0;
        for(int i = 0; i < (n - 1); ++i) {
          double local_change = (y[i+1] - y[i]) / global_h_range;
          accumulator += local_change;
          if (ready_to_fire) {
            if (accumulator < 0) accumulator = 0;
            if (accumulator > max_acc) max_acc = accumulator;
            if (accumulator >= thresh) {
              res_x.push_back(x[i+1]); res_y.push_back(y[i+1]);
              ready_to_fire = false; accumulator = 0;
            }
          } else {
            if (accumulator > 0) accumulator = 0;
            if (accumulator <= -thresh) {
              ready_to_fire = true; accumulator = 0;
            }
          }
        }
        return List::create(_["nodes"] = DataFrame::create(_["x"] = res_x, _["y"] = res_y),
                            _["max_acc"] = max_acc);
      }
    '))
  }

  tryCatch({
    m_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(m_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    dt <- data.table::fread(f, select = c("found", "macrostate", "fluctuation", "kolmogorov_complexity",
                                          "shannon_entropy", "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    action <- m_val * m_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)
    global_h_range <- max(plot_df$y, na.rm = TRUE) - min(plot_df$y, na.rm = TRUE)

    run_detection <- function(sub_df, scan_dir, label = "") {
      if (is.null(sub_df) || nrow(sub_df) < 2) return(NULL)
      sub_df <- if(scan_dir == "right") sub_df[order(x), ] else sub_df[order(-x), ]
      x_sd <- sqrt(sum(sub_df$y * (sub_df$x - (sum(sub_df$x * sub_df$y)/sum(sub_df$y)))^2) / sum(sub_df$y))
      thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
      out <- find_nodes_cpp(sub_df, thresh, global_h_range)
      if(label != "") {
        message(sprintf("  DEBUG [%s]: Max Acc: %.6f | Gabor Thresh: %.6f | Nodes: %d",
                        label, out$max_acc, thresh, nrow(out$nodes)))
      }
      return(as.data.table(out$nodes))
    }

    message(sprintf("\n--- START Target P: %.2f ---", m_val))
    res_r <- run_detection(plot_df[x >= 0], "right", "Primary Right")
    res_l <- run_detection(plot_df[x < 0], "left", "Primary Left")
    dot_df <- unique(rbind(res_l, res_r, fill = TRUE)[complete.cases(x, y)])

    if (nrow(res_l) > 0 && nrow(res_r) > 0) {
      left_inner  <- res_l[which.max(x)]
      right_inner <- res_r[which.min(x)]
      # EXCLUDE the boundary points (the trough walls) to check only the floor
      gap_df <- plot_df[x > left_inner$x & x < right_inner$x]

      center_scan <- run_detection(gap_df, "right", "Gap Verification")

      if (nrow(center_scan) == 0) {
        message("RESULT: No Gabor Peak in interior gap. MERGING to center.")
        dot_df <- dot_df[!(x == left_inner$x | x == right_inner$x)]
        y_center <- plot_df$y[which.min(abs(plot_df$x))]
        dot_df <- rbind(dot_df, data.table(x = 0, y = y_center))[order(x)]
      } else {
        message("RESULT: Gabor Peak confirmed in interior. KEEPING modes.")
      }
    }

    if (nrow(dot_df) == 0) {
      message("RESULT: Single peak detected. No nodes will be plotted.")
    }

    data.table::fwrite(rbind(data.table(type="hist", x=plot_df$x, y=plot_df$y),
                             data.table(type="node", x=dot_df$x, y=dot_df$y),
                             fill=TRUE), full_hist_path, compress="gzip")

    summary_cols <- c("fluctuation", "kolmogorov_complexity", "shannon_entropy", "zurek_entropy", "numerator", "denominator")
    res_summary <- dt[, {
      means <- lapply(.SD, mean); sds <- lapply(.SD, sd)
      c(list(momentum = m_val, node_count = nrow(dot_df)), means, sds)
    }, .SDcols = summary_cols]
    return(res_summary)
  }, error = function(e) {
    message(sprintf("ERROR on P %.2f: %s", m_val, conditionMessage(e))); return(NULL)
  })
}

# --- FORCED EXECUTION ---
all_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
files_to_process <- all_files[sapply(all_momenta, function(m) any(abs(m - target_P) < 1e-7))]

if (length(files_to_process) > 0) {
  results <- future.apply::future_lapply(files_to_process, process_file_full, out_path = hist_dir, future.seed = TRUE)
  new_summary <- data.table::rbindlist(results, fill = TRUE)
  data.table::fwrite(new_summary[order(momentum)], summary_file, compress = "gzip")
}
message("\n--- PROCESSING COMPLETE ---")
