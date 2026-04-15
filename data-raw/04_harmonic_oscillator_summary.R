library(data.table)
library(future.apply)

# --- 1. Configuration ---
plan(multisession, workers = parallel::detectCores() - 2)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw        <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_03_nodes      <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")

dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")
if (!dir.exists(dir_04_summary)) dir.create(dir_04_summary, recursive = TRUE)

# ==============================================================================
# PART A: TOPOLOGICAL METRICS (Nodes)
# ==============================================================================
message("\n=== Aggregating Topological Summaries ===")
cols_topological <- c("erasure_displacement", "selected_microstate")

for (col in cols_topological) {
  message(sprintf("Processing node summary for: %s", col))
  file_summary_out <- file.path(dir_04_summary, sprintf("harmonic_oscillator_%s_summary.csv.gz", col))
  pattern_str <- sprintf("^harmonic_oscillator_%s_nodes_.*_P_.*\\.csv\\.gz$", col)
  files_nodes <- list.files(dir_03_nodes, pattern = pattern_str, full.names = TRUE)

  if (length(files_nodes) == 0) {
    warning(sprintf("  -> No node files found for %s. Skipping.", col))
    next
  }

  dt_summary <- rbindlist(lapply(files_nodes, function(f) {
    tryCatch({
      fread(f, select = c("normalized_momentum", "node_count", "snr_metric"), nrows = 1)
    }, error = function(e) return(NULL))
  }), fill = TRUE)

  if (nrow(dt_summary) > 0) {
    dt_summary <- dt_summary[!is.na(snr_metric)]
    setorder(dt_summary, normalized_momentum)
    fwrite(dt_summary, file_summary_out, compress = "gzip")
    message(sprintf("  -> Saved %d rows to %s", nrow(dt_summary), basename(file_summary_out)))
  }
}

# ==============================================================================
# PART B: GROUND TRUTH RAW METRICS (Algorithmic)
# ==============================================================================
message("\n=== Aggregating Ground Truth Raw Summaries ===")

pattern_str_raw <- "^harmonic_oscillator_erasures_.*_P_.*\\.csv\\.gz$"
files_raw <- list.files(dir_01_raw, pattern = pattern_str_raw, full.names = TRUE)

if (length(files_raw) == 0) {
  stop("\n❌ CRITICAL ERROR: No raw erasure files found. Halting pipeline.")
}

message(sprintf("Processing %d RAW files in a single pass...", length(files_raw)))

dt_raw_combined <- rbindlist(future_lapply(files_raw, function(f) {
  tryCatch({
    # Only load what we need
    dt <- fread(f, select = c("momentum", "sequence_length", "erasure_displacement", "found"))

    dt <- dt[found == 1]
    if (nrow(dt) == 0) return(NULL)

    P_val <- dt$momentum[1]
    A_val <- P_val^2
    n_states <- nrow(dt)

    # Exact Ground Truth Math
    data.table(
      normalized_momentum = P_val,
      action_A = A_val,
      n_states = n_states,

      # Sequence Length Stats
      mean_len   = mean(dt$sequence_length, na.rm = TRUE),
      median_len = as.numeric(median(dt$sequence_length, na.rm = TRUE)),
      sd_len     = sd(dt$sequence_length, na.rm = TRUE),
      min_len    = min(dt$sequence_length, na.rm = TRUE),
      max_len    = max(dt$sequence_length, na.rm = TRUE),

      # Displacement Stats
      mean_disp   = mean(dt$erasure_displacement, na.rm = TRUE),
      median_disp = median(dt$erasure_displacement, na.rm = TRUE),
      sd_disp     = sd(dt$erasure_displacement, na.rm = TRUE),
      min_disp    = min(dt$erasure_displacement, na.rm = TRUE),
      max_disp    = max(dt$erasure_displacement, na.rm = TRUE)
    )
  }, error = function(e) return(NULL))
}, future.seed = TRUE))

if (nrow(dt_raw_combined) > 0) {
  setorder(dt_raw_combined, normalized_momentum)

  # ---------------------------------------------------------
  # 1. Export Sequence Length Summary
  # ---------------------------------------------------------
  cols_len <- c("normalized_momentum", "action_A", "n_states", "mean_len", "median_len", "sd_len", "min_len", "max_len")
  dt_len <- dt_raw_combined[, ..cols_len]
  dt_len[, upper := mean_len + sd_len]
  dt_len[, lower := pmax(min_len, mean_len - sd_len)]

  file_out_len <- file.path(dir_04_summary, "harmonic_oscillator_sequence_length_summary.csv.gz")
  fwrite(dt_len, file_out_len, compress = "gzip")
  message(sprintf("  -> Saved Sequence Length to %s", basename(file_out_len)))

  # ---------------------------------------------------------
  # 2. Export Erasure Displacement Summary
  # ---------------------------------------------------------
  cols_disp <- c("normalized_momentum", "action_A", "n_states", "mean_disp", "median_disp", "sd_disp", "min_disp", "max_disp")
  dt_disp <- dt_raw_combined[, ..cols_disp]
  dt_disp[, upper := mean_disp + sd_disp]
  dt_disp[, lower := mean_disp - sd_disp]

  file_out_disp <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_distribution_summary.csv.gz")
  fwrite(dt_disp, file_out_disp, compress = "gzip")
  message(sprintf("  -> Saved Erasure Displacement to %s", basename(file_out_disp)))

} else {
  stop("\n❌ CRITICAL ERROR: Raw data processing yielded 0 rows. Halting pipeline.")
}

plan(sequential)
message("\n✅ Pure RAW summaries generated successfully.")
