#' Count Nodes using Outward-Scanning Adaptive Hysteresis
#'
#' @param density A data.table containing 'x' and 'y' columns.
#' @import data.table
#' @export
count_nodes <- function(density) {
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  # Ensure sorted by X for the trend calculation and scanning
  density <- density[order(density[["x"]]), ]

  # --- 1. Physics-Based Adaptive Thresholding ---
  # Filter to active region to exclude vacuum zeros for the trend calculation
  # We use a tiny epsilon to grab valid physics data
  active_idx <- which(density[["y"]] > 1e-9)

  if (length(active_idx) < 5) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  # Work with the active subset to calculate trends
  active_data <- density[active_idx, ]

  # DISCERNING THE DC COMPONENT:
  # Use LOWESS to estimate the "U-Shaped" density contour.
  # f=0.2 provides a window of ~20% of the data.
  # This smoothes out the nodes (micro-structure) while preserving the saddle (macro-structure).
  trend_fit <- stats::lowess(active_data[["x"]], active_data[["y"]], f = 0.2)

  # The lowess output $y corresponds to the sorted input x.
  local_baseline <- trend_fit$y

  # DEFINE ADAPTIVE THRESHOLD:
  # 1. Scaling: 0.8 * sqrt(baseline) is more sensitive than the old 2.0 * sqrt(median).
  #    It allows detection of shallow wells at high-density edges.
  # 2. Floor: pmax(..., 5.0) ensures we never trigger on shot noise < 5 counts
  #    (prevents regressions at Low P).
  thresh_vec <- pmax(0.8 * sqrt(local_baseline), 5.0)

  # Assign thresholds back to the data.table so we can split them
  active_data[, threshold := thresh_vec]

  # --- 2. OUTWARD SCANNING (Center-Out) ---
  # We split the data AND the pre-calculated thresholds

  right_data <- active_data[active_data[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    # Scan Right (already sorted ascending)
    res_r <- SternBrocotPhysics::count_nodes_cpp(right_data, right_data[["threshold"]])
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0))
  }

  left_data <- active_data[active_data[["x"]] < 0, ]
  if (nrow(left_data) > 0) {
    # Scan Left (Reverse to sort descending: Center -> Out)
    left_data <- left_data[order(-left_data[["x"]]), ]
    # Note: threshold vector travels with the rows, so it stays aligned
    res_l <- SternBrocotPhysics::count_nodes_cpp(left_data, left_data[["threshold"]])
  } else {
    res_l <- data.frame(x=numeric(0), y=numeric(0))
  }

  # --- 3. Combine & Topology Check ---
  dt_l <- data.table::as.data.table(res_l)
  dt_r <- data.table::as.data.table(res_r)
  dot_df <- rbind(dt_l, dt_r)

  if (nrow(dot_df) > 0) {
    dot_df <- dot_df[order(dot_df[["x"]]), ]

    # --- CENTRAL PEAK VALIDATION (The Stitch) ---
    neg_nodes <- dot_df[dot_df[["x"]] < 0, ]
    pos_nodes <- dot_df[dot_df[["x"]] > 0, ]

    if (nrow(neg_nodes) > 0 && nrow(pos_nodes) > 0) {
      closest_neg <- neg_nodes[which.max(neg_nodes[["x"]]), ]
      closest_pos <- pos_nodes[which.min(pos_nodes[["x"]]), ]

      # Look at the gap between the two closest nodes
      gap_data <- density[density[["x"]] > closest_neg[["x"]] & density[["x"]] < closest_pos[["x"]], ]

      should_merge <- FALSE

      # Determine the threshold *specifically* at the center for the merge logic
      center_idx <- which.min(abs(active_data[["x"]]))
      center_thresh <- active_data[["threshold"]][center_idx]
      if (length(center_thresh) == 0) center_thresh <- 10.0 # Fallback safety

      if (nrow(gap_data) == 0) {
        should_merge <- TRUE
      } else {
        gap_peak <- max(gap_data[["y"]], na.rm = TRUE)
        valley_floor <- max(closest_neg[["y"]], closest_pos[["y"]])
        prominence <- gap_peak - valley_floor

        # Merge if the peak between them is insignificant relative to LOCAL noise
        if (prominence < center_thresh) {
          should_merge <- TRUE
        }
      }

      if (should_merge) {
        # Remove the two separate nodes
        dot_df <- dot_df[!(dot_df[["x"]] == closest_neg[["x"]] | dot_df[["x"]] == closest_pos[["x"]]), ]
        # Add a single central node
        min_val <- if(nrow(gap_data)>0) min(gap_data[["y"]], na.rm=TRUE) else (closest_neg[["y"]]+closest_pos[["y"]])/2
        dot_df <- rbind(dot_df, data.table::data.table(x=0, y=min_val))
      }
    }
  }

  final_count <- nrow(dot_df)

  # --- 4. STRUCTURE VALIDATION ---
  # If 0 nodes found, double check we didn't miss a massive single flat feature.
  # We use the median of our adaptive thresholds for a global sanity check.
  if (final_count == 0) {
    global_thresh_check <- median(active_data[["threshold"]], na.rm=TRUE)
    active_range <- max(active_data[["y"]]) - min(active_data[["y"]])

    if (active_range < global_thresh_check) {
      # Truly empty/noise (The variance is less than the expected noise floor)
      return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
    }
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]
  return(list(node_count = final_count, nodes = dot_df))
}
