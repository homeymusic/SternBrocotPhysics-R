# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

library(data.table)
library(future.apply)

# --- CONFIGURATION ---
workers_to_use <- parallel::detectCores() / 2
future::plan(future::multisession, workers = workers_to_use)

raw_dir  <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir  <- here::here("data-raw", "outputs", "02_aggregated_summary")
hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_aggregated_summary.csv.gz")
all_files    <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# --- THE WORKER ---
process_file_full <- function(f, out_path) {
  # 1. Ensure Rcpp is compiled inside the worker if not present
  if (!exists("find_nodes_cpp")) {
    Rcpp::cppFunction('
    DataFrame find_nodes_cpp(DataFrame sub_df, double thresh, double h_range) {
      NumericVector x = sub_df["x"]; NumericVector y = sub_df["y"];
      int n = x.size(); std::vector<double> res_x; std::vector<double> res_y;
      bool ready_to_fire = true; double accumulator = 0;
      for(int i = 0; i < (n - 1); ++i) {
        double local_change = (y[i+1] - y[i]) / h_range;
        accumulator += local_change;
        if (ready_to_fire) {
          if (accumulator >= thresh) {
            res_x.push_back(x[i+1]); res_y.push_back(y[i+1]);
            ready_to_fire = false; accumulator -= thresh;
          }
          if (accumulator < 0) accumulator = 0;
        } else {
          if (accumulator <= -thresh) {
            ready_to_fire = true; accumulator += thresh;
          }
          if (accumulator > 0) accumulator = 0;
        }
      }
      return DataFrame::create(_["x"] = res_x, _["y"] = res_y);
    }')
  }

  tryCatch({
    m_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(m_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    # 2. Load Data
    dt <- data.table::fread(f, select = c("found", "macrostate", "fluctuation", "kolmogorov_complexity",
                                          "shannon_entropy", "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    # 3. Histogram & Logic
    action <- m_val * m_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.frame(x = h$mids, y = h$counts)

    # Helper to wrap the C++ call
    run_detection <- function(sub_df, scan_dir) {
      if (is.null(sub_df) || nrow(sub_df) < 2) return(NULL)
      sub_df <- if(scan_dir == "right") sub_df[order(sub_df$x), ] else sub_df[order(-sub_df$x), ]
      h_range <- max(sub_df$y, na.rm = TRUE) - min(sub_df$y, na.rm = TRUE)
      x_sd <- sqrt(sum(sub_df$y * (sub_df$x - (sum(sub_df$x * sub_df$y)/sum(sub_df$y)))^2) / sum(sub_df$y))
      thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
      if (h_range < (thresh * mean(sub_df$y, na.rm = TRUE))) return(NULL)
      return(find_nodes_cpp(sub_df, thresh, h_range))
    }

    res_r <- run_detection(plot_df[plot_df$x >= 0, ], "right")
    res_l <- run_detection(plot_df[plot_df$x < 0, ], "left")

    # 4. Node Labeling
    if (is.null(res_r) || is.null(res_l)) {
      final_node_count <- NA_real_
    } else {
      y_orig <- plot_df$y[which.min(abs(plot_df$x))]
      in_l_y <- if(nrow(res_l) > 0) res_l$y[which.max(res_l$x)] else 0
      in_r_y <- if(nrow(res_r) > 0) res_r$y[which.min(res_r$x)] else 0
      if(y_orig < in_l_y && y_orig < in_r_y) {
        final_node_count <- 1 + (nrow(res_r)-1) + (nrow(res_l)-1)
      } else {
        final_node_count <- nrow(res_r) + nrow(res_l)
      }
    }

    # 5. Save Histogram IMMEDIATELY
    if (!file.exists(full_hist_path)) {
      data.table::fwrite(data.table(momentum = m_val, x = h$mids, y = h$counts), full_hist_path, compress = "gzip")
    }

    # 6. Return summary
    return(dt[, {
      stats_list <- list(min=lapply(.SD, min), max=lapply(.SD, max), mean=lapply(.SD, mean), sd=lapply(.SD, sd))
      c(list(momentum = m_val, node_count = final_node_count, macro_diversity = uniqueN(macrostate)),
        unlist(stats_list, recursive = FALSE))
    }, .SDcols = c("fluctuation", "kolmogorov_complexity", "shannon_entropy", "zurek_entropy", "numerator", "denominator")])

  }, error = function(e) {
    # If it fails, we want to know why
    cat("Error in file", f, ":", conditionMessage(e), "\n")
    return(NULL)
  })
}

# --- EXECUTION ---
message("Starting background processing. Monitor the histograms folder for updates...")

results <- future.apply::future_lapply(
  all_files,
  process_file_full,
  out_path = hist_dir,
  future.seed = TRUE,
  future.scheduling = Inf, # Essential for real-time file creation
  future.packages = c("data.table", "Rcpp")
)

new_summary <- data.table::rbindlist(results, fill = TRUE)
data.table::fwrite(new_summary[order(momentum)], summary_file, compress = "gzip")
message("Done.")
