library(SternBrocotPhysics)
library(data.table)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot-data/06_bell_test"

# --- 1. DIRECTORY MANAGEMENT ---
# Ensure we start with a clean slate to avoid mixing old/new simulation data
if (dir.exists(data_dir)) {
  unlink(data_dir, recursive = TRUE)
}
dir.create(data_dir, recursive = TRUE)

# --- 2. RUN SIMULATION ---
alice_angles_rad <- c(0.0, pi/2) + 1e-5
bob_angles_rad   <- seq(0, 2 * pi, by = 0.01) + 1e-5

message("Generating raw simulation data...")
# Both sweep identical microstates (0 to 2π) to preserve the non-linear erasure math!
micro_macro_bell_erasure_sweep('alice', alice_angles_rad, normalizePath(data_dir), 1e4, 0, 2*pi, 6)
micro_macro_bell_erasure_sweep('bob', bob_angles_rad, normalizePath(data_dir), 1e4, 0, 2*pi, 6)

# --- 3. DYNAMIC DATA DISCOVERY ---
all_files   <- list.files(data_dir, pattern = "erasure_.*\\.csv\\.gz")
alice_files <- grep("alice", all_files, value = TRUE)
bob_files   <- grep("bob", all_files, value = TRUE)

parse_angle <- function(file_names) {
  # FIX: Non-greedy regex that correctly captures negative wrapped angles
  extracted_strings <- gsub("erasure_[^_]+_([-0-9.]+)\\.csv\\.gz", "\\1", file_names)
  as.numeric(extracted_strings)
}
# --- 4. DATA REFLECTION & JOIN ---
message("Reflecting on filesystem to build summary...")

# Name the vector with itself so the resulting list is keyed by the exact filenames
names(alice_files) <- alice_files

# Load Alice data
alice_data_list <- lapply(alice_files, function(f) {
  fread(file.path(data_dir, f), select = c("spin", "found"))
})

# Extract numeric angles and find the indices of the smallest and largest
alice_numeric_angles <- parse_angle(alice_files)
sorted_idx           <- order(alice_numeric_angles)

# Grab the exact filenames corresponding to ~0 rad and ~1.57 rad
file_key_0  <- alice_files[sorted_idx[1]]
file_key_90 <- alice_files[sorted_idx[2]]

correlation_summary <- rbindlist(lapply(bob_files, function(bob_file) {

  current_bob_angle <- parse_angle(bob_file)
  bob_dt <- fread(file.path(data_dir, bob_file), select = c("spin", "found"))

  # Access Alice frames flawlessly using the filename keys
  alice_0  <- alice_data_list[[file_key_0]]
  alice_90 <- alice_data_list[[file_key_90]]

  # Coincidence masks
  mask_0  <- alice_0$found  & bob_dt$found
  mask_90 <- alice_90$found & bob_dt$found

  data.table(
    bob_angle_rad        = current_bob_angle,
    correlation_alice_0  = -mean(as.numeric(alice_0$spin[mask_0])  * as.numeric(bob_dt$spin[mask_0]), na.rm = TRUE),
    correlation_alice_90 = -mean(as.numeric(alice_90$spin[mask_90]) * as.numeric(bob_dt$spin[mask_90]), na.rm = TRUE)
  )
}))

# --- 5. PREP FOR RMD & PERSIST ---
# Calculate the phase difference for the Alice 90° plot
correlation_summary[, phase_diff_90 := (bob_angle_rad - pi/2) %% (2 * pi)]

# Sort geometrically by the phase difference
setorder(correlation_summary, phase_diff_90)

fwrite(correlation_summary, file.path(data_dir, "summary_stats.csv.gz"))

# FIX: Use the new file_key variables for the print statement
message(sprintf("Done. Summary built using Alice files: %s and %s", file_key_0, file_key_90))
