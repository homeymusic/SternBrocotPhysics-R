#' Compute Action Density from Raw Erasures
#'
#' Converts raw erasure distances into a normalized Action density histogram.
#' Handles the P^2 scaling and ensures odd-bin symmetry centered at zero.
#' Uses Rice's Rule to adaptively prevent Poisson noise at extreme momenta.
#'
#' @param dt A data.table containing a 'found' and 'erasure_distance' column.
#' @param p The momentum value (numeric).
#' @param bin_width The minimum resolution of the histogram (default 1).
#' @return A data.table with columns: normalized_momentum, coordinate_q, density_count.
#' @export
compute_density <- function(dt, p, bin_width = 1) {
  # --- 1. PRE-PROCESSING ---
  if ("found" %in% names(dt)) {
    dt <- dt[dt$found == 1, ]
  }

  if (nrow(dt) == 0) return(NULL)

  # Physical scaling to Action Space
  q = p
  action = q * p
  raw_fluc <- dt[["erasure_distance"]] * action

  # --- 2. THE BINNING (Adaptive via Rice's Rule) ---
  max_extent <- max(abs(raw_fluc), na.rm = TRUE)

  # Principled Adaptive Binning: Rice's Rule
  N <- nrow(dt)
  target_max_bins <- ceiling(2 * (N^(1/3))) # ~93 bins for N=100,001

  adaptive_bw <- (max_extent * 2) / target_max_bins
  actual_bw <- max(bin_width, adaptive_bw)

  # BULLETPROOF BREAKS GENERATION (Avoids floating point seq() errors)
  half_bin <- actual_bw / 2

  # Calculate exactly how many bins we need on one side of 0.0
  bins_one_side <- ceiling((max_extent - half_bin) / actual_bw)
  bins_one_side <- max(0, bins_one_side) # Safety catch for max_extent = 0

  # Use integer vector math to build breaks mathematically
  break_indices <- seq(-bins_one_side - 1, bins_one_side)
  breaks_seq <- (break_indices + 0.5) * actual_bw

  h <- graphics::hist(raw_fluc, breaks = breaks_seq, plot = FALSE)

  # --- 3. FORMAT OUTPUT ---
  density_df <- data.table::data.table(
    normalized_momentum = p,
    coordinate_q        = h$mids,
    density_count       = h$counts
  )

  # Clean floating point noise at origin
  density_df$coordinate_q[abs(density_df$coordinate_q) < 1e-10] <- 0

  # --- 4. THE SURGICAL TRIM (Symmetric & Odd-Guaranteed) ---
  nz_indices <- which(density_df$density_count > 0)

  if (length(nz_indices) > 0) {
    center_idx <- which(density_df$coordinate_q == 0)
    furthest_active_dist <- max(abs(nz_indices - center_idx))

    keep_min <- center_idx - furthest_active_dist
    keep_max <- center_idx + furthest_active_dist

    density_df <- density_df[keep_min:keep_max]
  } else {
    return(NULL)
  }

  return(density_df)
}

#' Process Erasure Distance Density
#'
#' Process
#'
#' @param f A file
#' @param out_path A dir
#' @return A data.table
#' @export
process_erasure_distance_density <- function(f, out_path) {
  tryCatch({
    library(data.table)
    setDTthreads(1)

    p_str <- gsub(".*erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)

    full_path <- file.path(out_path, sprintf("erasure_distance_density_P_%s.csv.gz", p_str))

    dt <- fread(f, select = c("found", "erasure_distance"))

    P_effective <- P_val * 2 * pi

    density_df <- compute_density(dt, P_effective, bin_width = 1.0)

    if (is.null(density_df)) return(NULL)

    density_df$normalized_momentum <- P_val

    fwrite(density_df, full_path, compress = "gzip")

    return(data.table(normalized_momentum = P_val, status = "success"))

  }, error = function(e) return(NULL))
}
