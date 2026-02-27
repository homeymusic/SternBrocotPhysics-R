library(future)
library(future.apply)
library(data.table)
library(progressr)
library(SternBrocotPhysics)

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_dir <- file.path(base_data_dir_4TB, "08_pib_erasures")
agg_dir <- file.path(base_data_dir_4TB, "09_pib_erasure_distance_densities")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

all_files <- list.files(raw_dir, pattern = "^pib_erasures_P_.*\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "^pib_erasure_distance_density_P_.*\\.csv\\.gz$")

all_p_names  <- gsub("pib_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("pib_erasure_distance_density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)

files_to_process <- all_files[!(all_p_names %in% done_p_names)]

process_pib_erasure_density <- function(f, out_path) {
  tryCatch({
    library(data.table)
    library(SternBrocotPhysics)
    setDTthreads(1)

    p_str <- gsub(".*pib_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)
    full_path <- file.path(out_path, sprintf("pib_erasure_distance_density_P_%s.csv.gz", p_str))

    dt <- fread(f, select = c("found", "erasure_distance"), na.strings = "NA")
    dt_valid <- dt[found == 1 & !is.na(erasure_distance)]

    P_effective <- P_val * 2 * pi

    # Use the original instrument to produce 'coordinate_q' and 'density_count'
    density_df <- compute_density(dt_valid, P_effective, bin_width = 1.0)

    if (is.null(density_df)) return(NULL)

    # API PARITY: Use 'normalized_momentum'
    density_df$normalized_momentum <- P_val

    fwrite(density_df, full_path, compress = "gzip")
    return(data.table(normalized_momentum = P_val, status = "success"))
  }, error = function(e) return(NULL))
}

if (length(files_to_process) > 0) {
  message(sprintf("🚀 Processing %d new PIB erasure_distance density files...", length(files_to_process)))
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      res <- process_pib_erasure_density(f, out_path = agg_dir)
      p()
      res
    }, future.seed = TRUE)
  })
}
plan(sequential)
