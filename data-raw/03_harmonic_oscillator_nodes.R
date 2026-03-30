library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

# --- 1. Configuration ---
target_cols <- c("erasure_distance", "minimal_action_state")

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir   <- file.path(base_data_dir_4TB, "02_harmonic_oscillator_densities")
nodes_out_dir <- file.path(base_data_dir_4TB, "03_harmonic_oscillator_nodes")

if (!dir.exists(nodes_out_dir)) dir.create(nodes_out_dir, recursive = TRUE)

# --- 2. Execution Loop ---
for (col in target_cols) {
  message(sprintf("\n--- Extracting Nodes & Topology for: %s ---", col))

  # FIX: Allow the algorithm string in the pattern
  pattern_str <- sprintf("^harmonic_oscillator_%s_density_.*_P_.*\\.csv\\.gz$", col)
  col_density_files <- list.files(density_dir, pattern = pattern_str, full.names = TRUE)

  # --- 3. Skip Logic ---
  files_to_process <- Filter(function(f) {
    base_f <- basename(f)
    # FIX: Extract both algorithm and momentum safely
    regex_pattern <- sprintf("harmonic_oscillator_%s_density_(.*)_P_([0-9.]+)\\.csv\\.gz", col)
    matches <- regmatches(base_f, regexec(regex_pattern, base_f))

    if (length(matches[[1]]) == 3) {
      algo_str <- matches[[1]][2]
      p_str    <- matches[[1]][3]
      out_file <- file.path(nodes_out_dir, sprintf("harmonic_oscillator_%s_nodes_%s_P_%s.csv.gz", col, algo_str, p_str))
      return(!file.exists(out_file))
    }
    return(FALSE)
  }, col_density_files)

  # --- 4. Parallel Worker ---
  if (length(files_to_process) > 0) {
    message(sprintf("Processing %d density files...", length(files_to_process)))

    with_progress({
      p <- progressor(steps = length(files_to_process))

      future_lapply(files_to_process, function(f) {
        library(data.table)
        library(SternBrocotPhysics)
        setDTthreads(1)

        base_f <- basename(f)
        regex_pattern <- sprintf("harmonic_oscillator_%s_density_(.*)_P_([0-9.]+)\\.csv\\.gz", col)
        matches <- regmatches(base_f, regexec(regex_pattern, base_f))

        algo_str <- matches[[1]][2]
        p_str    <- matches[[1]][3]
        P_val    <- as.numeric(p_str)

        # FIX: Propagate the algorithm string into the output file
        out_file <- file.path(nodes_out_dir, sprintf("harmonic_oscillator_%s_nodes_%s_P_%s.csv.gz", col, algo_str, p_str))

        density_data <- fread(f)
        if (nrow(density_data) == 0) { p(); return(NULL) }

        input_dt <- density_data[, .(x = coordinate_q, y = density_count)]
        analysis <- count_nodes(input_dt)

        if (!is.null(analysis$nodes) && nrow(analysis$nodes) > 0) {
          nodes_df <- as.data.table(analysis$nodes)
          setnames(nodes_df, c("x", "y"), c("coordinate_q", "density_count"))
        } else {
          nodes_df <- data.table(coordinate_q = NA_real_, density_count = NA_real_, snr = NA_real_)
        }

        # Append Metadata (Now tracking algorithm)
        nodes_df[, algorithm := algo_str]
        nodes_df[, normalized_momentum := P_val]
        nodes_df[, node_count := as.integer(analysis$node_count)]
        nodes_df[, snr_metric := as.numeric(analysis$snr_metric)]

        fwrite(nodes_df, out_file, compress = "gzip")

        p()
        return(TRUE)
      }, future.seed = TRUE, future.scheduling = 1000)
    })
  } else {
    message(sprintf("\n⏭️  SKIPPING: Node files for '%s' already exist.", col))
  }
}

plan(sequential)
