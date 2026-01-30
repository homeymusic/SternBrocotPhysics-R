library(future)
library(future.apply)
library(data.table)

# Use all available cores minus 2
plan(multisession, workers = parallel::detectCores() - 2)

# --- CONFIGURATION ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_dir  <- file.path(base_data_dir_4TB, "01_micro_macro_erasures")
agg_dir  <- file.path(base_data_dir_4TB, "04_fine_structure")

if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "04_fine_structure.csv.gz")

# --- FILE SELECTION ---
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# Idempotency: Check what P values already exist in the summary file
processed_p <- if(file.exists(summary_file)) {
  data.table::fread(summary_file, select = "normalized_momentum")[[1]]
} else numeric(0)

all_p <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
files_to_process <- all_files[!sapply(all_p, function(x) any(abs(x - processed_p) < 1e-7))]

cat("Audit: Found", length(all_files), "total raw files.\n")
cat("Audit: Skipping", length(all_files) - length(files_to_process), "already processed.\n")
cat("Audit: Processing", length(files_to_process), "remaining files.\n\n")

# --- WORKER LOGIC ---
process_fine_structure <- function(f) {
  tryCatch({
    library(data.table)

    P_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))

    # Only select necessary columns to save memory/time
    dt <- data.table::fread(f,
                            select = c("found", "erasure_distance", "program_length", "shannon_entropy"),
                            colClasses = c(found="integer", erasure_distance="numeric",
                                           program_length="integer", shannon_entropy="numeric"))

    dt[, found := as.logical(found)]
    dt <- dt[found == TRUE]

    if (nrow(dt) == 0) return(NULL)

    # CREATE NEW METRIC: absolute value of erasure_distance
    dt[, fine_structure := abs(erasure_distance)]

    # Identify numeric columns for stats (including the new one)
    num_cols <- names(dt)[sapply(dt, is.numeric)]

    stats_list <- list(normalized_momentum = P_val, n_found = nrow(dt))

    # Calculate Mean, Median, and SD for all numeric columns
    stats_list <- c(stats_list,
                    setNames(lapply(dt[, ..num_cols], mean, na.rm=TRUE), paste0(num_cols, "_mean")),
                    setNames(lapply(dt[, ..num_cols], median, na.rm=TRUE), paste0(num_cols, "_median")),
                    setNames(lapply(dt[, ..num_cols], sd, na.rm=TRUE), paste0(num_cols, "_sd")))

    return(as.data.table(stats_list))
  }, error = function(e) {
    message("Worker Error on file ", f, ": ", e$message)
    return(NULL)
  })
}

# --- EXECUTION ---
if (length(files_to_process) > 0) {
  new_results <- future.apply::future_lapply(files_to_process,
                                             process_fine_structure,
                                             future.seed = TRUE,
                                             future.packages = c("data.table"),
                                             future.scheduling = 100)

  new_dt <- data.table::rbindlist(new_results, fill = TRUE)

  if (nrow(new_dt) > 0) {
    if (file.exists(summary_file)) {
      existing_dt <- data.table::fread(summary_file)
      final_dt <- unique(rbind(existing_dt, new_dt, fill = TRUE), by = "normalized_momentum")
    } else {
      final_dt <- new_dt
    }

    # Save the updated summary
    data.table::fwrite(final_dt[order(normalized_momentum)], summary_file, compress="gzip")
    cat("Successfully updated", summary_file, "\n")
  }
} else {
  cat("No new files to process.\n")
}
