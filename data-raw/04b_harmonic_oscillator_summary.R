library(data.table)
library(future.apply)

# --- 1. Configuration ---
# Set up parallel workers just like the main summary script
plan(multisession, workers = parallel::detectCores() - 2)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_02_densities  <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

if (!dir.exists(dir_04_summary)) dir.create(dir_04_summary, recursive = TRUE)

# ==============================================================================
# ERASURE DISPLACEMENT DISTRIBUTIONS (For Action Grid Plot)
# ==============================================================================
message("\n=== Aggregating Erasure Displacement Distributions ===")

file_summary_out_disp <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_distribution_summary.csv.gz")

pattern_str_disp <- "^harmonic_oscillator_erasure_displacement_density_.*_P_.*\\.csv\\.gz$"
files_disp_densities <- list.files(dir_02_densities, pattern = pattern_str_disp, full.names = TRUE)

if (length(files_disp_densities) == 0) {
  stop("\n❌ CRITICAL ERROR: No density files found for erasure_displacement. Ensure Step 2 completed successfully. Halting pipeline.")
}

message(sprintf("Processing %d density files for erasure displacement distributions...", length(files_disp_densities)))

dt_summary_disp <- rbindlist(future_lapply(files_disp_densities, function(f) {
  tryCatch({
    dt <- fread(f)
    if (nrow(dt) == 0) return(NULL)

    P_val <- dt$normalized_momentum[1]
    A_val <- P_val^2

    # 1. Recover Physical Erasure Displacement (epsilon)
    # Scale by the geometric capacity as dictated by Eq 22: epsilon = q / A
    dt[, coordinate_q := coordinate_q * (pi / 2) / P_val]

    total_states <- sum(dt$density_count)

    # 2. Weighted statistical calculations on the PHYSICAL displacement
    mean_val <- sum(dt$coordinate_q * dt$density_count) / total_states
    sd_val <- sqrt(sum(dt$density_count * (dt$coordinate_q - mean_val)^2) / total_states)

    # 3. Standard Median
    setorder(dt, coordinate_q)
    dt[, cum_prop := cumsum(density_count) / total_states]
    median_val <- dt[cum_prop >= 0.5, min(coordinate_q)]

    # 4. Median of the Absolute Values (Magnitude)
    dt_abs <- dt[, .(density_count = sum(density_count)), by = .(abs_q = abs(coordinate_q))]
    setorder(dt_abs, abs_q)
    dt_abs[, cum_prop := cumsum(density_count) / total_states]
    median_abs_val <- dt_abs[cum_prop >= 0.5, min(abs_q)]

    data.table(
      normalized_momentum = P_val,
      action_A    = A_val,
      mean_disp   = mean_val,
      median_disp = median_val,
      median_abs_disp = median_abs_val,
      sd_disp     = sd_val,
      min_disp    = min(dt$coordinate_q),
      max_disp    = max(dt$coordinate_q),
      n_states    = total_states
    )
  }, error = function(e) return(NULL))
}, future.seed = TRUE))

if (nrow(dt_summary_disp) > 0) {
  setorder(dt_summary_disp, normalized_momentum)

  dt_summary_disp[, upper := mean_disp + sd_disp]
  dt_summary_disp[, lower := mean_disp - sd_disp]

  fwrite(dt_summary_disp, file_summary_out_disp, compress = "gzip")
  message(sprintf("  -> Saved %d rows to %s", nrow(dt_summary_disp), basename(file_summary_out_disp)))
} else {
  stop("\n❌ CRITICAL ERROR: Density files were found, but data aggregation resulted in 0 rows. Halting pipeline.")
}

# Close parallel workers cleanly
plan(sequential)
message("\n✅ Erasure displacement distribution summary generated successfully.")
