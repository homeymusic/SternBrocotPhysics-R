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

# --- NEW SWEEP DEFINITION (0 to 180) ---
# We split ~120k files between Alice and Bob.
# Range: 0 to 180 degrees (Spin 1/2 coverage).

# DEFINE THE PHYSICAL CONSTANT
granularity <- 1e-5  # The fundamental resolution of the universe

# 1. Generate the ideal mathematical points
N_points <- 60200
ideal_sweep <- seq(0, 180, length.out = N_points)

# 2. Apply the granularity offset to EVERY point
# This shifts 0.0 -> 0.00001, 90.0 -> 90.00001, etc.
# This guarantees we never hit a singularity while keeping the spacing uniform.
full_sweep <- ideal_sweep + granularity

# --- FAST AUDIT LOGIC ---
# Instead of slow loops, convert to high-precision strings for set comparison
sig_figs <- 7
sweep_char <- sprintf(paste0("%.", sig_figs, "f"), full_sweep)
completed_char <- sprintf(paste0("%.", sig_figs, "f"), completed_angles)

# Find missing angles by set difference
missing_char <- setdiff(sweep_char, completed_char)
angles_to_run <- as.numeric(missing_char)

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
