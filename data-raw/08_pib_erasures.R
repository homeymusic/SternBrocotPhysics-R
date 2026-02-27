here::i_am("data-raw/08_pib_erasures.R")
library(SternBrocotPhysics)

# Drive Path
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory  <- file.path(base_data_dir_4TB, "08_pib_erasures")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# --- CONFIGURATION: SCALING FROM FIRST PRINCIPLES ---
normalized_momenta <- c(0.5, 1:6)

message(sprintf("Launching Dynamic Simulation."))
message(sprintf("Total Files: %d", length(normalized_momenta)))

# Call the Updated C++ API
pib_erasures(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  n_threads = 6
)

message("Dynamic Simulation Complete.")
