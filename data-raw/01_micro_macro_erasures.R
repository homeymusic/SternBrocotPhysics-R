# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_erasures.R")
library(SternBrocotPhysics)


base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_directory  <- file.path(base_data_dir_4TB, "01_micro_macro_erasures")

# Final Parameters
microstates_count <- 1e6 + 1
normalized_momenta <- seq(0.0025, 301, by = 0.0025)

message("Launching mass simulation to SanDisk...")
message("Estimated storage required: ~600 GB")

# Using 6 threads to balance speed with external drive I/O overhead
SternBrocotPhysics::run_erasure_simulation(
  momenta = normalized_momenta,
  dir = normalizePath(raw_directory, mustWork = TRUE),
  count = microstates_count,
  n_threads = 6
)

message("Simulation Complete. All 120,400 files generated.")
