library(SternBrocotPhysics)
library(data.table)

# Kept exactly as you requested
data_dir <- "/Volumes/SanDisk4TB/SternBrocot-data/06_bell_test"

if (dir.exists(data_dir)) {
  unlink(data_dir, recursive = TRUE)
}
dir.create(data_dir, recursive = TRUE)

alice_angles_rad <- c(0.0, pi/2) + 1e-5
bob_angles_rad   <- seq(0, 2 * pi, by = 0.01) + 1e-5

message("Generating non-local paired simulation data...")

# The combinatorial sweep generating the paired contextual datasets
for (alpha in alice_angles_rad) {
  non_local_bell_sweep(
    alice_angle_rad = alpha,
    bob_angles_rad = bob_angles_rad,
    dir = normalizePath(data_dir),
    count = 10000L,
    microstate_start = 0.0,
    microstate_end = 2*pi,
    n_threads = 6L
  )
}

message("Calculating Bell correlations...")
all_files <- list.files(data_dir, pattern = "bell_pair_.*\\.csv\\.gz", full.names = TRUE)

correlation_summary <- rbindlist(lapply(all_files, function(f) {

  # Pull the angles directly from the data file, completely ignoring the filename
  dt <- fread(f, select = c("alice_angle", "bob_angle", "alice_spin", "bob_spin"))

  alpha_val <- dt$alice_angle[1]
  beta_val  <- dt$bob_angle[1]

  # Standard expectation value calculation E(alpha, beta)
  correlation <- mean(dt$alice_spin * dt$bob_spin)

  data.table(
    alice_angle_rad = alpha_val,
    bob_angle_rad = beta_val,
    correlation = correlation
  )
}))

# Map to independent variable for standard Bell test plotting
correlation_summary[, relative_angle := (bob_angle_rad - alice_angle_rad) %% (2 * pi)]
setorder(correlation_summary, alice_angle_rad, relative_angle)

fwrite(correlation_summary, file.path(data_dir, "summary_stats.csv.gz"))
message("Done! The non-local geometric engine has finished computing.")
