# 05_micro_macro_angle_erasures.R
here::i_am("data-raw/05_micro_macro_angle_erasures.R")
library(SternBrocotPhysics)

# --- DIRECTORY SETUP ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_directory  <- file.path(base_data_dir_4TB, "05_micro_macro_angle_erasures")

if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}

# --- RESUME AUDIT (ROBUST) ---
# List all Alpha and Beta files separately
files_alpha <- list.files(raw_directory, pattern = "micro_macro_erasures_alpha_([0-9.]+)\\.csv\\.gz$")
files_beta  <- list.files(raw_directory, pattern = "micro_macro_erasures_beta_([0-9.]+)\\.csv\\.gz$")

# Extract the angle values from filenames
extract_angles <- function(filenames, prefix) {
  if (length(filenames) == 0) return(numeric(0))
  # Regex to capture the number between the specific prefix and .csv.gz
  pattern <- paste0(prefix, "([0-9.]+)\\.csv\\.gz")
  as.numeric(gsub(pattern, "\\1", filenames))
}

angles_alpha <- extract_angles(files_alpha, "micro_macro_erasures_alpha_")
angles_beta  <- extract_angles(files_beta,  "micro_macro_erasures_beta_")

# Valid angles must exist in BOTH lists (intersection)
# If an angle is in Alpha but not Beta (or vice versa), it will be re-run.
completed_angles <- intersect(angles_alpha, angles_beta)

# --- NEW SWEEP DEFINITION ---
# 60,200 points avoiding exactly 0 and 90 to prevent division by zero in the math
N_points <- 120400 / 2
offset <- 1 / N_points / 2
full_sweep <- seq(offset, 90 - offset, length.out = N_points)

# Filter: Keep angles that are NOT in the completed set (using tolerance)
# We recreate the file if either pair is missing to ensure synchronization
angles_to_run <- full_sweep[!sapply(full_sweep, function(a) any(abs(a - completed_angles) < 1e-7))]

if (length(angles_to_run) == 0) {
  stop("Audit Complete: All angular experiment pairs (Alpha & Beta) verify as present.")
}

cat("Audit Summary:\n")
cat("  - Alpha files found:", length(angles_alpha), "\n")
cat("  - Beta files found: ", length(angles_beta), "\n")
cat("  - Complete pairs:   ", length(completed_angles), "\n")
cat("Focus: Executing", length(angles_to_run), "missing or incomplete pairs.\n\n")

# --- EXECUTION ---
microstates_count <- 1e6 + 1

SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = angles_to_run,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  count     = microstates_count,
  n_threads = 6
)

message("Success. 05 dataset generated/repaired with synchronized Alpha/Beta symplectic capacities.")
