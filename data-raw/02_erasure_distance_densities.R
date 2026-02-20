library(future)
library(future.apply)
library(data.table)
library(progressr)

# --- 1. Configuration ---
plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "01_erasures")
# Directory specifically for the erasure_distance measure
agg_dir <- file.path(base_data_dir_4TB, "02_erasure_distance_densities")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

# --- 2. File Matching & Skip Logic ---
# Input: erasures_P_... (Source of Truth)
all_files <- list.files(raw_dir, pattern = "^erasures_P_.*\\.csv\\.gz$", full.names = TRUE)
# Output: erasure_distance_density_P_...
existing_densities <- list.files(agg_dir, pattern = "^erasure_distance_density_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)

files_to_process <- all_files[!(all_p_names %in% done_p_names)]

# --- 3. Processing Function ---
process_erasure_distance_density <- function(f, out_path) {
  tryCatch({
    library(data.table)
    # Use 1 thread per worker to avoid conflict with future_apply
    setDTthreads(1)

    # --- 1. Extract Momentum (P) ---
    p_str <- gsub(".*erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)

    # Define output path
    full_path <- file.path(out_path, sprintf("erasure_distance_density_P_%s.csv.gz", p_str))

    # --- 2. Load Raw Data ---
    dt <- fread(f, select = c("found", "erasure_distance"))

    # --- 3. THE PRO MOVE: Shared Logic ---
    # We call the package function. This handles:
    #   - Filtering found==1
    #   - The P^2 Action scaling
    #   - The 0.1 bin width
    #   - The Odd-Bin Symmetry
    #   - The floating point cleanup

    # --- 3. THE PRO MOVE: Shared Logic ---
    # We call the package function.

    # CRITICAL FIX: Scale P by 2*PI to match the Coordinate Q invariant.
    # The Physics (uncertainty) is based on 1/(2*pi*P).
    # To see the nodes, the Action canvas must scale by the same factor.
    P_effective <- P_val * 2 * pi

    density_df <- compute_density(dt, P_effective, bin_width = 1.0)

    if (is.null(density_df)) return(NULL)

    # RESTORE METADATA:
    # The function will label the rows with P_effective (approx 19.8).
    # We must set it back to P_val (3.16) so the final plot X-axis is correct.
    density_df$normalized_momentum <- P_val

    # --- 4. Write Result ---
    fwrite(density_df, full_path, compress = "gzip")

    return(data.table(normalized_momentum = P_val, status = "success"))

  }, error = function(e) return(NULL))
}
# --- 4. Execution ---
if (length(files_to_process) > 0) {
  message(sprintf("Processing %d new erasure_distance density files...", length(files_to_process)))
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      res <- process_erasure_distance_density(f, out_path = agg_dir)
      p()
      res
    }, future.seed = TRUE)
  })
} else {
  message("All erasure_distance density files are up to date.")
}

plan(sequential)
