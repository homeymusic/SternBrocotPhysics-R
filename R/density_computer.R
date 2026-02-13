#' Compute Action Density from Raw Erasures
#'
#' Converts raw erasure distances into a normalized Action density histogram.
#' Handles the P^2 scaling and ensures odd-bin symmetry centered at zero.
#'
#' @param dt A data.table containing a 'found' and 'erasure_distance' column.
#' @param p The momentum value (numeric).
#' @param bin_width The resolution of the histogram (default 0.1).
#' @return A data.table with columns: normalized_momentum, coordinate_q, density_count.
#' @export
compute_density <- function(dt, p, bin_width = 0.1) {
  # Filter for found states if not already done
  if ("found" %in% names(dt)) {
    dt <- dt[dt$found == 1, ]
  }

  if (nrow(dt) == 0) return(NULL)

  # --- 1. THE PHYSICS ---
  # Action q = erasure * P^2
  raw_fluc <- dt[["erasure_distance"]] * (p^2)
  f_rng <- range(raw_fluc, na.rm = TRUE)

  # --- 2. THE BINNING (Odd-Bin Symmetry) ---
  max_extent <- max(abs(f_rng))

  # Round up to next whole number + buffer
  limit <- ceiling(max_extent) + 1.0

  # Offset by half-bin to capture 0.0 in the center
  half_bin <- bin_width / 2
  breaks_seq <- seq(-limit - half_bin, limit + half_bin, by = bin_width)

  h <- graphics::hist(raw_fluc, breaks = breaks_seq, plot = FALSE)

  # --- 3. FORMAT OUTPUT ---
  density_df <- data.table::data.table(
    normalized_momentum = p,
    coordinate_q        = h$mids,
    density_count       = h$counts
  )

  # Clean floating point noise at origin
  density_df$coordinate_q[abs(density_df$coordinate_q) < 1e-10] <- 0

  return(density_df)
}
