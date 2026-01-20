# 02_aggregate_erasure_metrics.R
here::i_am("data-raw/02_aggregate_erasure_metrics.R")

library(data.table)
library(future.apply)
library(Rcpp)

workers_to_use <- parallel::detectCores() / 2
future::plan(future::multisession, workers = workers_to_use)

# Updated to match External Volume from Script 01
raw_dir  <- "/Volumes/SternBrocot/01_micro_macro_erasures"
agg_dir  <- "/Volumes/SternBrocot/02_aggregated_summary"

hist_dir <- file.path(agg_dir, "histograms")
if (!dir.exists(hist_dir)) dir.create(hist_dir, recursive = TRUE)

summary_file <- file.path(agg_dir, "02_aggregated_summary.csv.gz")
all_files    <- list.files(raw_dir, pattern = "\\.csv\\.gz$", full.names = TRUE)

# --- WORKER LOGIC ---
process_file_full <- function(f, out_path) {
  # Compile C++ helper inside worker if not present
  if (!exists("find_nodes_cpp")) {
    try(Rcpp::sourceCpp(code = '
      #include <Rcpp.h>
      using namespace Rcpp;
      // [[Rcpp::export]]
      DataFrame find_nodes_cpp(DataFrame sub_df, double thresh, double h_range) {
        NumericVector x = sub_df["x"]; NumericVector y = sub_df["y"];
        int n = x.size(); std::vector<double> res_x; std::vector<double> res_y;
        bool ready_to_fire = true; double accumulator = 0;
        for(int i = 0; i < (n - 1); ++i) {
          double local_change = (y[i+1] - y[i]) / h_range;
          accumulator += local_change;
          if (ready_to_fire) {
            if (accumulator >= thresh) {
              res_x.push_back(x[i+1]); res_y.push_back(y[i+1]);
              ready_to_fire = false; accumulator -= thresh;
            }
            if (accumulator < 0) accumulator = 0;
          } else {
            if (accumulator <= -thresh) {
              ready_to_fire = true; accumulator += thresh;
            }
            if (accumulator > 0) accumulator = 0;
          }
        }
        return DataFrame::create(_["x"] = res_x, _["y"] = res_y);
      }
    '))
  }

  tryCatch({
    m_val <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", f))
    hist_name <- sprintf("histogram_P_%013.6f.csv.gz", round(m_val, 6))
    full_hist_path <- file.path(out_path, hist_name)

    dt <- data.table::fread(f, select = c("found", "macrostate", "fluctuation", "kolmogorov_complexity",
                                          "shannon_entropy", "zurek_entropy", "numerator", "denominator"))
    dt <- dt[found == TRUE]
    if (nrow(dt) == 0) return(NULL)

    action <- m_val * m_val
    raw_fluc <- dt$fluctuation * action
    f_rng <- range(raw_fluc, na.rm = TRUE)
    h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)
    plot_df <- data.table(x = h$mids, y = h$counts)

    run_detection <- function(sub_df, scan_dir) {
      if (is.null(sub_df) || nrow(sub_df) < 2) return(NULL)
      sub_df <- if(scan_dir == "right") sub_df[order(x), ] else sub_df[order(-x), ]
      h_range <- max(sub_df$y, na.rm = TRUE) - min(sub_df$y, na.rm = TRUE)
      x_sd <- sqrt(sum(sub_df$y * (sub_df$x - (sum(sub_df$x * sub_df$y)/sum(sub_df$y)))^2) / sum(sub_df$y))
      thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
      if (h_range < (thresh * mean(sub_df$y, na.rm = TRUE))) return(NULL)
      return(as.data.table(find_nodes_cpp(sub_df, thresh, h_range)))
    }

    res_r <- run_detection(plot_df[x >= 0], "right")
    res_l <- run_detection(plot_df[x < 0], "left")

    y_center <- plot_df$y[which.min(abs(plot_df$x))]
    dot_df <- data.table(x = numeric(0), y = numeric(0))

    if (!is.null(res_r) && !is.null(res_l)) {
      # MODIFIED LOGIC START: Unconditionally include the center point
      dot_df <- rbind(
        data.table(x = 0, y = y_center),
        res_l,
        res_r,
        fill = TRUE
      )
      # MODIFIED LOGIC END
    } else {
      dot_df <- rbind(res_l, res_r, fill=TRUE)
    }

    final_node_count <- nrow(unique(dot_df[complete.cases(dot_df)]))

    output_dt <- rbind(
      data.table(type = "hist", node_count = final_node_count, x = plot_df$x, y = plot_df$y),
      data.table(type = "node", node_count = final_node_count, x = dot_df$x,  y = dot_df$y),
      fill = TRUE
    )
    data.table::fwrite(output_dt, full_hist_path, compress = "gzip")

    summary_cols <- c("fluctuation", "kolmogorov_complexity", "shannon_entropy",
                      "zurek_entropy", "numerator", "denominator")

    res_summary <- dt[, {
      means <- lapply(.SD, mean); sds   <- lapply(.SD, sd)
      mins  <- lapply(.SD, min);  maxs  <- lapply(.SD, max)
      meds  <- lapply(.SD, median)

      names(means) <- paste0(names(means), "_mean")
      names(sds)   <- paste0(names(sds), "_sd")
      names(mins)  <- paste0(names(mins), "_min")
      names(maxs)  <- paste0(names(maxs), "_max")
      names(meds)  <- paste0(names(meds), "_median")

      c(list(momentum = m_val, node_count = final_node_count, macro_diversity = uniqueN(macrostate)),
        means, sds, mins, maxs, meds)
    }, .SDcols = summary_cols]

    return(res_summary)

  }, error = function(e) {
    message(paste("Failed on:", f, conditionMessage(e)))
    return(NULL)
  })
}

# --- INCREMENTAL EXECUTION LOGIC ---
# Check existing results to avoid re-processing
if (file.exists(summary_file)) {
  # Only read the momentum column to check progress efficiently
  existing_done <- data.table::fread(summary_file, select = "momentum")$momentum
  message(paste("Found existing summary with", length(existing_done), "records."))
} else {
  existing_done <- numeric(0)
}

# Extract momentum from filenames to compare against existing_done
all_momenta <- as.numeric(gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", all_files))
files_to_process <- all_files[!(all_momenta %in% existing_done)]

if (length(files_to_process) > 0) {
  message(paste("Processing", length(files_to_process), "new files..."))

  results <- future.apply::future_lapply(
    files_to_process,
    process_file_full,
    out_path = hist_dir,
    future.seed = TRUE,
    future.scheduling = 1,
    future.packages = c("data.table", "Rcpp")
  )

  new_summary <- data.table::rbindlist(results, fill = TRUE)

  if (nrow(new_summary) > 0) {
    # If file exists, append without column names. If not, write new with names.
    is_append <- file.exists(summary_file)
    data.table::fwrite(new_summary, summary_file,
                       append = is_append,
                       col.names = !is_append,
                       compress = "gzip")
    message("New data appended successfully.")
  }
} else {
  message("All files are already up to date in the summary.")
}

message("Done.")
