#' Count Nodes using Outward-Scanning Hysteresis
#'
#' @param density A data.table containing 'x' and 'y' columns.
#' @export
count_nodes <- function(density) {
  # 1. Validation
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  # --- 2. Physics-Based Thresholding ---
  # Tuned to 2-sigma Poisson noise.
  # 3-sigma (48 units) was too high for side-lobes (depth ~40 units).
  # 2-sigma (32 units) catches side-lobes while blocking vacuum noise (~15 units).
  mean_density <- mean(density[["y"]], na.rm = TRUE)
  if (is.na(mean_density) || mean_density <= 0) {
    return(list(node_count = 0, nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  hysteresis_thresh <- 2.0 * sqrt(mean_density)

  # --- 3. OUTWARD SCANNING ---

  # RIGHT SIDE: 0 -> +Infinity
  right_data <- density[density[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    right_data <- right_data[order(right_data[["x"]]), ]
    res_r <- SternBrocotPhysics::count_nodes_cpp(right_data, hysteresis_thresh)
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0))
  }

  # LEFT SIDE: 0 -> -Infinity
  left_data <- density[density[["x"]] < 0, ]
  if (nrow(left_data) > 0) {
    # Scan outwards from center (descending x) to match hysteresis direction
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

    # Filter edge artifacts
    max_x <- max(abs(density[["x"]]), na.rm = TRUE)
    dot_df <- dot_df[abs(dot_df[["x"]]) < max_x * 0.90, ]

    # --- 5. Singularity Patch ---
    # Merge central straddlers if they are physically the same valley
    neg_nodes <- dot_df[dot_df[["x"]] < 0, ]
    pos_nodes <- dot_df[dot_df[["x"]] > 0, ]

    if (nrow(neg_nodes) > 0 && nrow(pos_nodes) > 0) {
      closest_neg <- neg_nodes[which.max(neg_nodes[["x"]]), ]
      closest_pos <- pos_nodes[which.min(pos_nodes[["x"]]), ]

      # Only merge if they are reasonably close (avoid merging distinct side lobes across a wide center)
      # Heuristic: Gap must be smaller than 20% of total domain, or purely based on peak height.
      # We stick to the Peak Height Physics check:

      gap_data <- density[density[["x"]] > closest_neg[["x"]] & density[["x"]] < closest_pos[["x"]], ]

      if (nrow(gap_data) > 0) {
        local_peak <- max(gap_data[["y"]], na.rm = TRUE)
        avg_depth  <- (closest_neg[["y"]] + closest_pos[["y"]]) / 2

        # If the "mountain" between them is insignificant...
        if ((local_peak - avg_depth) < hysteresis_thresh) {
          # ...merge them.
          dot_df <- dot_df[!(dot_df[["x"]] == closest_neg[["x"]] | dot_df[["x"]] == closest_pos[["x"]]), ]
          min_val <- min(gap_data[["y"]], na.rm = TRUE)
          dot_df <- rbind(dot_df, data.table::data.table(x=0, y=min_val))
        }
      }
    }
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]
  return(list(node_count = nrow(dot_df), nodes = dot_df))
}
