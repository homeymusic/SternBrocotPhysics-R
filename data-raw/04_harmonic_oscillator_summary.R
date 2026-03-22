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

  pattern_str <- sprintf("^harmonic_oscillator_%s_nodes_P_.*\\.csv\\.gz$", col)
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

  pattern_str <- sprintf("^harmonic_oscillator_%s_density_P_.*\\.csv\\.gz$", col)
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

plan(sequential)
