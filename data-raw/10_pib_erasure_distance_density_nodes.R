library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir <- file.path(base_data_dir_4TB, "09_pib_erasure_distance_densities")
nodes_out_dir <- file.path(base_data_dir_4TB, "10_pib_erasure_distance_density_nodes")

if (!dir.exists(nodes_out_dir)) dir.create(nodes_out_dir, recursive = TRUE)

density_files <- list.files(density_dir, pattern = "^pib_erasure_distance_density_P_.*\\.csv\\.gz$", full.names = TRUE)
existing_nodes <- list.files(nodes_out_dir, pattern = "^pib_erasure_distance_nodes_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("pib_erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(density_files))
done_p_names <- gsub("pib_erasure_distance_nodes_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_nodes)

files_to_process <- density_files[!(all_p_names %in% done_p_names)]

process_pib_nodes <- function(f, out_path) {
  tryCatch({
    library(data.table)
    library(SternBrocotPhysics)
    setDTthreads(1)

    p_str <- gsub(".*pib_erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)
    out_file <- file.path(out_path, sprintf("pib_erasure_distance_nodes_P_%s.csv.gz", p_str))

    density_data <- fread(f)

    # IDENTITY MAPPING: Use restored column names
    input_dt <- density_data[, .(x = coordinate_q, y = pmax(0, density_count))]

    analysis <- count_nodes(input_dt)

    if (!is.null(analysis$nodes) && nrow(analysis$nodes) > 0) {
      nodes_df <- as.data.table(analysis$nodes)
      setnames(nodes_df, c("x", "y"), c("coordinate_q", "density_count"))
    } else {
      nodes_df <- data.table(coordinate_q = NA_real_, density_count = NA_real_)
    }

    # API PARITY: Ensure metadata keys match the QHO Readme exactly
    nodes_df[, normalized_momentum := P_val]
    nodes_df[, node_count := as.integer(analysis$node_count)]
    nodes_df[, complexity_ntv := as.numeric(analysis$complexity_ntv)]

    fwrite(nodes_df, out_file, compress = "gzip")
    return(data.table(normalized_momentum = P_val, status = "success"))
  }, error = function(e) return(NULL))
}

if (length(files_to_process) > 0) {
  message(sprintf("🔍 Extracting PIB nodes from %d density files...", length(files_to_process)))
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      res <- process_pib_nodes(f, out_path = nodes_out_dir)
      p()
      res
    }, future.seed = TRUE)
  })
}
plan(sequential)
