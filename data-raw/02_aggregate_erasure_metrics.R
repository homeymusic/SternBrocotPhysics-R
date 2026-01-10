# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

# 1. Critical Build/Load (Mirrors 01 Script)
devtools::install(quick = TRUE, upgrade = "never")
library(SternBrocotPhysics)
library(data.table)
library(future.apply)

# 2. Parallel Setup
future::plan(future::multisession, workers = parallel::detectCores() - 1)

# 3. Path Management
raw_dir <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
agg_dir <- here::here("data-raw", "outputs", "02_aggregated_summary")
if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

file_list <- list.files(raw_dir, pattern = "micro_macro_erasures_P_.*\\.csv\\.gz", full.names = TRUE)

# 4. Processing Logic
process_file_summary <- function(f) {
  dt <- data.table::fread(f)

  # Diversity + Physics Stats
  target_cols <- c("fluctuation", "kolmogorov_complexity", "shannon_entropy")

  summary_dt <- dt[, c(
    .(momentum = momentum,
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

  return(summary_dt)
}

# 5. Parallel Execution
final_summary_dt <- rbindlist(future.apply::future_lapply(
  file_list,
  process_file_summary,
  future.seed = TRUE,
  future.packages = c("data.table", "SternBrocotPhysics")
))

# 6. Save Compressed Result
data.table::fwrite(
  final_summary_dt[order(momentum)],
  file = file.path(agg_dir, "erasure_metrics_summary.csv.gz"),
  compress = "gzip"
)

future::plan(future::sequential)
message("Success: Summary saved to ", agg_dir)
