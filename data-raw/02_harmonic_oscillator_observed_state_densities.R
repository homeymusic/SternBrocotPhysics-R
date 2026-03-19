library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "01_harmonic_oscillator_erasures")
agg_dir <- file.path(base_data_dir_4TB, "02_harmonic_oscillator_observed_state_densities")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

all_files <- list.files(raw_dir, pattern = "^harmonic_oscillator_erasures_P_.*\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "^harmonic_oscillator_observed_state_density_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("harmonic_oscillator_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("harmonic_oscillator_observed_state_density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)

files_to_process <- all_files[!(all_p_names %in% done_p_names)]

if (length(files_to_process) > 0) {
  message(sprintf("Processing %d new observed_state density files...", length(files_to_process)))
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      # The worker needs to know these functions come from the package
      res <- SternBrocotPhysics::process_observed_state_density(f, out_path = agg_dir)
      p()
      res
    },
    future.seed = TRUE,
    future.packages = c("SternBrocotPhysics", "data.table"))
  })
} else {
  message("All observed_state density files are up to date.")
}

plan(sequential)
