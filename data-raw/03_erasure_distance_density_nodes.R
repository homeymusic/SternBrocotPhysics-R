library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

# --- 1. Configuration ---
plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
# Input directory from Script 02
density_dir <- file.path(base_data_dir_4TB, "02_erasure_distance_densities")
# Output directory for 1:1 node files
nodes_out_dir <- file.path(base_data_dir_4TB, "03_erasure_distance_density_nodes")

if (!dir.exists(nodes_out_dir)) dir.create(nodes_out_dir, recursive = TRUE)

# --- 2. File Matching & Skip Logic ---
# Input: erasure_distance_density_P_...
density_files <- list.files(density_dir, pattern = "^erasure_distance_density_P_.*\\.csv\\.gz$", full.names = TRUE)
# Output: erasure_distance_nodes_P_...
existing_nodes <- list.files(nodes_out_dir, pattern = "^erasure_distance_nodes_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(density_files))
done_p_names <- gsub("erasure_distance_nodes_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_nodes)

files_to_process <- density_files[!(all_p_names %in% done_p_names)]

# --- 3. Parallel Worker ---
process_erasure_nodes <- function(f, out_path) {
  tryCatch({
    library(data.table)
    library(SternBrocotPhysics)

    # Extract momentum string for naming
    p_str <- gsub(".*erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)

    # 1. Load the intuitive density data
    density_data <- fread(f)

    # 2. Map intuitive names back to x/y for the hardened R/C++ wrapper
    # count_nodes expects a data.table with 'x' and 'y' columns
    input_dt <- density_data[, .(x = coordinate_q, y = density_count)]

    # 3. DOMAIN CALL: The hardened logic (Gabor-Mean scaling + Symmetry Consolidation)
    analysis <- SternBrocotPhysics::count_nodes(input_dt)

    # 4. Save 1:1 Node File if nodes exist
    if (!is.null(analysis$nodes) && nrow(analysis$nodes) > 0) {
      nodes_df <- as.data.table(analysis$nodes)

      # Restore intuitive names for the output file
      setnames(nodes_df, c("x", "y"), c("coordinate_q", "density_count"))
      nodes_df[, normalized_momentum := P_val]
      nodes_df[, node_count := analysis$node_count]

      out_file <- file.path(out_path, sprintf("erasure_distance_nodes_P_%s.csv.gz", p_str))
      fwrite(nodes_df, out_file, compress = "gzip")
    }

    return(data.table(normalized_momentum = P_val, status = "success"))
  }, error = function(e) return(NULL))
}

# --- 4. Execution ---
if (length(files_to_process) > 0) {
  message(sprintf("Extracting nodes from %d erasure_distance density files...", length(files_to_process)))

  with_progress({
    p <- progressor(steps = length(files_to_process))

    future_lapply(files_to_process, function(f) {
      res <- process_erasure_nodes(f, out_path = nodes_out_dir)
      p()
      res
    }, future.seed = TRUE, future.scheduling = 1000)
  })
} else {
  message("All node files are up to date.")
}

plan(sequential)
