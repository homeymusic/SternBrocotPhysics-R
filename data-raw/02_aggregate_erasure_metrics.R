# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

devtools::install(quick = TRUE, upgrade = "never")
library(data.table)
library(future.apply)

# Setup Parallel Plan
workers_to_use <- 4
future::plan(future::multisession, workers = workers_to_use)

# Directories
raw_dir <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir <- here::here("data-raw", "outputs", "02_aggregated_summary")
summary_file <- file.path(agg_dir, "02_aggregated_summary.csv.gz")

# 1. Identify files to process
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

if (file.exists(summary_file)) {
  existing_summary <- data.table::fread(summary_file)
  existing_momenta <- existing_summary$momentum
  file_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
  new_files <- all_files[!(file_momenta %in% existing_momenta)]
} else {
  existing_summary <- NULL
  new_files <- all_files
}

if (length(new_files) == 0) {
  stop("No new experiment files found to aggregate.")
}

# 2. Worker function with updated measures and filtering
process_file_summary <- function(f) {
  # Added new measures and 'found' for filtering
  target_cols <- c(
    "fluctuation", "kolmogorov_complexity", "shannon_entropy",
    "numerator", "denominator", "fisher_N2", "fisher_N4",
    "symplectic_capacity", "winding_number", "phase_density"
  )
  needed_cols <- c("momentum", "macrostate", "found", target_cols)

  dt <- data.table::fread(f, select = needed_cols)

  # Filter for found = TRUE
  dt <- dt[found == TRUE | found == "TRUE"]

  if (nrow(dt) == 0) return(NULL)

  summary_dt <- dt[, c(
    .(momentum = momentum[1],
      macro_diversity = uniqueN(macrostate)),
    lapply(.SD, min, na.rm = TRUE),
    lapply(.SD, max, na.rm = TRUE),
    lapply(.SD, sum, na.rm = TRUE),
    lapply(.SD, mean, na.rm = TRUE),
    lapply(.SD, median, na.rm = TRUE),
    lapply(.SD, sd, na.rm = TRUE)
  ), .SDcols = target_cols]

  stats <- c("min", "max", "total", "mean", "median", "sd")
  new_names <- c("momentum", "macro_diversity", as.vector(outer(target_cols, stats, paste, sep = "_")))
  setnames(summary_dt, new_names)

  rm(dt); gc()
  return(summary_dt)
}

# 3. Process
message(paste("Processing", length(new_files), "new files..."))
new_summary_dt <- data.table::rbindlist(future.apply::future_lapply(
  new_files,
  process_file_summary,
  future.seed = TRUE,
  future.packages = c("data.table")
), use.names = TRUE, fill = TRUE)

# 4. Merge and save
final_summary_dt <- data.table::rbindlist(list(existing_summary, new_summary_dt), use.names = TRUE, fill = TRUE)

data.table::fwrite(
  final_summary_dt[order(momentum)],
  file = summary_file,
  compress = "gzip"
)

future::plan(future::sequential)
message("Update Complete. Total records in summary: ", nrow(final_summary_dt))
