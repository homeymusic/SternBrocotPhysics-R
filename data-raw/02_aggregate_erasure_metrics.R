# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

library(data.table)
library(future.apply)
library(Rcpp)

# --- CONFIGURATION ---
target_P <- c(10.27, 12.12)
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
      }
    '))
  }

  tryCatch({
    m_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(m_val, 6))
    full_hist_path <- file.path(out_path, hist_name)
    if(file.exists(full_hist_path)) file.remove(full_hist_path)

    dt <- data.table::fread(f, select = c("found", "macrostate", "fluctuation", "kolmogorov_complexity",
                                          "shannon_entropy", "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    action <- m_val * m_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)

    run_detection <- function(sub_df, scan_dir) {
      if (is.null(sub_df) || nrow(sub_df) < 2) return(NULL)
      sub_df <- if(scan_dir == "right") sub_df[order(x), ] else sub_df[order(-x), ]
      h_range <- max(sub_df$y, na.rm = TRUE) - min(sub_df$y, na.rm = TRUE)
      x_sd <- sqrt(sum(sub_df$y * (sub_df$x - (sum(sub_df$x * sub_df$y)/sum(sub_df$y)))^2) / sum(sub_df$y))
      thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
      return(as.data.table(find_nodes_cpp(sub_df, thresh, h_range)))
    }

    # 1. Scans: moving AWAY from center
    res_r <- run_detection(plot_df[x >= 0], "right")
    res_l <- run_detection(plot_df[x < 0], "left")
    dot_df <- unique(rbind(res_l, res_r, fill = TRUE)[complete.cases(x, y)])

    # 2. Peak logic: Just trust the scans.
    # If the center is a trough (10.27), both scans will find a node near x=0.
    # If the center is a peak (12.12), scans will skip the center and find nodes further out.
    if (nrow(dot_df) == 0) {
      y_center <- plot_df$y[which.min(abs(plot_df$x))]
      dot_df <- data.table(x = 0, y = y_center)
    }

    final_node_count <- nrow(dot_df)
    data.table::fwrite(rbind(data.table(type="hist", node_count=final_node_count, x=plot_df$x, y=plot_df$y),
                             data.table(type="node", node_count=final_node_count, x=dot_df$x, y=dot_df$y),
                             fill=TRUE), full_hist_path, compress="gzip")

    summary_cols <- c("fluctuation", "kolmogorov_complexity", "shannon_entropy", "zurek_entropy", "numerator", "denominator")
    res_summary <- dt[, {
      means <- lapply(.SD, mean); sds <- lapply(.SD, sd); mins <- lapply(.SD, min); maxs <- lapply(.SD, max); meds <- lapply(.SD, median)
      names(means) <- paste0(names(means), "_mean"); names(sds) <- paste0(names(sds), "_sd")
      names(mins) <- paste0(names(mins), "_min"); names(maxs) <- paste0(names(maxs), "_max"); names(meds) <- paste0(names(meds), "_median")
      c(list(momentum = m_val, node_count = final_node_count, macro_diversity = uniqueN(macrostate)),
        means, sds, mins, maxs, meds)
    }, .SDcols = summary_cols]

    return(res_summary)
  }, error = function(e) {
    message(paste("Failed on:", f, conditionMessage(e))); return(NULL)
  })
}

# --- FORCED EXECUTION ---
all_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
files_to_process <- all_files[sapply(all_momenta, function(m) any(abs(m - target_P) < 1e-7))]

if (length(files_to_process) > 0) {
  message(sprintf("Processing %d requested files...", length(files_to_process)))
  results <- future.apply::future_lapply(files_to_process, process_file_full, out_path = hist_dir, future.seed = TRUE, future.scheduling = 1)
  new_summary <- data.table::rbindlist(results, fill = TRUE)
  if (file.exists(summary_file)) {
    existing <- data.table::fread(summary_file)
    existing <- existing[!sapply(momentum, function(m) any(abs(m - target_P) < 1e-7))]
    new_summary <- rbind(existing, new_summary, fill = TRUE)
  }
  data.table::fwrite(new_summary[order(momentum)], summary_file, compress = "gzip")
}
message("Done.")
