library(future)
# Use all available cores minus 1 (to keep the system responsive)
plan(multisession, workers = parallel::detectCores() - 2)

# --- CONFIGURATION ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_dir  <- file.path(base_data_dir_4TB, "01_micro_macro_erasures")
agg_dir  <- file.path(base_data_dir_4TB, "02_quantum_harmonic_oscillator")

hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_quantum_harmonic_oscillator.csv.gz")

# --- FULL FILE SELECTION WITH IDEMPOTENCY ---
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# Identify already processed files to skip them
existing_hists <- list.files(hist_dir, pattern = "histogram_P_.*\\.csv\\.gz$")
processed_p <- if(length(existing_hists) > 0) {
  as.numeric(gsub("histogram_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_hists))
} else numeric(0)

# Extract P values from all raw files for comparison
all_p <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))

# Filter: Only process files where the histogram does not yet exist
# Using a small tolerance (1e-7) for floating point P-value matching
files_to_process <- all_files[!sapply(all_p, function(x) any(abs(x - processed_p) < 1e-7))]

# Audit info
cat("Audit: Found", length(all_files), "total raw files.\n")
cat("Audit: Skipping", length(all_files) - length(files_to_process), "already processed files.\n")
cat("Focus Audit: Processing", length(files_to_process), "remaining files.\n\n")

# --- WORKER LOGIC ---
process_file_full <- function(f, out_path) {
  # Define is_near locally so future workers reliably find it
  is_near <- function(a, b) abs(a - b) < 1e-10

  tryCatch({
    library(data.table)
    library(SternBrocotPhysics) # Explicitly load inside worker

    P_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(P_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    if (file.exists(full_hist_path)) return(NULL)

    dt <- data.table::fread(f,
                            select = c("found", "fluctuation", "program_length", "shannon_entropy", "numerator", "denominator"),
                            # Changed to integer to stop fread warnings
                            colClasses = c(found="integer", fluctuation="numeric", program_length="integer",
                                           shannon_entropy="numeric", numerator="numeric", denominator="numeric"))

    # Coerce to logical to match your dt[found == TRUE] filter
    dt[, found := as.logical(found)]
    dt <- dt[found == TRUE]

    if (nrow(dt) == 0) return(NULL)

    action <- P_val * P_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    # FIX: Reverted to explicit indices for worker compatibility
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)

    # Use is_near function consistently here for robust zero-snapping
    plot_df[is_near(x, 0), x := 0]

    # Reusable function to check Gabor/DC case for any data subset (for N=NA check)
    is_gabor_dc <- function(data_subset) {
      if (nrow(data_subset) < 2 || sum(data_subset$y) == 0) return(TRUE)
      total_y <- sum(data_subset$y)
      mean_x <- sum(data_subset$x * data_subset$y) / total_y
      x_sd <- sqrt(sum(data_subset$y * (data_subset$x - mean_x)^2) / total_y)
      gabor_thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
      local_mean <- mean(data_subset$y, na.rm = TRUE)
      return(all(abs(data_subset$y - local_mean) < gabor_thresh * local_mean))
    }

    is_dc_case <- is_gabor_dc(plot_df)

    if (is_dc_case) {
      node_count_final <- NA_real_
      dot_df <- data.table(x = numeric(0), y = numeric(0))
    } else {
      global_h_range <- max(plot_df$y, na.rm = TRUE) - min(plot_df$y, na.rm = TRUE)

      # --- SYMMETRY FIX: Calculate threshold once for the full data ---
      total_y_global <- sum(plot_df$y)
      mean_x_global  <- sum(plot_df$x * plot_df$y) / total_y_global
      x_sd_global    <- sqrt(sum(plot_df$y * (plot_df$x - mean_x_global)^2) / total_y_global)
      global_thresh  <- (1 / (4 * pi)) / (1 + sqrt(x_sd_global))


      run_detection <- function(sub_df, scan_dir, use_thresh) {
        if (is.null(sub_df) || nrow(sub_df) < 2 || sum(sub_df$y) == 0) {
          return(data.table(x = numeric(0), y = numeric(0)))
        }
        sub_df <- if(scan_dir == "right") sub_df[order(x), ] else sub_df[order(-x), ]
        thresh <- use_thresh
        return(as.data.table(SternBrocotPhysics::find_nodes_cpp(sub_df, thresh, global_h_range)))
      }

      res_r <- run_detection(plot_df[x > 0], "right", use_thresh = global_thresh)
      res_l <- run_detection(plot_df[x < 0], "left",  use_thresh = global_thresh)

      # unique() handles merging the potential overlapping node at x=0
      dot_df <- unique(data.table::rbindlist(list(res_l, res_r), fill = TRUE)[complete.cases(x, y)])

      # --- CLEANED UP GAP LOGIC ---
      if (nrow(res_l) > 0 && nrow(res_r) > 0) {
        left_inner <- res_l[which.max(x)]
        right_inner <- res_r[which.min(x)]
        gap_df <- plot_df[x > left_inner$x & x < right_inner$x]

        if (nrow(gap_df) >= 2) {
          # Use the global threshold here too
          thresh_gap <- global_thresh

          if (!SternBrocotPhysics::contains_peak_cpp(gap_df, thresh_gap, global_h_range)) {
            dot_df   <- dot_df[!(is_near(x, left_inner$x) | is_near(x, right_inner$x))]
            y_center <- plot_df$y[which.min(abs(plot_df$x))]
            dot_df   <- rbind(dot_df, data.table(x = 0, y = y_center))[order(x)]
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
  # Call future.apply explicitly
  new_results <- future.apply::future_lapply(files_to_process,
                                             process_file_full,
                                             out_path = hist_dir,
                                             future.seed = TRUE,
                                             future.packages = c("data.table", "SternBrocotPhysics"),
                                             future.scheduling = 100)
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
