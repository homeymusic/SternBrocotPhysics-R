library(SternBrocotPhysics)
library(data.table)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot-data/06_bell_test"

# --- 1. DIRECTORY MANAGEMENT (The Fix) ---
# Ensure we start with a clean slate to avoid mixing old/new simulation data
if (dir.exists(data_dir)) {
  unlink(data_dir, recursive = TRUE)
}
dir.create(data_dir, recursive = TRUE)

# --- 2. RUN SIMULATION ---
alice_angles_rad <- c(0.0, pi/2) + 1e-5
bob_angles_rad   <- seq(0, 2 * pi, by = 0.01) + 1e-5

message("Generating raw simulation data...")
micro_macro_bell_erasure_sweep('alice', alice_angles_rad, normalizePath(data_dir), 1e4, 0, 2*pi, 6)
micro_macro_bell_erasure_sweep('bob', bob_angles_rad, normalizePath(data_dir), 1e4, 0, 2*pi, 6)

# --- 3. DYNAMIC DATA DISCOVERY ---
all_files   <- list.files(data_dir, pattern = "erasure_.*\\.csv\\.gz")
alice_files <- grep("alice", all_files, value = TRUE)
bob_files   <- grep("bob", all_files, value = TRUE)

parse_angle <- function(file_names) {
  as.numeric(gsub("erasure_.*_([0-9.]*)\\.csv\\.gz", "\\1", file_names))
}

# --- 4. DATA REFLECTION & JOIN ---
message("Reflecting on filesystem to build summary...")

# Load Alice data
alice_data_list <- lapply(alice_files, function(f) {
  fread(file.path(data_dir, f), select = c("spin", "found"))
})

# Extract numeric angles, then assign string versions as list names
alice_numeric_angles <- parse_angle(alice_files)
names(alice_data_list) <- as.character(alice_numeric_angles)

# CRITICAL FIX: Sort the numbers mathematically, not lexicographically
sorted_numeric_angles <- sort(alice_numeric_angles)
key_0  <- as.character(sorted_numeric_angles[1]) # The smaller angle (~0 rad)
key_90 <- as.character(sorted_numeric_angles[2]) # The larger angle (~1.57 rad)

correlation_summary <- rbindlist(lapply(bob_files, function(bob_file) {

  current_bob_angle <- parse_angle(bob_file)
  bob_dt <- fread(file.path(data_dir, bob_file), select = c("spin", "found"))

  # Access Alice frames by key
  alice_0  <- alice_data_list[[key_0]]
  alice_90 <- alice_data_list[[key_90]]

  # Coincidence masks
  mask_0  <- alice_0$found  & bob_dt$found
  mask_90 <- alice_90$found & bob_dt$found

  # Note on Singlet State:
  # Using the negative sign to artificially simulate anti-alignment.
  data.table(
    bob_angle_rad        = current_bob_angle,
    correlation_alice_0  = -mean(as.numeric(alice_0$spin[mask_0])  * as.numeric(bob_dt$spin[mask_0])),
    correlation_alice_90 = -mean(as.numeric(alice_90$spin[mask_90]) * as.numeric(bob_dt$spin[mask_90]))
  )
}))

# --- 5. PERSIST ---
fwrite(correlation_summary, file.path(data_dir, "summary_stats.csv.gz"))
message(sprintf("Done. Summary built using Alice angles: %s and %s", key_0, key_90))
