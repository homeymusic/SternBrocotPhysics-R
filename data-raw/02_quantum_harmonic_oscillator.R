# 02_quantum_harmonic_oscillator.R
here::i_am("data-raw/02_quantum_harmonic_oscillator.R")

library(data.table)
library(future.apply)

# --- CONFIGURATION ---
RUN_ALL <- TRUE
workers_to_use <- max(1, parallel::detectCores() / 2)
future::plan(future::multisession, workers = workers_to_use)

raw_dir  <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir  <- here::here("data-raw", "outputs", "02_quantum_harmonic_oscillator")
hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_quantum_harmonic_oscillator.csv.gz")

# --- FILE SELECTION ---
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
all_p     <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))

existing_hists <- list.files(hist_dir, pattern = "histogram_P_")
existing_p     <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_hists))

to_process_mask <- !round(all_p, 6) %in% round(existing_p, 6)
files_to_process <- all_files[to_process_mask]

cat("Audit: Found", length(all_files), "raw files.\n")
cat("Audit:", length(existing_p), "histograms exist.\n")
cat("Audit:", length(files_to_process), "new files to process.\n\n")

# --- WORKER LOGIC ---
process_file_full <- function(f, out_path) {
  tryCatch({
    library(data.table)

    P_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(P_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    if (file.exists(full_hist_path)) return(NULL)

    dt <- data.table::fread(f,
                            select = c("found", "fluctuation", "program_length", "shannon_entropy", "numerator", "denominator"),
                            colClasses = c(found="logical", fluctuation="numeric", program_length="integer",
                                           shannon_entropy="numeric", numerator="numeric", denominator="numeric"))

    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    action <- P_val * P_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)

    mean_y <- mean(plot_df$y, na.rm = TRUE)


    # ... (code before this point remains the same, calculating P_val, dt, raw_fluc, plot_df) ...

    mean_y <- mean(plot_df$y, na.rm = TRUE)

    # Reusable function to check Gabor/DC case for any data subset
    is_gabor_dc <- function(data_subset, global_mean) {
      # Uses the original, motivated Gabor/4*pi threshold check
      mean_local <- mean(data_subset$y, na.rm = TRUE)
      return(all(abs(data_subset$y - mean_local) < (global_mean / (4 * pi))))
    }

    # Use the new function for the primary check
    is_dc_case <- is_gabor_dc(plot_df, mean_y)

    if (is_dc_case) {
      node_count_final <- NA_real_
      dot_df <- data.table(x = numeric(0), y = numeric(0))
    } else {
      global_h_range <- max(plot_df$y, na.rm = TRUE) - min(plot_df$y, na.rm = TRUE)

      run_detection <- function(sub_df, scan_dir) {
        if (is.null(sub_df) || nrow(sub_df) < 2 || sum(sub_df$y) == 0) {
          return(data.table(x = numeric(0), y = numeric(0)))
        }
        sub_df <- if(scan_dir == "right") sub_df[order(x), ] else sub_df[order(-x), ]
        total_y <- sum(sub_df$y)
        mean_x <- sum(sub_df$x * sub_df$y) / total_y
        x_sd <- sqrt(sum(sub_df$y * (sub_df$x - mean_x)^2) / total_y)
        thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))

        # Call directly - returns DataFrame
        return(as.data.table(SternBrocotPhysics::find_nodes_cpp(sub_df, thresh, global_h_range)))
      }

      res_r <- run_detection(plot_df[x >= 0], "right")
      res_l <- run_detection(plot_df[x < 0], "left")
      dot_df <- unique(data.table::rbindlist(list(res_l, res_r), fill = TRUE)[complete.cases(x, y)])

      if (nrow(res_l) > 0 && nrow(res_r) > 0) {
        left_inner <- res_l[which.max(x)]
        right_inner <- res_r[which.min(x)]
        gap_df <- plot_df[x > left_inner$x & x < right_inner$x]

        if (nrow(gap_df) >= 2) {
          # Use the new function to check the gap for Gabor DC flatness
          if (is_gabor_dc(gap_df, mean_y)) {
            dot_df <- dot_df[!(abs(x - left_inner$x) < 1e-10 | abs(x - right_inner$x) < 1e-10)]
            y_center <- plot_df$y[which.min(abs(plot_df$x))]
            dot_df <- rbind(dot_df, data.table(x = 0, y = y_center))[order(x)]
          }
        }
      }
      node_count_final <- as.numeric(nrow(dot_df))
    }

    data.table::fwrite(rbind(data.table(type="hist", x=plot_df$x, y=plot_df$y, node_count=node_count_final),
                             data.table(type="node", x=dot_df$x, y=dot_df$y, node_count=node_count_final), fill=TRUE),
                       full_hist_path, compress="gzip")

    num_cols <- names(dt)[sapply(dt, is.numeric)]
    stats_list <- list(normalized_momentum = P_val, node_count = node_count_final, n_found = nrow(dt))
    stats_list <- c(stats_list, setNames(lapply(dt[, ..num_cols], mean, na.rm=TRUE), paste0(num_cols, "_mean")),
                    setNames(lapply(dt[, ..num_cols], median, na.rm=TRUE), paste0(num_cols, "_median")),
                    setNames(lapply(dt[, ..num_cols], sd, na.rm=TRUE), paste0(num_cols, "_sd")))

    return(as.data.table(stats_list))
  }, error = function(e) { message("Worker Error: ", e$message); return(NULL) })
}

# --- EXECUTION ---
if (length(files_to_process) > 0) {
  new_results <- future.apply::future_lapply(files_to_process, process_file_full, out_path = hist_dir,
                                             future.seed = TRUE, future.packages = c("data.table", "SternBrocotPhysics"))
  new_dt <- data.table::rbindlist(new_results, fill = TRUE)

  if (nrow(new_dt) > 0) {
    if (file.exists(summary_file)) {
      final_dt <- unique(rbind(data.table::fread(summary_file), new_dt, fill = TRUE), by = "normalized_momentum")
    } else {
      final_dt <- new_dt
    }
    data.table::fwrite(final_dt[order(normalized_momentum)], summary_file, compress = "gzip")
    message("Success. Summary saved.")
  } else {
    message("No new data processed.")
  }
}
future::plan(future::sequential)
