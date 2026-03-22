#' Count Nodes and Calculate Topological Complexity
#'
#' @param density A data.table containing 'x' (coordinate) and 'y' (density) columns.
#' @param debug Logical. If TRUE, prints decision logic to the console.
#' @return A list containing: node_count, nodes, snr_metric
#' @import data.table
#' @export
count_nodes <- function(density, debug = FALSE) {
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  density <- density[order(density[["x"]]), ]

  # PURE SYSTEM QUANTA
  n_active_microstates <- sum(density[["y"]], na.rm = TRUE)
  system_quanta <- 1.0 / n_active_microstates
  active_idx <- which(density[["y"]] >= system_quanta)

  if (length(active_idx) < 3) {
    return(list(
      node_count = as.integer(NA),
      nodes = data.table::data.table(x=numeric(0), y=numeric(0), snr=numeric(0)),
      snr_metric = 0
    ))
  }

  active_data <- density[active_idx, ]
  n_active <- nrow(active_data)

  # PURE GEOMETRIC SMOOTHING
  adaptive_f <- 3 / n_active
  trend_fit <- stats::lowess(active_data[["x"]], active_data[["y"]], f = adaptive_f)
  local_baseline <- trend_fit$y

  threshold_scale = 1 / (2 * pi)
  thresh_vec <- threshold_scale * sqrt(abs(local_baseline))
  data.table::set(active_data, j = "threshold", value = thresh_vec)

  if (debug) {
    message(sprintf("DEBUG: Peak ~ %0.0f. Baseline ~ %0.0f. Threshold ~ %0.2f. f-span ~ %0.5f",
                    max(active_data$y),
                    median(local_baseline),
                    median(thresh_vec),
                    adaptive_f))
  }

  # --- OUTWARD SCANNING (Center-Out) ---
  right_data <- active_data[active_data[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    res_r <- count_nodes_cpp(right_data, right_data[["threshold"]])
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0), snr=numeric(0))
  }

  left_data <- active_data[active_data[["x"]] <= 0, ]
  if (nrow(left_data) > 0) {
    left_data <- left_data[order(-left_data[["x"]]), ]
    res_l <- count_nodes_cpp(left_data, left_data[["threshold"]])
  } else {
    res_l <- data.frame(x=numeric(0), y=numeric(0), snr=numeric(0))
  }

  # --- Combine & Topology Check ---
  dt_l <- data.table::as.data.table(res_l)
  dt_r <- data.table::as.data.table(res_r)
  dot_df <- rbind(dt_l, dt_r, fill = TRUE)
  dot_df <- unique(dot_df, by = "x")

  if (nrow(dot_df) > 0) {
    dot_df <- dot_df[order(dot_df[["x"]]), ]

    # CENTRAL PEAK VALIDATION
    neg_nodes <- dot_df[dot_df[["x"]] < 0, ]
    pos_nodes <- dot_df[dot_df[["x"]] > 0, ]

    if (nrow(neg_nodes) > 0 && nrow(pos_nodes) > 0) {
      closest_neg <- neg_nodes[which.max(neg_nodes[["x"]]), ]
      closest_pos <- pos_nodes[which.min(pos_nodes[["x"]]), ]

      gap_data <- density[density[["x"]] > closest_neg[["x"]] & density[["x"]] < closest_pos[["x"]], ]

      should_merge <- FALSE
      center_idx <- which.min(abs(active_data[["x"]]))
      center_thresh <- active_data[["threshold"]][center_idx]

      if (length(center_thresh) == 0) {
        center_thresh <- (closest_neg[["threshold"]] + closest_pos[["threshold"]]) / 2
      }

      if (nrow(gap_data) == 0) {
        should_merge <- TRUE
      } else {
        gap_peak <- max(gap_data[["y"]], na.rm = TRUE)
        valley_floor <- max(closest_neg[["y"]], closest_pos[["y"]])
        prominence <- gap_peak - valley_floor

        if (prominence < center_thresh) {
          should_merge <- TRUE
        }
      }

      if (should_merge) {
        dot_df <- dot_df[!(dot_df[["x"]] == closest_neg[["x"]] | dot_df[["x"]] == closest_pos[["x"]]), ]
        min_val <- if(nrow(gap_data)>0) min(gap_data[["y"]], na.rm=TRUE) else (closest_neg[["y"]]+closest_pos[["y"]])/2
        merged_snr <- mean(c(closest_neg[["snr"]], closest_pos[["snr"]]), na.rm = TRUE)
        dot_df <- rbind(dot_df, data.table::data.table(x=0, y=min_val, snr=merged_snr), fill = TRUE)
      }
    }
  }

  # --- STRUCTURE VALIDATION ---
  final_count <- nrow(dot_df)
  if (final_count == 0) {
    global_thresh_check <- median(active_data[["threshold"]], na.rm=TRUE)
    active_range <- max(active_data[["y"]]) - min(active_data[["y"]])
    if (active_range < global_thresh_check) {
      return(list(
        node_count = as.integer(NA),
        nodes = data.table::data.table(x=numeric(0), y=numeric(0), snr=numeric(0)),
        snr_metric = 0
      ))
    }
  }

  # --- TOPOLOGICAL COMPLEXITY (Mean Local SNR) ---
  if (nrow(dot_df) > 0 && "snr" %in% names(dot_df)) {
    final_complexity <- mean(dot_df[["snr"]], na.rm = TRUE)
  } else {
    final_complexity <- 0
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]

  return(list(
    node_count = final_count,
    nodes = dot_df,
    snr_metric = final_complexity
  ))
}
