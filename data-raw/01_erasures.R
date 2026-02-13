here::i_am("data-raw/01_erasures.R")
library(SternBrocotPhysics)

# Drive Path
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory  <- file.path(base_data_dir_4TB, "01_erasures_dynamic")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# --- CONFIGURATION: SCALING FROM FIRST PRINCIPLES ---
granularity_p <- 0.01
normalized_momenta <- seq(1.0, 101.0, by = granularity_p)

message(sprintf("Launching Dynamic Simulation."))
message(sprintf("Total Files: %d", length(normalized_momenta)))

# Call the Updated C++ API
SternBrocotPhysics::erasures(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  n_threads = 6
)

message("Dynamic Simulation Complete.")
