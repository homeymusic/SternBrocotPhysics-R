# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_momentum_erasures.R")
library(SternBrocotPhysics)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_directory  <- file.path(base_data_dir_4TB, "01_micro_macro_momentum_erasures")

# --- ADD THIS SAFETY CHECK ---
if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}
# -----------------------------

# Final Parameters
# Final Parameters
microstates_count <- 1e6 + 1

# We start at 0.0025, which acts as our effective "momentum granularity"
# preventing the singularity at p=0 (Infinite Uncertainty).
granularity_p <- 0.0025
normalized_momenta <- seq(granularity_p, 301, by = granularity_p)
message("Launching mass simulation to SanDisk...")

SternBrocotPhysics::micro_macro_erasures_momentum(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  count     = microstates_count,
  n_threads = 6
)

message("Simulation Complete.")
