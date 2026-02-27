library(data.table)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
nodes_dir    <- file.path(base_data_dir_4TB, "10_pib_erasure_distance_density_nodes")
summary_file <- file.path(base_data_dir_4TB, "11_pib_erasure_distance_summary.csv.gz")

message("📊 Aggregating PIB node counts and complexity metrics...")

all_node_files <- list.files(nodes_dir, pattern = "^pib_erasure_distance_nodes_P_.*\\.csv\\.gz$", full.names = TRUE)

if (length(all_node_files) == 0) {
  stop("No node files found in 10_pib_erasure_distance_density_nodes.")
}

summary_dt <- rbindlist(lapply(all_node_files, function(f) {
  tryCatch({
    # IDENTITY MAPPING: Harvesting restored key
    fread(f, select = c("normalized_momentum", "node_count", "complexity_ntv"), nrows = 1)
  }, error = function(e) return(NULL))
}), fill = TRUE)

if (nrow(summary_dt) > 0) {
  summary_dt <- summary_dt[!is.na(complexity_ntv)]
  setorder(summary_dt, normalized_momentum)
  fwrite(summary_dt, summary_file, compress = "gzip")
  message(sprintf("✅ Success. PIB Summary for %d momentum steps saved.", nrow(summary_dt)))
}
