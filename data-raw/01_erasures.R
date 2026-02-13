here::i_am("data-raw/01_erasures.R")
library(SternBrocotPhysics)

# Drive Path
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_directory  <- file.path(base_data_dir_4TB, "01_erasures_dynamic")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# --- CONFIGURATION: SCALING FROM FIRST PRINCIPLES ---
granularity_p <- 0.01
normalized_momenta <- seq(1.0, 301.0, by = granularity_p)

total_microstates <- sum(as.numeric(counts_vec))
message(sprintf("Launching Dynamic Simulation."))
message(sprintf("Total Files: %d", length(normalized_momenta)))
message(sprintf("Total Microstates: %s (approx 3x previous density)", format(total_microstates, scientific=FALSE)))

# Call the Updated C++ API
SternBrocotPhysics::erasures(
  momenta   = normalized_momenta,
  dir       = normalizePath(raw_directory, mustWork = TRUE),
  n_threads = 6
)

message("Dynamic Simulation Complete.")
