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

# 1. Identify files
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# 2. Worker Function
process_file_full <- function(f, out_path) {
  tryCatch({
    m_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(m_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    # SKIP IF ALREADY DONE
    # If the file exists, we could return NULL or read the summary.
    # To be safe and ensure the summary table is complete, we re-run
    # the summary but skip the fwrite if it's already there.

    action <- m_val * m_val
    dt <- data.table::fread(f, select = c("found", "macrostate", "fluctuation",
                                          "kolmogorov_complexity", "shannon_entropy",
                                          "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    # --- A. GABOR NODE DETECTION ---
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc,
                        breaks = seq(f_rng[1], f_rng[2], length.out = 402),
                        plot = FALSE)
    plot_df <- data.frame(x = h$mids, y = h$counts)

    find_nodes <- function(sub_df, scan_dir) {
      if (is.null(sub_df) || nrow(sub_df) < 2) return(NULL)
      sub_df <- if(scan_dir == "right") sub_df[order(sub_df$x), ] else sub_df[order(-sub_df$x), ]
      h_range <- max(sub_df$y, na.rm = TRUE) - min(sub_df$y, na.rm = TRUE)
      x_mean  <- sum(sub_df$x * sub_df$y) / sum(sub_df$y)
      x_sd    <- sqrt(sum(sub_df$y * (sub_df$x - x_mean)^2) / sum(sub_df$y))
      thresh  <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
      if (h_range < (thresh * mean(sub_df$y, na.rm = TRUE))) return(NULL)

      nodes <- data.frame(x = numeric(0), y = numeric(0))
      ready_to_fire <- TRUE; accumulator <- 0
      for (i in seq_len(nrow(sub_df) - 1)) {
        local_change <- (sub_df$y[i+1] - sub_df$y[i]) / h_range
        accumulator  <- accumulator + local_change
        if (ready_to_fire && accumulator >= thresh) {
          nodes <- rbind(nodes, sub_df[i+1, c("x", "y")]); ready_to_fire <- FALSE; accumulator <- accumulator - thresh
        } else if (!ready_to_fire && accumulator <= -thresh) {
          ready_to_fire <- TRUE; accumulator <- accumulator + thresh
        }
      }
      return(nodes)
    }

    res_r <- find_nodes(plot_df[plot_df$x >= 0, ], "right")
    res_l <- find_nodes(plot_df[plot_df$x < 0, ], "left")

    # Node Labeling Logic
    if (is.null(res_r) || is.null(res_l)) {
      final_node_count <- NA_real_
    } else {
      y_orig <- plot_df$y[which.min(abs(plot_df$x))]
      if(nrow(res_r) > 0 && nrow(res_l) > 0) {
        if(y_orig < res_l$y[which.max(res_l$x)] && y_orig < res_r$y[which.min(res_r$x)]) {
          final_node_count <- 1 + (nrow(res_r)-1) + (nrow(res_l)-1)
        } else {
          final_node_count <- nrow(res_r) + nrow(res_l)
        }
      } else { final_node_count <- nrow(res_r) + nrow(res_l) }
    }

    # --- B. SUMMARY AGGREGATION ---
    summary_dt <- dt[, {
      stats_list <- list(min=lapply(.SD, min), max=lapply(.SD, max), mean=lapply(.SD, mean), sd=lapply(.SD, sd))
      c(list(momentum = m_val, node_count = final_node_count, macro_diversity = uniqueN(macrostate)),
        unlist(stats_list, recursive = FALSE))
    }, .SDcols = c("fluctuation", "kolmogorov_complexity", "shannon_entropy", "zurek_entropy", "numerator", "denominator")]

    # --- C. HISTOGRAM DATA (Only save if missing) ---
    if (!file.exists(full_hist_path)) {
      hist_dt <- data.table(momentum = m_val, x = h$mids, y = h$counts)
      data.table::fwrite(hist_dt, full_hist_path, compress = "gzip")
    }

    return(summary_dt)

  }, error = function(e) {
    message(paste("Error processing file:", f, "\n", e))
    return(NULL)
  })
}

# 3. Execution
message(paste("Processing", length(all_files), "files using", workers_to_use, "cores..."))

results <- future.apply::future_lapply(
  all_files,
  process_file_full,
  out_path = hist_dir,
  future.seed = TRUE,
  future.scheduling = Inf,
  future.packages = c("data.table", "graphics")
)

# 4. Combine and Save Summary
message("Writing aggregated summary file...")
new_summary <- data.table::rbindlist(results, fill = TRUE)
data.table::fwrite(new_summary[order(momentum)], summary_file, compress = "gzip")

message("Processing Complete.")
future::plan(future::sequential)
