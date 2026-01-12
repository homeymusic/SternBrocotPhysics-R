# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

library(data.table)
library(future.apply)

# Setup Parallel Plan
workers_to_use <- 4
future::plan(future::multisession, workers = workers_to_use)

# Directories
raw_dir <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir <- here::here("data-raw", "outputs", "02_aggregated_summary")
if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)
summary_file <- file.path(agg_dir, "02_aggregated_summary.csv.gz")

# 1. Identify files and detect existing progress
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

if (file.exists(summary_file)) {
  existing_summary <- data.table::fread(summary_file)
  existing_momenta <- existing_summary$momentum
  # Extract momentum from filenames to compare
  file_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
  new_files <- all_files[!(file_momenta %in% existing_momenta)]
} else {
  existing_summary <- NULL
  new_files <- all_files
}

if (length(new_files) == 0) {
  future::plan(future::sequential)
  stop("No new experiment files found to aggregate.")
}

# 2. Worker function
process_file_summary <- function(f) {
  # Fix: Extract m_val here so it is available in the function scope
  m_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))

  target_cols <- c(
    "fluctuation", "kolmogorov_complexity", "shannon_entropy",
    "zurek_entropy", "numerator", "denominator"
  )

  # Momentum is added in Script 01 via cbind, so we read it or use m_val
  dt <- data.table::fread(f, select = c("macrostate", "found", target_cols))

  # Fast logical filter
  dt <- dt[found == TRUE]
  if (nrow(dt) == 0) return(NULL)

  # Single-pass aggregation
  # We pass m_val into the list explicitly
  summary_dt <- dt[, {
    stats_list <- list(
      min    = lapply(.SD, min, na.rm = TRUE),
      max    = lapply(.SD, max, na.rm = TRUE),
      total  = lapply(.SD, sum, na.rm = TRUE),
      mean   = lapply(.SD, mean, na.rm = TRUE),
      median = lapply(.SD, median, na.rm = TRUE),
      sd     = lapply(.SD, sd, na.rm = TRUE)
    )

    # Combine momentum and diversity with the flattened stats
    c(list(momentum = m_val, macro_diversity = uniqueN(macrostate)),
      unlist(stats_list, recursive = FALSE))
  }, .SDcols = target_cols]

  stats_names <- c("min", "max", "total", "mean", "median", "sd")
  new_names <- c("momentum", "macro_diversity", as.vector(outer(target_cols, stats_names, paste, sep = "_")))
  setnames(summary_dt, new_names)

  return(summary_dt)
}

# 3. Process with future.apply
message(paste("Processing", length(new_files), "new files..."))

new_summary_dt <- data.table::rbindlist(future.apply::future_lapply(
  new_files,
  process_file_summary,
  future.seed = TRUE,
  future.packages = c("data.table")
), use.names = TRUE, fill = TRUE)

# 4. Final Merge, Sort, and Save
if (nrow(new_summary_dt) > 0) {
  final_summary_dt <- data.table::rbindlist(list(existing_summary, new_summary_dt), use.names = TRUE, fill = TRUE)

  data.table::fwrite(
    final_summary_dt[order(momentum)],
    file = summary_file,
    compress = "gzip"
  )
  message("Update Complete. Total records in summary: ", nrow(final_summary_dt))
} else {
  message("No new valid data found in processed files.")
}

future::plan(future::sequential)
