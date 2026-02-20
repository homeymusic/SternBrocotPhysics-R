#' Count Nodes and Calculate Topological Complexity
#'
#' Uses outward-scanning adaptive hysteresis to detect nodes and calculates the
#' Normalized Total Variation (NTV) to rank states by their physical intricacy.
#'
#' @param density A data.table containing 'x' (coordinate) and 'y' (density) columns.
#' @param debug Logical. If TRUE, prints decision logic to the console.
#' @return A list containing:
#'   \item{node_count}{Integer count of detected nodes.}
#'   \item{nodes}{A data.table of the detected node coordinates.}
#'   \item{complexity_ntv}{Dimensionless metric of skyline intricacy.}
#' @import data.table
#' @export
count_nodes <- function(density, debug = FALSE) {
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  # Ensure strict coordinate ordering
  density <- density[order(density[["x"]]), ]

  # --- 1. Physics-Based Adaptive Thresholding ---
  active_idx <- which(density[["y"]] > 1e-9)

  if (length(active_idx) < 3) {
    return(list(
      node_count = as.integer(NA),
      nodes = data.table::data.table(x=numeric(0), y=numeric(0)),
      complexity_ntv = 0
    ))
  }

  active_data <- density[active_idx, ]

  # Use LOWESS to estimate the baseline (envelope)
  trend_fit <- stats::lowess(active_data[["x"]], active_data[["y"]], f = 0.2)
  local_baseline <- trend_fit$y

  # Threshold logic: 0.2 coefficient catches deep features; floor 5.0 suppresses noise.
  # thresh_vec <- pmax(0.2 * sqrt(local_baseline), 5.0)
  # Slightly more sensitive to shallow dips
  # thresh_vec <- pmax(0.12 * sqrt(local_baseline), 3.0)
  thresh_vec <- 0.05 * sqrt(local_baseline)
  data.table::set(active_data, j = "threshold", value = thresh_vec)

  if (debug) {
    message(sprintf("DEBUG: P ~ %0.2f. Baseline ~ %0.0f. Threshold ~ %0.2f.",
                    active_data$x[which.max(active_data$y)],
                    median(local_baseline),
                    median(thresh_vec)))
  }

  # --- 2. OUTWARD SCANNING (Center-Out) ---

  # Right Scan (Positive Q)
  right_data <- active_data[active_data[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    res_r <- count_nodes_cpp(right_data, right_data[["threshold"]])
    if (debug && nrow(res_r) > 0) message(sprintf("DEBUG: Right Scan found nodes at: %s", paste(res_r$x, collapse=", ")))
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0))
  }

  # Left Scan (Negative Q)
  left_data <- active_data[active_data[["x"]] <= 0, ]
  if (nrow(left_data) > 0) {
    left_data <- left_data[order(-left_data[["x"]]), ] # Sort 0 -> -Inf
    res_l <- count_nodes_cpp(left_data, left_data[["threshold"]])
    if (debug && nrow(res_l) > 0) message(sprintf("DEBUG: Left Scan found nodes at: %s", paste(res_l$x, collapse=", ")))
  } else {
    res_l <- data.frame(x=numeric(0), y=numeric(0))
  }

  # --- 3. Combine & Topology Check ---
  dt_l <- data.table::as.data.table(res_l)
  dt_r <- data.table::as.data.table(res_r)
  dot_df <- rbind(dt_l, dt_r)
  dot_df <- unique(dot_df, by = "x")

  if (nrow(dot_df) > 0) {
    dot_df <- dot_df[order(dot_df[["x"]]), ]

    # --- CENTRAL PEAK VALIDATION ---
    neg_nodes <- dot_df[dot_df[["x"]] < 0, ]
    pos_nodes <- dot_df[dot_df[["x"]] > 0, ]

    if (nrow(neg_nodes) > 0 && nrow(pos_nodes) > 0) {
      closest_neg <- neg_nodes[which.max(neg_nodes[["x"]]), ]
      closest_pos <- pos_nodes[which.min(pos_nodes[["x"]]), ]

      gap_data <- density[density[["x"]] > closest_neg[["x"]] & density[["x"]] < closest_pos[["x"]], ]

      should_merge <- FALSE

      center_idx <- which.min(abs(active_data[["x"]]))
      center_thresh <- active_data[["threshold"]][center_idx]
      if (length(center_thresh) == 0) center_thresh <- 10.0

      if (nrow(gap_data) == 0) {
        should_merge <- TRUE
      } else {
        gap_peak <- max(gap_data[["y"]], na.rm = TRUE)
        valley_floor <- max(closest_neg[["y"]], closest_pos[["y"]])
        prominence <- gap_peak - valley_floor

        if (debug) {
          message(sprintf("DEBUG: Checking Center Merge. Neg: %s, Pos: %s. Prominence: %s vs Thresh: %s",
                          closest_neg$x, closest_pos$x, prominence, center_thresh))
        }

        if (prominence < center_thresh) {
          should_merge <- TRUE
        }
      }

      if (should_merge) {
        if(debug) message("DEBUG: Merging central nodes.")
        dot_df <- dot_df[!(dot_df[["x"]] == closest_neg[["x"]] | dot_df[["x"]] == closest_pos[["x"]]), ]
        min_val <- if(nrow(gap_data)>0) min(gap_data[["y"]], na.rm=TRUE) else (closest_neg[["y"]]+closest_pos[["y"]])/2
        dot_df <- rbind(dot_df, data.table::data.table(x=0, y=min_val))
      }
    }
  }

  # --- 4. STRUCTURE VALIDATION ---
  final_count <- nrow(dot_df)
  if (final_count == 0) {
    global_thresh_check <- median(active_data[["threshold"]], na.rm=TRUE)
    active_range <- max(active_data[["y"]]) - min(active_data[["y"]])
    if (active_range < global_thresh_check) {
      return(list(
        node_count = as.integer(NA),
        nodes = data.table::data.table(x=numeric(0), y=numeric(0)),
        complexity_ntv = 0
      ))
    }
  }

  # --- 5. TOPOLOGICAL COMPLEXITY (Weighted & Powered NTV) ---
  y_vals  <- active_data[["y"]]
  y_max   <- max(y_vals, na.rm = TRUE)
  y_min   <- min(y_vals, na.rm = TRUE)
  y_range <- y_max - y_min

  # --- 5. TOPOLOGICAL COMPLEXITY (Feature-Based NTV) ---
  y_vals  <- active_data[["y"]]
  x_vals  <- active_data[["x"]]
  y_max   <- max(y_vals, na.rm = TRUE)
  y_min   <- min(y_vals, na.rm = TRUE)
  y_range <- y_max - y_min

  if (y_range > 1e-9 && nrow(dot_df) > 0) {
    # 1. Identify critical x-points: start, detected nodes, and end
    # This creates the 'segments' of the signal
    critical_x <- sort(unique(c(min(x_vals), dot_df$x, max(x_vals))))

    # 2. Build the Topological Skeleton
    # We find the highest peak in every segment between nodes
    skeleton_y <- c()
    for (i in 1:(length(critical_x) - 1)) {
      # Data within this segment
      seg_idx <- which(x_vals >= critical_x[i] & x_vals <= critical_x[i+1])

      if (length(seg_idx) > 0) {
        # Add the segment's starting y (usually a node or boundary)
        if (i == 1) skeleton_y <- c(skeleton_y, y_vals[seg_idx[1]])

        # Add the maximum value in this segment (the Peak)
        skeleton_y <- c(skeleton_y, max(y_vals[seg_idx]))

        # Add the segment's ending y (the next node or boundary)
        skeleton_y <- c(skeleton_y, y_vals[seg_idx[length(seg_idx)]])
      }
    }

    # 3. Calculate Normalized Total Variation of the Skeleton
    # We can also add your 'Magnitude Weighting' here to favor larger peaks
    dy      <- abs(diff(skeleton_y))
    weights <- ((skeleton_y[-1] + skeleton_y[-length(skeleton_y)]) / 2) / y_max

    # p=1.5 or 2.0 makes balanced 'high' peaks win over one 'big' + many 'tiny'
    p <- 1.5
    final_complexity <- sum(dy * (weights^p)) / y_range

  } else if (y_range > 1e-9) {
    # If no nodes detected, it's a single hump: variation is just Up + Down
    # We calculate the variation from start -> max -> end
    final_complexity <- ((y_max - y_vals[1]) + (y_max - y_vals[length(y_vals)])) / y_range
  } else {
    final_complexity <- 0
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]

  return(list(
    node_count = final_count,
    nodes = dot_df,
    complexity_ntv = final_complexity
  ))
}
