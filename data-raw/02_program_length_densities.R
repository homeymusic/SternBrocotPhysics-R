library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

# --- 1. Configuration ---
plan(multisession, workers = parallel::detectCores() - 2)
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "01_erasures")
agg_dir <- file.path(base_data_dir_4TB, "02_program_length_densities")
if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

# --- 2. File Matching ---
all_files <- list.files(raw_dir, pattern = "^erasures_P_.*\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "^program_length_density_P_.*\\.csv\\.gz$")
all_p_names  <- gsub("erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("program_length_density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)
files_to_process <- all_files[!(all_p_names %in% done_p_names)]

# --- 3. Processing Function ---
process_program_length_density <- function(f, out_path) {
  tryCatch({
    library(data.table)
    setDTthreads(1)

    p_str <- gsub(".*erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)
    full_path <- file.path(out_path, sprintf("program_length_density_P_%s.csv.gz", p_str))

    # 1. Load data
    dt <- fread(f, select = c("found", "program_length"))
    dt <- dt[found == 1]
    if(nrow(dt) == 0) return(NULL)

    # 2. MANUAL AGGREGATION (Bypassing compute_density)
    # This creates a "skyline" by counting how many states fall into each integer bit-length.
    density_df <- dt[, .(density_count = .N), by = .(coordinate_q = program_length)]

    # Sort by coordinate so the plot flows correctly
    setorder(density_df, coordinate_q)

    # 3. Add metadata for the Rmd
    density_df$normalized_momentum <- P_val

    # 4. Write Result
    fwrite(density_df, full_path, compress = "gzip")

    return(data.table(normalized_momentum = P_val, status = "success"))

  }, error = function(e) return(NULL))
}
# --- 4. Execution ---
if (length(files_to_process) > 0) {
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      res <- process_program_length_density(f, agg_dir)
      p()
      res
    }, future.seed = TRUE, future.globals = TRUE)
  })
}
plan(sequential)
