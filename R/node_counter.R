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
  active_idx <- which(density[["y"]] > 1e-9)

  if (length(active_idx) < 5) {
    return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
  }

  # Work with the active subset to calculate trends
  active_data <- density[active_idx, ]

  # DISCERNING THE DC COMPONENT:
  # Use LOWESS to estimate the "U-Shaped" density contour.
  trend_fit <- stats::lowess(active_data[["x"]], active_data[["y"]], f = 0.2)
  local_baseline <- trend_fit$y

  # DEFINE ADAPTIVE THRESHOLD:
  thresh_vec <- pmax(0.8 * sqrt(local_baseline), 5.0)
  data.table::set(active_data, j = "threshold", value = thresh_vec)

  # --- 2. OUTWARD SCANNING (Center-Out) ---

  # Right Scan: Starts at 0 (Inclusive)
  right_data <- active_data[active_data[["x"]] >= 0, ]
  if (nrow(right_data) > 0) {
    res_r <- SternBrocotPhysics::count_nodes_cpp(right_data, right_data[["threshold"]])
  } else {
    res_r <- data.frame(x=numeric(0), y=numeric(0))
  }

  # Left Scan: Starts at 0 (Inclusive) - Essential for Symmetry
  left_data <- active_data[active_data[["x"]] <= 0, ]
  if (nrow(left_data) > 0) {
    left_data <- left_data[order(-left_data[["x"]]), ]
    res_l <- SternBrocotPhysics::count_nodes_cpp(left_data, left_data[["threshold"]])
  } else {
    res_l <- data.frame(x=numeric(0), y=numeric(0))
  }

  # --- 3. Combine & Topology Check ---
  dt_l <- data.table::as.data.table(res_l)
  dt_r <- data.table::as.data.table(res_r)

  dot_df <- rbind(dt_l, dt_r)

  # CRITICAL FIX: Remove duplicates at x=0 caused by inclusive overlapping scans
  dot_df <- unique(dot_df, by = "x")

  if (nrow(dot_df) > 0) {
    dot_df <- dot_df[order(dot_df[["x"]]), ]

    # --- CENTRAL PEAK VALIDATION (The Stitch) ---
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

        if (prominence < center_thresh) {
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

  # --- 4. STRUCTURE VALIDATION ---
  if (final_count == 0) {
    global_thresh_check <- median(active_data[["threshold"]], na.rm=TRUE)
    active_range <- max(active_data[["y"]]) - min(active_data[["y"]])

    if (active_range < global_thresh_check) {
      return(list(node_count = as.integer(NA), nodes = data.table::data.table(x=numeric(0), y=numeric(0))))
    }
  }

  if (nrow(dot_df) > 0) dot_df <- dot_df[order(dot_df[["x"]]), ]
  return(list(node_count = final_count, nodes = dot_df))
}
