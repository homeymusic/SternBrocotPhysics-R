library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "01_erasures")
agg_dir <- file.path(base_data_dir_4TB, "02_erasure_distance_densities")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

all_files <- list.files(raw_dir, pattern = "^erasures_P_.*\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "^erasure_distance_density_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)

files_to_process <- all_files[!(all_p_names %in% done_p_names)]

if (length(files_to_process) > 0) {
  message(sprintf("Processing %d new erasure_distance density files...", length(files_to_process)))
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      res <- process_erasure_distance_density(f, out_path = agg_dir)
      p()
      res
    }, future.seed = TRUE)
  })
} else {
  message("All erasure_distance density files are up to date.")
}

plan(sequential)
