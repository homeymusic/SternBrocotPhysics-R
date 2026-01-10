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
summary_file <- file.path(agg_dir, "erasure_metrics_summary.csv.gz")

# 1. Identify files to process
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# If an existing summary exists, only process files NOT already in it
if (file.exists(summary_file)) {
  existing_summary <- data.table::fread(summary_file)
  existing_momenta <- existing_summary$momentum

  # Extract momentum from filename to filter (assumes format: ...P_000000.000000.csv.gz)
  file_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
  new_files <- all_files[!(file_momenta %in% existing_momenta)]
} else {
  existing_summary <- NULL
  new_files <- all_files
}

if (length(new_files) == 0) {
  stop("No new experiment files found to aggregate.")
}

# 2. Worker function (unchanged logic)
process_file_summary <- function(f) {
  needed_cols <- c("momentum", "macrostate", "fluctuation",
                   "kolmogorov_complexity", "shannon_entropy")

  dt <- data.table::fread(f, select = needed_cols)
  target_cols <- c("fluctuation", "kolmogorov_complexity", "shannon_entropy")

  summary_dt <- dt[, c(
    .(momentum = momentum[1],
      macro_diversity = uniqueN(macrostate)),
    lapply(.SD, min),
    lapply(.SD, max),
    lapply(.SD, sum),
    lapply(.SD, mean),
    lapply(.SD, median),
    lapply(.SD, sd)
  ), .SDcols = target_cols]

  stats <- c("min", "max", "total", "mean", "median", "sd")
  new_names <- c("momentum", "macro_diversity", as.vector(outer(target_cols, stats, paste, sep = "_")))
  setnames(summary_dt, new_names)

  rm(dt); gc()
  return(summary_dt)
}

# 3. Process new files and combine
message(paste("Processing", length(new_files), "new files..."))
new_summary_dt <- data.table::rbindlist(future.apply::future_lapply(
  new_files,
  process_file_summary,
  future.seed = TRUE,
  future.packages = c("data.table")
))

# 4. Merge with existing data and save
final_summary_dt <- data.table::rbindlist(list(existing_summary, new_summary_dt), use.names = TRUE)

data.table::fwrite(
  final_summary_dt[order(momentum)],
  file = summary_file,
  compress = "gzip"
)

future::plan(future::sequential)
message("Update Complete. Total records in summary: ", nrow(final_summary_dt))
