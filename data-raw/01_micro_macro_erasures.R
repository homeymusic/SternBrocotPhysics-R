# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_erasures.R")
library(SternBrocotPhysics)

# Drive Path Configuration
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_directory  <- file.path(base_data_dir_4TB, "01_micro_macro_erasures")

if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}

# Simulation Parameters
# 1e6 + 1 ensures we hit the 0.0 midpoint exactly in the mu_source linear spread
microstates_count <- 1e5 + 1

# Granularity p = 0.01; sequence up to 301
granularity_p <- 0.01
normalized_momenta <- seq(1.0, 301, by = granularity_p)

# Status Update
n_files <- length(normalized_momenta)
message(sprintf("Launching mass simulation: %d momentum steps, %s points per step.",
                n_files, format(microstates_count, scientific = FALSE)))
message(sprintf("Target Directory: %s", raw_directory))

# Call the Rcpp API
# Ensure the C++ side has been recompiled with the 'spin' logic removed
SternBrocotPhysics::micro_macro_erasures(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  count     = microstates_count,
  n_threads = 6
)

message("Simulation Complete. Data compressed on SanDisk.")
