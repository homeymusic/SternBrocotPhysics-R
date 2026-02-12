#' Count Nodes using Outward-Scanning Hysteresis
#'
#' @param density A data.table containing 'x' and 'y' columns.
#' @export
count_nodes <- function(density) {
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  # --- 1. Physics-Based Thresholding ---
  mean_density <- mean(density[["y"]], na.rm = TRUE)
  if (is.na(mean_density) || mean_density <= 0) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  hysteresis_thresh <- 2.0 * sqrt(mean_density)

  # --- 2. PEAK VALIDATION (Global Amplitude) ---
  min_y <- min(density[["y"]], na.rm = TRUE)
  max_y <- max(density[["y"]], na.rm = TRUE)

  # Reject pure noise / DC offset
  if ((max_y - min_y) < hysteresis_thresh) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  # --- 3. OUTWARD SCANNING ---

  # RIGHT SIDE
  right_data <- density[density[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    right_data <- right_data[order(right_data[["x"]]), ]
    res_r <- SternBrocotPhysics::count_nodes_cpp(right_data, hysteresis_thresh)
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0))
  }

  # LEFT SIDE
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

    max_x <- max(abs(density[["x"]]), na.rm = TRUE)
    dot_df <- dot_df[abs(dot_df[["x"]]) < max_x * 0.90, ]

    # Singularity Patch
    neg_nodes <- dot_df[dot_df[["x"]] < 0, ]
    pos_nodes <- dot_df[dot_df[["x"]] > 0, ]

    if (nrow(neg_nodes) > 0 && nrow(pos_nodes) > 0) {
      closest_neg <- neg_nodes[which.max(neg_nodes[["x"]]), ]
      closest_pos <- pos_nodes[which.min(pos_nodes[["x"]]), ]

      gap_data <- density[density[["x"]] > closest_neg[["x"]] & density[["x"]] < closest_pos[["x"]], ]

      if (nrow(gap_data) > 0) {
        local_peak <- max(gap_data[["y"]], na.rm = TRUE)
        avg_depth  <- (closest_neg[["y"]] + closest_pos[["y"]]) / 2

        if ((local_peak - avg_depth) < hysteresis_thresh) {
          dot_df <- dot_df[!(dot_df[["x"]] == closest_neg[["x"]] | dot_df[["x"]] == closest_pos[["x"]]), ]
          min_val <- min(gap_data[["y"]], na.rm = TRUE)
          dot_df <- rbind(dot_df, data.table::data.table(x=0, y=min_val))
        }
      }
    }
  }

  final_count <- nrow(dot_df)

  # --- 5. STRUCTURE VALIDATION (Distinguish n=0 from Flat Box) ---
  if (final_count == 0) {
    # Extract only the "Active Signal" (the part standing above the noise floor)
    # FIX: Use standard evaluation for column extraction
    active_subset <- density[density[["y"]] > hysteresis_thresh, ]

    if (nrow(active_subset) > 5) {
      active_signal <- active_subset[["y"]]

      active_max <- max(active_signal)
      active_min <- min(active_signal)
      active_range <- active_max - active_min

      # Logic:
      # P=1 (Box): The active signal is just the flat top. Range ~ 0.
      # P=3 (Steps): The active signal has tiers. Range >> 0.

      if (active_range < hysteresis_thresh) {
        # The "mountain" is perfectly flat on top -> Artificial Box / Vacuum
        return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
      }
    }
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]
  return(list(node_count = final_count, nodes = dot_df))
}
