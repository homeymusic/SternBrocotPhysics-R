here::i_am("data-raw/01_harmonic_oscillator_erasures.R")
library(SternBrocotPhysics)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory  <- file.path(base_data_dir_4TB, "01_harmonic_oscillator_erasures")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

granularity_p <- 0.001
normalized_momenta <- seq(0.1, 10.0, by = granularity_p)

message(sprintf("Launching Dynamic Simulation."))
message(sprintf("Total Files: %d", length(normalized_momenta)))

# Explicitly request the engine (matches the new C++ API)
harmonic_oscillator_erasures(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  algorithm = "stern_brocot",
  n_threads = 6
)

message("Dynamic Simulation Complete.")
