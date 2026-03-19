library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

# --- 1. Configuration ---
# Only include the continuous physical phase-space metrics here.
# (minimal_program_length skips this step and goes straight to Step 04)
target_cols <- c("erasure_distance", "minimal_action_state")

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir   <- file.path(base_data_dir_4TB, "02_harmonic_oscillator_densities")
nodes_out_dir <- file.path(base_data_dir_4TB, "03_harmonic_oscillator_nodes")

if (!dir.exists(nodes_out_dir)) dir.create(nodes_out_dir, recursive = TRUE)

# --- 2. Execution Loop ---
# We loop through each physical metric one at a time to keep the parallel workers focused
for (col in target_cols) {
  message(sprintf("\n--- Extracting Nodes & Topology for: %s ---", col))

  # Find all density files specifically for this column
  pattern_str <- sprintf("^harmonic_oscillator_%s_density_P_.*\\.csv\\.gz$", col)
  col_density_files <- list.files(density_dir, pattern = pattern_str, full.names = TRUE)

  # --- 3. Skip Logic ---
  files_to_process <- Filter(function(f) {
    p_str <- gsub(sprintf(".*harmonic_oscillator_%s_density_P_([0-9.]+)\\.csv\\.gz", col), "\\1", basename(f))
    out_file <- file.path(nodes_out_dir, sprintf("harmonic_oscillator_%s_nodes_P_%s.csv.gz", col, p_str))
    return(!file.exists(out_file))
  }, col_density_files)

  # --- 4. Parallel Worker ---
  if (length(files_to_process) > 0) {
    message(sprintf("Processing %d density files...", length(files_to_process)))

    with_progress({
      p <- progressor(steps = length(files_to_process))

      future_lapply(files_to_process, function(f) {
        library(data.table)
        library(SternBrocotPhysics)

        # 1 thread per worker to avoid conflict with future_apply
        setDTthreads(1)

        # Extract momentum string and value
        p_str <- gsub(sprintf(".*harmonic_oscillator_%s_density_P_([0-9.]+)\\.csv\\.gz", col), "\\1", basename(f))
        P_val <- as.numeric(p_str)
        out_file <- file.path(nodes_out_dir, sprintf("harmonic_oscillator_%s_nodes_P_%s.csv.gz", col, p_str))

        # Load density data
        density_data <- fread(f)
        if (nrow(density_data) == 0) { p(); return(NULL) }

        # Format for the node counter
        input_dt <- density_data[, .(x = coordinate_q, y = density_count)]

        # Call the physics C++ node counter (returns node_count, nodes, and complexity_ntv)
        analysis <- count_nodes(input_dt)

        # Prepare node coordinate table
        if (!is.null(analysis$nodes) && nrow(analysis$nodes) > 0) {
          nodes_df <- as.data.table(analysis$nodes)
          setnames(nodes_df, c("x", "y"), c("coordinate_q", "density_count"))
        } else {
          # Placeholder for P where no nodes are detected (e.g., Ground State)
          nodes_df <- data.table(coordinate_q = NA_real_, density_count = NA_real_)
        }

        # Append Metadata & Topological Complexity Metrics
        nodes_df[, normalized_momentum := P_val]
        nodes_df[, node_count := as.integer(analysis$node_count)]
        nodes_df[, complexity_ntv := as.numeric(analysis$complexity_ntv)]

        # Save output
        fwrite(nodes_df, out_file, compress = "gzip")

        p()
        return(TRUE)
      }, future.seed = TRUE, future.scheduling = 1000)
    })
  } else {
    message("All node files for this column are up to date.")
  }
}

plan(sequential)
