#' Count Nodes using Outward-Scanning Hysteresis
#'
#' @param density A data.table containing 'x' and 'y' columns.
#' @export
count_nodes <- function(density) {
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  # --- 1. Physics-Based Thresholding (ROBUST) ---
  # Filter to active region to exclude vacuum zeros
  active_y <- density[["y"]][density[["y"]] > 1e-9]

  if (length(active_y) < 5) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  # USE MEDIAN INSTEAD OF MEAN
  # High-P states are "U-Shaped" with massive peaks at the edges.
  # The 'median' stays anchored to the valley floor, preserving sensitivity.
  robust_baseline <- median(active_y, na.rm = TRUE)

  if (is.na(robust_baseline) || robust_baseline <= 0) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  hysteresis_thresh <- 2.0 * sqrt(robust_baseline)

  # --- 2. PEAK VALIDATION (Global Amplitude) ---
  min_y <- min(density[["y"]], na.rm = TRUE)
  max_y <- max(density[["y"]], na.rm = TRUE)

  if ((max_y - min_y) < hysteresis_thresh) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  # --- 3. OUTWARD SCANNING ---
  right_data <- density[density[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    right_data <- right_data[order(right_data[["x"]]), ]
    res_r <- SternBrocotPhysics::count_nodes_cpp(right_data, hysteresis_thresh)
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0))
  }

  left_data <- density[density[["x"]] < 0, ]
  if (nrow(left_data) > 0) {
    left_data <- left_data[order(-left_data[["x"]]), ]
    res_l <- SternBrocotPhysics::count_nodes_cpp(left_data, hysteresis_thresh)
  } else {
    res_l <- data.frame(x=numeric(0), y=numeric(0))
  }

  # --- 4. Combine & Topology Check ---
  dt_l <- data.table::as.data.table(res_l)
  dt_r <- data.table::as.data.table(res_r)
  dot_df <- rbind(dt_l, dt_r)

  if (nrow(dot_df) > 0) {
    dot_df <- dot_df[order(dot_df[["x"]]), ]

    # REMOVED DESTRUCTIVE SPATIAL FILTER (max_x * 0.90)
    # The nodes at high P are exactly at the edge. We must keep them.

    # --- CENTRAL PEAK VALIDATION (The Stitch) ---
    neg_nodes <- dot_df[dot_df[["x"]] < 0, ]
    pos_nodes <- dot_df[dot_df[["x"]] > 0, ]

    if (nrow(neg_nodes) > 0 && nrow(pos_nodes) > 0) {
      closest_neg <- neg_nodes[which.max(neg_nodes[["x"]]), ]
      closest_pos <- pos_nodes[which.min(pos_nodes[["x"]]), ]

      gap_data <- density[density[["x"]] > closest_neg[["x"]] & density[["x"]] < closest_pos[["x"]], ]

      should_merge <- FALSE

      if (nrow(gap_data) == 0) {
        should_merge <- TRUE
      } else {
        gap_peak <- max(gap_data[["y"]], na.rm = TRUE)
        valley_floor <- max(closest_neg[["y"]], closest_pos[["y"]])
        prominence <- gap_peak - valley_floor
        merge_thresh <- 0.75 * hysteresis_thresh

        if (prominence < merge_thresh) {
          should_merge <- TRUE
        }
      }

      if (should_merge) {
        dot_df <- dot_df[!(dot_df[["x"]] == closest_neg[["x"]] | dot_df[["x"]] == closest_pos[["x"]]), ]
        min_val <- if(nrow(gap_data)>0) min(gap_data[["y"]], na.rm=TRUE) else (closest_neg[["y"]]+closest_pos[["y"]])/2
        dot_df <- rbind(dot_df, data.table::data.table(x=0, y=min_val))
      }
    }
  }

  final_count <- nrow(dot_df)

  # --- 5. STRUCTURE VALIDATION ---
  if (final_count == 0) {
    active_subset <- density[density[["y"]] > hysteresis_thresh, ]
    if (nrow(active_subset) > 5) {
      active_range <- max(active_subset[["y"]]) - min(active_subset[["y"]])
      if (active_range < hysteresis_thresh) {
        return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
      }
    }
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]
  return(list(node_count = final_count, nodes = dot_df))
}
