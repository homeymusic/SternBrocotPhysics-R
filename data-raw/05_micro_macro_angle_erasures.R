# 05_micro_macro_angle_erasures.R
here::i_am("data-raw/05_micro_macro_angle_erasures.R")
library(SternBrocotPhysics)

# --- DIRECTORY SETUP ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_directory  <- file.path(base_data_dir_4TB, "05_micro_macro_angle_erasures")

if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}

# --- RESUME AUDIT ---
existing_files <- list.files(raw_directory, pattern = "theta_.*\\.csv\\.gz$")
processed_angles <- if(length(existing_files) > 0) {
  as.numeric(gsub("micro_macro_erasures_theta_([0-9.]+)\\.csv\\.gz", "\\1", existing_files))
} else numeric(0)

# 0.1 degree resolution creates the high-fidelity "Important Plot"
full_sweep <- seq(0, 90, by = 0.1)
angles_to_run <- full_sweep[!sapply(full_sweep, function(a) any(abs(a - processed_angles) < 1e-7))]

if (length(angles_to_run) == 0) {
  stop("Audit Complete: All 901 angular experiments already exist on disk.")
}

cat("Audit: Found", length(processed_angles), "completed experiments.\n")
cat("Focus: Executing", length(angles_to_run), "remaining experiments.\n\n")

# --- EXECUTION ---
microstates_count <- 1e6 + 1

SternBrocotPhysics::micro_macro_erasures_angle(
  angles   = angles_to_run,
  dir      = normalizePath(raw_directory, mustWork = TRUE),
  count    = microstates_count,
  n_threads = 6
)

message("Success. 05 dataset generated with full theta-indexed Landauer metadata.")
