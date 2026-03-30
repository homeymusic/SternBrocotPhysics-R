library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

# --- 1. Configuration ---
# Add any future metrics you want to analyze to this vector!
target_cols <- c("erasure_distance", "minimal_action_state", "minimal_program_length")

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "01_harmonic_oscillator_erasures")
agg_dir <- file.path(base_data_dir_4TB, "02_harmonic_oscillator_densities")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

# --- 2. File Matching & Skip Logic ---
# FIX: Accept the algorithm string between 'erasures_' and '_P_'
all_raw_files <- list.files(raw_dir, pattern = "^harmonic_oscillator_erasures_.*_P_.*\\.csv\\.gz$", full.names = TRUE)

# We only want to read a massive raw CSV if one of its target density files is missing
files_to_process <- Filter(function(f) {
  base_f <- basename(f)

  # FIX: Safely extract both algorithm and momentum
  matches <- regmatches(base_f, regexec("harmonic_oscillator_erasures_(.*)_P_([0-9.]+)\\.csv\\.gz", base_f))

  if (length(matches[[1]]) == 3) {
    algo_str <- matches[[1]][2]
    p_str    <- matches[[1]][3]

    # Check if ALL target columns have already been processed for this momentum AND algorithm
    all_exist <- all(sapply(target_cols, function(col) {
      file.exists(file.path(agg_dir, sprintf("harmonic_oscillator_%s_density_%s_P_%s.csv.gz", col, algo_str, p_str)))
    }))

    return(!all_exist)
  }

  # If the regex fails to match, process it just to be safe
  return(TRUE)
}, all_raw_files)

# --- 3. Parallel Execution ---
if (length(files_to_process) > 0) {
  message(sprintf("Processing %d raw files for columns: %s",
                  length(files_to_process),
                  paste(target_cols, collapse = ", ")))

  with_progress({
    p <- progressor(steps = length(files_to_process))

    future_lapply(files_to_process, function(f) {

      # The package function handles the single-read and multi-column density computation
      # (Including the algorithmic bypass for minimal_program_length)
      res <- process_action_densities(f, out_path = agg_dir, target_cols = target_cols)

      p()
      res
    },
    future.seed = TRUE,
    future.packages = c("SternBrocotPhysics", "data.table"))
  })
} else {
  message("All density files for all target columns are up to date.")
}

plan(sequential)
