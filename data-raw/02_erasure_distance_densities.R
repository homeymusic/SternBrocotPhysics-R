library(future)
library(future.apply)
library(data.table)
library(progressr)

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "01_erasures")
agg_dir <- file.path(base_data_dir_4TB, "02_erasure_distance_densities")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

all_files <- list.files(raw_dir, pattern = "^erasures_P_.*\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "^erasure_distance_density_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)

files_to_process <- all_files[!(all_p_names %in% done_p_names)]

process_erasure_distance_density <- function(f, out_path) {
  tryCatch({
    library(data.table)
    setDTthreads(1)

    p_str <- gsub(".*erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)

    full_path <- file.path(out_path, sprintf("erasure_distance_density_P_%s.csv.gz", p_str))

    dt <- fread(f, select = c("found", "erasure_distance"))

    P_effective <- P_val * 2 * pi

    density_df <- compute_density(dt, P_effective, bin_width = 1.0)

    if (is.null(density_df)) return(NULL)

    density_df$normalized_momentum <- P_val

    fwrite(density_df, full_path, compress = "gzip")

    return(data.table(normalized_momentum = P_val, status = "success"))

  }, error = function(e) return(NULL))
}

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
