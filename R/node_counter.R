#' Count Nodes in Coordinate Density
#'
#' @param density A data.table containing 'x' and 'y' columns.
#' @export
count_nodes <- function(density) {
  if (!data.table::is.data.table(density)) {
    density <- data.table::as.data.table(density)
  }

  # 1. Moments & Gabor Grounding
  total_y <- sum(density[["y"]])
  mean_x  <- sum(density[["x"]] * density[["y"]]) / total_y
  x_sd    <- sqrt(sum(density[["y"]] * (density[["x"]] - mean_x)^2) / total_y)

  gabor_thresh <- (1 / (4 * pi)) / (1 + sqrt(x_sd))
  fluctuation_power <- mean(density[["y"]])

  if (all(abs(density[["y"]] - mean(density[["y"]])) < gabor_thresh * mean(density[["y"]]))) {
    return(list(node_count = as.numeric(NA), nodes = data.table::data.table(x = numeric(0), y = numeric(0))))
  }

  # 2. Sectional Detection (Using explicit indexing for order to avoid 'object not found')
  res_r <- data.table::as.data.table(
    SternBrocotPhysics::count_nodes_cpp(density[density[["x"]] > 0, ], gabor_thresh, fluctuation_power)
  )

  # Subset first, then order using the explicit column vector
  left_side <- density[density[["x"]] < 0, ]
  res_l <- data.table::as.data.table(
    SternBrocotPhysics::count_nodes_cpp(left_side[order(-left_side[["x"]]), ], gabor_thresh, fluctuation_power)
  )

  # 3. Combine
  dot_df <- rbind(res_l, res_r)
  if (nrow(dot_df) > 0) {
    dot_df <- dot_df[!is.na(dot_df[["x"]]) & !is.na(dot_df[["y"]]), ]
    dot_df <- unique(dot_df)
  }

  # 4. Parity/Symmetry Consolidation
  if (nrow(res_l) > 0 && nrow(res_r) > 0) {
    l_max <- max(res_l[["x"]])
    r_min <- min(res_r[["x"]])
    mid_zone <- density[density[["x"]] > l_max & density[["x"]] < r_min, ]

    if (!SternBrocotPhysics::contains_peak_cpp(mid_zone, gabor_thresh, fluctuation_power)) {
      # Collapse "straddlers" into a single central node
      dot_df <- rbind(
        dot_df[dot_df[["x"]] < l_max | dot_df[["x"]] > r_min, ],
        data.table::data.table(
          x = 0,
          y = density[["y"]][which.min(abs(density[["x"]]))]
        )
      )
      dot_df <- unique(dot_df)
    }
  }

  return(list(node_count = nrow(dot_df), nodes = dot_df))
}
