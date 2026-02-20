library(data.table)
library(future.apply)

# --- 1. Configuration ---
plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir  <- file.path(base_data_dir_4TB, "02_program_length_densities")
summary_file <- file.path(base_data_dir_4TB, "04_program_length_summary.csv.gz")

# --- 2. Collection ---
message("Calculating weighted statistics from density files...")

all_density_files <- list.files(density_dir, pattern = "^program_length_density_P_.*\\.csv\\.gz$", full.names = TRUE)

if (length(all_density_files) == 0) {
  stop("No density files found. Run Script 02 first.")
}

# --- 3. Statistical Aggregation ---
# We process in parallel because calculating weighted medians/SDs for thousands of files adds up.
summary_dt <- rbindlist(future_lapply(all_density_files, function(f) {
  tryCatch({
    dt <- fread(f)
    if (nrow(dt) == 0) return(NULL)

    # 1. Total count of microstates
    total_n <- sum(dt$density_count)

    # 2. Weighted Mean
    mean_len <- sum(dt$coordinate_q * dt$density_count) / total_n

    # 3. Weighted Standard Deviation (The "Spread")
    sd_len <- sqrt(sum(dt$density_count * (dt$coordinate_q - mean_len)^2) / total_n)

    # 4. Weighted Median
    setorder(dt, coordinate_q)
    dt[, cum_prop := cumsum(density_count) / total_n]
    median_len <- dt[cum_prop >= 0.5, min(coordinate_q)]

    data.table(
      normalized_momentum = dt$normalized_momentum[1],
      mean_len   = mean_len,
      median_len = median_len,
      sd_len     = sd_len,
      n_states   = total_n
    )
  }, error = function(e) return(NULL))
}))

# --- 4. Finalize & Save ---
if (nrow(summary_dt) > 0) {
  setorder(summary_dt, normalized_momentum)

  # Calculate ribbon bounds here for convenience in plotting
  summary_dt[, upper := mean_len + sd_len]
  summary_dt[, lower := pmax(0, mean_len - sd_len)]

  fwrite(summary_dt, summary_file, compress = "gzip")
  message(sprintf("Success. Summary for %d steps saved to: %s", nrow(summary_dt), summary_file))
}
plan(sequential)
