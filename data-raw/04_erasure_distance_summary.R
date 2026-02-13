library(data.table)

# --- 1. Configuration ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
nodes_dir    <- file.path(base_data_dir_4TB, "03_erasure_distance_density_nodes")
summary_file <- file.path(base_data_dir_4TB, "04_erasure_distance_summary.csv.gz")

# --- 2. Collection ---
message("Aggregating node counts from 1:1 feature files...")

all_node_files <- list.files(nodes_dir, pattern = "^erasure_distance_nodes_P_.*\\.csv\\.gz$", full.names = TRUE)

if (length(all_node_files) == 0) {
  stop("No node files found in 03_erasure_distance_density_nodes. Run Script 03 first.")
}

# --- 3. High-Speed Aggregation ---
# We use nrows = 1 because the momentum and node_count are constants in each 1:1 file
summary_dt <- rbindlist(lapply(all_node_files, function(f) {
  tryCatch({
    # Only read the metadata row to save massive IO time
    fread(f, select = c("normalized_momentum", "node_count"), nrows = 1)
  }, error = function(e) return(NULL))
}), fill = TRUE)

# --- 4. Finalize & Save to Root ---
if (nrow(summary_dt) > 0) {
  # Sort by momentum to ensure the README plots have continuous lines
  setorder(summary_dt, normalized_momentum)

  # Save to the root project directory on the SanDisk
  fwrite(summary_dt, summary_file, compress = "gzip")

  message(sprintf("Success. Summary for %d momentum steps saved to: %s",
                  nrow(summary_dt), summary_file))
} else {
  warning("Aggregation failed. No valid data found in node files.")
}
