library(data.table)
library(future.apply)

# --- 1. Configuration ---
cols_topological <- c("erasure_distance", "minimal_action_state")
cols_algorithmic <- c("minimal_program_length")

plan(multisession, workers = parallel::detectCores() - 2)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_02_densities  <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes      <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")

dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")
if (!dir.exists(dir_04_summary)) dir.create(dir_04_summary, recursive = TRUE)

# ==============================================================================
# PART A: TOPOLOGICAL METRICS (Nodes & Complexity)
# ==============================================================================
message("\n=== Aggregating Topological Summaries ===")

for (col in cols_topological) {
  message(sprintf("Processing summary for: %s", col))

  file_summary_out <- file.path(dir_04_summary, sprintf("harmonic_oscillator_%s_summary.csv.gz", col))

  pattern_str <- sprintf("^harmonic_oscillator_%s_nodes_.*_P_.*\\.csv\\.gz$", col)
  files_nodes <- list.files(dir_03_nodes, pattern = pattern_str, full.names = TRUE)

  if (length(files_nodes) == 0) {
    warning(sprintf("  -> No node files found for %s. Skipping.", col))
    next
  }

  dt_summary <- rbindlist(lapply(files_nodes, function(f) {
    tryCatch({
      # Request snr_metric instead of complexity_ntv
      fread(f, select = c("normalized_momentum", "node_count", "snr_metric"), nrows = 1)
    }, error = function(e) return(NULL))
  }), fill = TRUE)

  if (nrow(dt_summary) > 0) {
    # Clean and Sort on the new variable
    dt_summary <- dt_summary[!is.na(snr_metric)]
    setorder(dt_summary, normalized_momentum)

    fwrite(dt_summary, file_summary_out, compress = "gzip")
    message(sprintf("  -> Saved %d rows to %s", nrow(dt_summary), basename(file_summary_out)))
  }
}

# ==============================================================================
# PART B: ALGORITHMIC METRICS (Weighted Distributions)
# ==============================================================================
message("\n=== Aggregating Algorithmic Summaries ===")

for (col in cols_algorithmic) {
  message(sprintf("Processing summary for: %s", col))

  file_summary_out <- file.path(dir_04_summary, sprintf("harmonic_oscillator_%s_summary.csv.gz", col))

  pattern_str <- sprintf("^harmonic_oscillator_%s_density_.*_P_.*\\.csv\\.gz$", col)
  files_densities <- list.files(dir_02_densities, pattern = pattern_str, full.names = TRUE)

  if (length(files_densities) == 0) {
    warning(sprintf("  -> No density files found for %s. Skipping.", col))
    next
  }

  dt_summary <- rbindlist(future_lapply(files_densities, function(f) {
    tryCatch({
      dt <- fread(f)
      if (nrow(dt) == 0) return(NULL)

      total_states <- sum(dt$density_count)
      mean_val <- sum(dt$coordinate_q * dt$density_count) / total_states
      sd_val <- sqrt(sum(dt$density_count * (dt$coordinate_q - mean_val)^2) / total_states)

      setorder(dt, coordinate_q)
      dt[, cum_prop := cumsum(density_count) / total_states]
      median_val <- dt[cum_prop >= 0.5, min(coordinate_q)]

      data.table(
        normalized_momentum = dt$normalized_momentum[1],
        mean_len   = mean_val,
        median_len = median_val,
        sd_len     = sd_val,
        n_states   = total_states
      )
    }, error = function(e) return(NULL))
  }, future.seed = TRUE))

  if (nrow(dt_summary) > 0) {
    setorder(dt_summary, normalized_momentum)

    dt_summary[, upper := mean_len + sd_len]
    dt_summary[, lower := pmax(0, mean_len - sd_len)]

    fwrite(dt_summary, file_summary_out, compress = "gzip")
    message(sprintf("  -> Saved %d rows to %s", nrow(dt_summary), basename(file_summary_out)))
  }
}

# ==============================================================================
# PART C: THERMODYNAMIC METRICS (Resonance Margin)
# ==============================================================================
message("\n=== Aggregating Thermodynamic Summaries ===")

dir_01_raw <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
file_summary_out_res <- file.path(dir_04_summary, "harmonic_oscillator_resonance_margin_summary.csv.gz")

pattern_str_raw <- "^harmonic_oscillator_erasures_P_.*\\.csv\\.gz$"
files_raw <- list.files(dir_01_raw, pattern = pattern_str_raw, full.names = TRUE)

if (length(files_raw) == 0) {
  warning("  -> No raw erasure files found. Skipping Resonance Margin.")
} else {
  message(sprintf("Processing Resonance Margin from %d raw files...", length(files_raw)))

  dt_summary_res <- rbindlist(future_lapply(files_raw, function(f) {
    tryCatch({
      # EXACT COLUMN MATCH: momentum, max_erasure_radius, erasure_distance
      dt <- fread(f, select = c("momentum", "max_erasure_radius", "erasure_distance"))
      if (nrow(dt) == 0) return(NULL)

      # Calculate Resonance Margin: delta_q - |epsilon_q|
      dt[, residual := max_erasure_radius - abs(erasure_distance)]

      data.table(
        normalized_momentum = dt$momentum[1],
        mean_residual   = mean(dt$residual, na.rm = TRUE),
        median_residual = median(dt$residual, na.rm = TRUE),
        sd_residual     = sd(dt$residual, na.rm = TRUE)
      )
    }, error = function(e) return(NULL))
  }, future.seed = TRUE))

  if (nrow(dt_summary_res) > 0) {
    setorder(dt_summary_res, normalized_momentum)

    # Calculate ribbon bounds
    dt_summary_res[, upper_residual := mean_residual + sd_residual]
    dt_summary_res[, lower_residual := mean_residual - sd_residual]

    fwrite(dt_summary_res, file_summary_out_res, compress = "gzip")
    message(sprintf("  -> Saved %d rows to %s", nrow(dt_summary_res), basename(file_summary_out_res)))
  }
}

plan(sequential)
