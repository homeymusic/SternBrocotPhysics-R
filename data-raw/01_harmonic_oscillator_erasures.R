here::i_am("data-raw/01_harmonic_oscillator_erasures.R")
library(SternBrocotPhysics)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory  <- file.path(base_data_dir_4TB, "01_harmonic_oscillator_erasures")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# --- NEW: UNIFORM ACTION SAMPLING ---
# Step linearly through Action space to ensure uniform data density on the plots
granularity_a <- 0.01
action_sequence <- seq(1.0, 100.0, by = granularity_a)

# Convert to Momentum (P = sqrt(A)) for the C++ engine
normalized_momenta <- sqrt(action_sequence)

message(sprintf("Launching Dynamic Simulation (Uniform Action Space)."))
message(sprintf("Total Files: %d", length(normalized_momenta)))

# Explicitly request the engine (matches the new C++ API)
harmonic_oscillator_erasures(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  algorithm = "stern_brocot",
  n_threads = 6
)

message("Dynamic Simulation Complete.")
