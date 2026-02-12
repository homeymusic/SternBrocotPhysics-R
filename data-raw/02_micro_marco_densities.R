library(future)
library(future.apply)
library(data.table)
library(progressr)

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_dir <- file.path(base_data_dir_4TB, "01_micro_macro_erasures")
agg_dir <- file.path(base_data_dir_4TB, "02_micro_marco_densities") # New Dir
if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "density_P_.*\\.csv\\.gz$")

all_p_names <- gsub("micro_macro_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)
files_to_process <- all_files[!(all_p_names %in% done_p_names)]

process_density_only <- function(f, out_path) {
  tryCatch({
    library(data.table)
    setDTthreads(1)

    p_str <- gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)
    full_path <- file.path(out_path, sprintf("density_P_%s.csv.gz", p_str))

    dt <- fread(f, select = c("found", "erasure_distance"))
    dt <- dt[found == 1]
    if (nrow(dt) == 0) return(NULL)

    # Physics calc: Fluctuation = d * P^2
    raw_fluc <- dt$erasure_distance * (P_val^2)
    f_rng <- range(raw_fluc, na.rm = TRUE)

    # Generate Histogram
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)

    density_df <- data.table(x = h$mids, y = h$counts)
    density_df[abs(x) < 1e-10, x := 0]

    # Save ONLY density
    fwrite(density_df, full_path, compress = "gzip")
    return(data.table(normalized_momentum = P_val, status = "success"))
  }, error = function(e) return(NULL))
}

if (length(files_to_process) > 0) {
  with_progress({
    p <- progressor(steps = length(files_to_process))
    future_lapply(files_to_process, function(f) {
      res <- process_density_only(f, out_path = agg_dir)
      p()
      res
    }, future.seed = TRUE)
  })
}
plan(sequential)
