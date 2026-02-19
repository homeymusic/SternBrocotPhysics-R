#' Compute Action Density from Raw Erasures
#'
#' Converts raw erasure distances into a normalized Action density histogram.
#' Handles the P^2 scaling and ensures odd-bin symmetry centered at zero.
#'
#' @param dt A data.table containing a 'found' and 'erasure_distance' column.
#' @param p The momentum value (numeric).
#' @param bin_width The resolution of the histogram.
#' @return A data.table with columns: normalized_momentum, coordinate_q, density_count.
#' @export
compute_density <- function(dt, p, bin_width = 1) {
  # --- 1. PRE-PROCESSING ---
  # Filter for found states if not already done
  if ("found" %in% names(dt)) {
    dt <- dt[dt$found == 1, ]
  }

  if (nrow(dt) == 0) return(NULL)

  # Physical scaling: Action = p * q
  # In this context, we treat the erasure distance as an offset in the Action canvas
  q = p
  action = q * p
  raw_fluc <- dt[["erasure_distance"]] * action
  f_rng <- range(raw_fluc, na.rm = TRUE)

  # --- 2. THE BINNING (Odd-Bin Symmetry) ---
  # We find the furthest point to define a symmetric boundary
  max_extent <- max(abs(f_rng))

  # Round up to next whole number to ensure the grid covers all potential data
  limit <- ceiling(max_extent)

  # Offset by half-bin to capture 0.0 in the center of the middle bin
  half_bin <- bin_width / 2
  breaks_seq <- seq(-limit - half_bin, limit + half_bin, by = bin_width)

  # Generate the histogram
  h <- graphics::hist(raw_fluc, breaks = breaks_seq, plot = FALSE)

  # --- 3. FORMAT OUTPUT ---
  density_df <- data.table::data.table(
    normalized_momentum = p,
    coordinate_q        = h$mids,
    density_count       = h$counts
  )

  # Clean floating point noise at origin to ensure 0.0 is exact
  density_df$coordinate_q[abs(density_df$coordinate_q) < 1e-10] <- 0

  # --- 4. THE SURGICAL TRIM ---
  # Remove zero-valued bins from the edges, but keep internal zeros.
  # This removes the "dead air" created by the ceiling() and symmetric grid logic.
  nz_indices <- which(density_df$density_count > 0)

  if (length(nz_indices) > 0) {
    # Slice from the first bin that has data to the last bin that has data
    density_df <- density_df[min(nz_indices):max(nz_indices)]
  } else {
    # If the file somehow contains only zeros, return NULL to avoid downstream errors
    return(NULL)
  }

  return(density_df)
}
