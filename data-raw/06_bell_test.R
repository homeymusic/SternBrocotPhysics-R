library(SternBrocotPhysics)
library(data.table)

data_dir <- "/Volumes/SanDisk4TB/SternBrocot-data/06_bell_test_nonlocal"

if (dir.exists(data_dir)) {
  unlink(data_dir, recursive = TRUE)
}
dir.create(data_dir, recursive = TRUE)

alice_angles_rad <- c(0.0, pi/2) + 1e-5
bob_angles_rad   <- seq(0, 2 * pi, by = 0.01) + 1e-5

message("Generating non-local paired simulation data...")

# Sweep over each of Alice's angles against all of Bob's angles
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
  # Extract alpha and beta from the filename
  file_name <- basename(f)
  alpha_val <- as.numeric(sub(".*alpha_([-0-9.]+)_beta.*", "\\1", file_name))
  beta_val  <- as.numeric(sub(".*beta_([-0-9.]+)\\.csv\\.gz", "\\1", file_name))

  dt <- fread(f, select = c("alice_spin", "bob_spin"))

  # Calculate the correlation E(alpha, beta) for this specific setup
  correlation <- mean(dt$alice_spin * dt$bob_spin)

  data.table(
    alice_angle_rad = alpha_val,
    bob_angle_rad = beta_val,
    correlation = correlation
  )
}))

# Prepare for plotting
correlation_summary[, relative_angle := (bob_angle_rad - alice_angle_rad) %% (2 * pi)]
setorder(correlation_summary, alice_angle_rad, relative_angle)

fwrite(correlation_summary, file.path(data_dir, "nonlocal_summary_stats.csv.gz"))
message("Done! Ready to plot the CHSH curve.")
