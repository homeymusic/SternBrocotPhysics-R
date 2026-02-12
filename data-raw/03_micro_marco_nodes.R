library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

# --- Configuration ---
plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
density_dir       <- file.path(base_data_dir_4TB, "02_micro_marco_densities")
results_dir       <- file.path(base_data_dir_4TB, "03_micro_marco_nodes")

if (!dir.exists(results_dir)) dir.create(results_dir, recursive = TRUE)

summary_file  <- file.path(results_dir, "node_analysis_summary.csv.gz")
density_files <- list.files(density_dir, pattern = "density_P_.*\\.csv\\.gz$", full.names = TRUE)

# --- Parallel Worker ---
process_quantum_nodes <- function(f) {
  tryCatch({
    # We load the libraries inside the worker for multisession stability
    library(data.table)
    library(SternBrocotPhysics)

    # Extract momentum from filename
    p_str <- gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    density_data <- fread(f)

    # DOMAIN CALL: The logic now lives in R/node_counter.R
    analysis <- count_nodes(density_data)

    return(data.table(
      normalized_momentum = as.numeric(p_str),
      node_count          = analysis$node_count
    ))
  }, error = function(e) return(NULL))
}

# --- Execution ---
message(sprintf("Analyzing %d density files for node counts...", length(density_files)))

with_progress({
  p <- progressor(steps = length(density_files))

  node_results <- future_lapply(density_files, function(f) {
    res <- process_quantum_nodes(f)
    p()
    res
  }, future.seed = TRUE, future.scheduling = 1000) # scheduling keeps workers fed
})

# --- Finalize ---
final_summary <- rbindlist(node_results, fill = TRUE)

if (nrow(final_summary) > 0) {
  setorder(final_summary, normalized_momentum)
  fwrite(final_summary, summary_file, compress = "gzip")
  message(sprintf("Success. Summary saved to: %s", summary_file))
} else {
  warning("No results were generated. Check raw density data.")
}

plan(sequential)
