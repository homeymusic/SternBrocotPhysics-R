library(data.table)

# --- 1. Configuration ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
nodes_dir    <- file.path(base_data_dir_4TB, "03_erasure_distance_density_nodes")
summary_file <- file.path(base_data_dir_4TB, "04_erasure_distance_summary.csv.gz")

# --- 2. Collection ---
message("Aggregating node counts and complexity metrics from 1:1 feature files...")

all_node_files <- list.files(nodes_dir, pattern = "^erasure_distance_nodes_P_.*\\.csv\\.gz$", full.names = TRUE)

if (length(all_node_files) == 0) {
  stop("No node files found in 03_erasure_distance_density_nodes. Run Script 03 first.")
}

# --- 3. High-Speed Aggregation ---
# We now select 'complexity_ntv' as well.
summary_dt <- rbindlist(lapply(all_node_files, function(f) {
  tryCatch({
    # We read ONLY the first row and ONLY the specific columns needed for the summary
    # This keeps the aggregation extremely fast even with thousands of files.
    fread(f, select = c("normalized_momentum", "node_count", "complexity_ntv"), nrows = 1)
  }, error = function(e) return(NULL))
}), fill = TRUE)

# --- 4. Finalize & Save ---
if (nrow(summary_dt) > 0) {

  # Ensure we only keep rows where complexity was actually calculated
  # This prevents the README from crashing if a few files are still the old version
  summary_dt <- summary_dt[!is.na(complexity_ntv)]

  # Sort by momentum for consistent sequence mapping
  setorder(summary_dt, normalized_momentum)

  # Save to the root project directory on the SanDisk
  fwrite(summary_dt, summary_file, compress = "gzip")

  message(sprintf("Success. Summary for %d momentum steps (with Complexity metrics) saved to: %s",
                  nrow(summary_dt), summary_file))
} else {
  warning("Aggregation failed. No valid data (or missing 'complexity_ntv' column) found in node files.")
}
