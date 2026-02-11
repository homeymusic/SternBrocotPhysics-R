library(future)
library(future.apply)
library(data.table)
library(progressr) # Highly recommended for 300k files

plan(multisession, workers = parallel::detectCores() - 2)

base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot"
raw_dir  <- file.path(base_data_dir_4TB, "01_micro_macro_erasures")
agg_dir  <- file.path(base_data_dir_4TB, "02_micro_marco_densities")
if (!dir.exists(agg_dir)) dir.create(agg_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_micro_marco_densities.csv.gz")

# FAST FILE AUDIT
cat("Auditing files (this may take a minute with 300k entries)...\n")
all_files <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)
existing_densities <- list.files(agg_dir, pattern = "density_P_.*\\.csv\\.gz$")

# String-based matching is 100x faster than numeric tolerance for large sets
all_p_names <- gsub("micro_macro_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(all_files))
done_p_names <- gsub("density_P_([0-9.]+)\\.csv\\.gz", "\\1", existing_densities)

files_to_process <- all_files[!(all_p_names %in% done_p_names)]

cat(sprintf("Audit: %d total, %d already done, %d to process.\n",
            length(all_files), length(done_p_names), length(files_to_process)))

# --- UPDATED WORKER LOGIC ---
process_file_full <- function(f, out_path) {
  is_near <- function(a, b) abs(a - b) < 1e-10

  tryCatch({
    library(data.table)
    setDTthreads(1)
    library(SternBrocotPhysics)

    # Use the filename string directly to maintain 0.001 precision
    p_str <- gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)

    full_path <- file.path(out_path, sprintf("density_P_%s.csv.gz", p_str))

    # Fast skip if exists
    if (file.exists(full_path)) return(NULL)

    dt <- data.table::fread(f,
                            select = c("found", "erasure_distance", "program_length",
                                       "shannon_entropy", "numerator", "denominator"),
                            colClasses = c(found="integer", erasure_distance="numeric",
                                           program_length="integer", shannon_entropy="numeric",
                                           numerator="numeric", denominator="numeric"))

    dt <- dt[as.logical(found) == TRUE]
    if (nrow(dt) == 0) return(NULL)

    action <- P_val * P_val
    raw_fluc <- dt$erasure_distance * action
    f_rng <- range(raw_fluc, na.rm = TRUE)

    # Use 402 breaks for consistent wavefunction resolution
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)
    plot_df[is_near(x, 0), x := 0]

    # Gabor/DC Case Check
    total_y <- sum(plot_df$y)
    mean_x <- sum(plot_df$x * plot_df$y) / total_y
    x_sd <- sqrt(sum(plot_df$y * (plot_df$x - mean_x)^2) / total_y)
    gabor_thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))

    if (all(abs(plot_df$y - mean(plot_df$y)) < gabor_thresh * mean(plot_df$y))) {
      node_count_final <- NA_real_
      dot_df <- data.table(x = numeric(0), y = numeric(0))
    } else {
      global_h_range <- max(plot_df$y) - min(plot_df$y)

      # Node detection
      res_r <- as.data.table(SternBrocotPhysics::find_nodes_cpp(plot_df[x > 0], gabor_thresh, global_h_range))
      res_l <- as.data.table(SternBrocotPhysics::find_nodes_cpp(plot_df[x < 0][order(-x)], gabor_thresh, global_h_range))

      dot_df <- unique(rbind(res_l, res_r, fill = TRUE)[complete.cases(x, y)])

      # Gap Logic for Zero-Node
      if (nrow(res_l) > 0 && nrow(res_r) > 0) {
        if (!SternBrocotPhysics::contains_peak_cpp(plot_df[x > res_l[which.max(x)]$x & x < res_r[which.min(x)]$x],
                                                   gabor_thresh, global_h_range)) {
          dot_df <- rbind(dot_df[!(abs(x) < 1e-5)], data.table(x = 0, y = plot_df$y[which.min(abs(plot_df$x))]))
        }
      }
      node_count_final <- nrow(dot_df)
    }

    # Write per-momentum density
    data.table::fwrite(rbind(
      data.table(type="density", x=plot_df$x, y=plot_df$y, node_count=node_count_final),
      data.table(type="node",    x=dot_df$x,  y=dot_df$y,  node_count=node_count_final),
      fill=TRUE), full_path, compress="gzip")

    # Aggregate stats for summary
    num_cols <- names(dt)[sapply(dt, is.numeric)]
    stats <- list(normalized_momentum = P_val, node_count = node_count_final, n_found = nrow(dt))
    stats <- c(stats, setNames(lapply(dt[, ..num_cols], mean, na.rm=TRUE), paste0(num_cols, "_mean")),
               setNames(lapply(dt[, ..num_cols], median, na.rm=TRUE), paste0(num_cols, "_median")),
               setNames(lapply(dt[, ..num_cols], sd, na.rm=TRUE), paste0(num_cols, "_sd")))

    return(as.data.table(stats))
  }, error = function(e) return(NULL))
}

# EXECUTION
if (length(files_to_process) > 0) {
  with_progress({
    p <- progressor(steps = length(files_to_process))
    new_results <- future_lapply(files_to_process, function(f) {
      res <- process_file_full(f, out_path = agg_dir)
      p()
      res
    }, future.seed = TRUE, future.scheduling = 1000)
  })

  new_dt <- rbindlist(new_results, fill = TRUE)

  if (nrow(new_dt) > 0) {
    if (file.exists(summary_file)) {
      final_dt <- unique(rbind(fread(summary_file), new_dt, fill = TRUE), by = "normalized_momentum")
    } else {
      final_dt <- new_dt
    }
    fwrite(final_dt[order(normalized_momentum)], summary_file, compress = "gzip")
    message("Success. Summary saved.")
  }
}
plan(sequential)
