#' Compute Action Density from Raw Data
#'
#' @param dt A data.table containing 'found' and the target column.
#' @param p The momentum value (numeric).
#' @param target_col The exact string name of the column to process.
#' @param bin_width The absolute physical resolution in action space.
#' @return A data.table with columns: normalized_momentum, coordinate_q, density_count.
#' @export
compute_action_density <- function(dt, p, target_col, bin_width) {
  if ("found" %in% names(dt)) dt <- dt[dt$found == 1, ]
  if (nrow(dt) == 0) return(NULL)

  # Scale strictly to physical action space
  raw_fluc <- dt[[target_col]] * (p * p)
  max_extent <- max(abs(raw_fluc), na.rm = TRUE)

  # PURE PHYSICS SCALING:
  # No arbitrary safety caps. We trust the physical bin width to scale the grid.
  half_bin <- bin_width / 2
  bins_one_side <- max(0, ceiling((max_extent - half_bin) / bin_width))
  breaks_seq <- (seq(-bins_one_side - 1, bins_one_side) + 0.5) * bin_width

  h <- graphics::hist(raw_fluc, breaks = breaks_seq, plot = FALSE)

  density_df <- data.table::data.table(
    normalized_momentum = p,
    coordinate_q        = h$mids,
    density_count       = h$counts
  )

  density_df$coordinate_q[abs(density_df$coordinate_q) < 1e-10] <- 0
  nz_indices <- which(density_df$density_count > 0)

  if (length(nz_indices) > 0) {
    center_idx <- which(density_df$coordinate_q == 0)
    if(length(center_idx) == 0) return(density_df[nz_indices])

    furthest_active_dist <- max(abs(nz_indices - center_idx))

    keep_min <- max(1, center_idx - furthest_active_dist)
    keep_max <- min(nrow(density_df), center_idx + furthest_active_dist)

    return(density_df[keep_min:keep_max])
  } else {
    return(NULL)
  }
}

#' Process Densities for Multiple Target Columns
#'
#' @param f A raw simulation file path.
#' @param out_path The output directory.
#' @param target_cols A character vector of column names to process.
#' @return A data.table indicating success
#' @export
process_action_densities <- function(f, out_path, target_cols) {
  tryCatch({
    library(data.table)
    setDTthreads(1)

    p_str <- gsub(".*harmonic_oscillator_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", f)
    P_val <- as.numeric(p_str)
    P_effective <- P_val * 2 * pi

    dt <- fread(f, select = c("found", target_cols))

    for (col in target_cols) {
      full_path <- file.path(out_path, sprintf("harmonic_oscillator_%s_density_P_%s.csv.gz", col, p_str))

      if (col == "minimal_program_length") {
        dt_active <- dt[found == 1]
        if(nrow(dt_active) > 0) {
          density_df <- dt_active[, .(density_count = .N), by = .(coordinate_q = get(col))]
          setorder(density_df, coordinate_q)
        } else {
          density_df <- NULL
        }
      } else {
        # THE PURE PHYSICS DIAL:
        # 4 bins per physical node, scaling dynamically with 1/P.
        physics_bin_width <- pi / P_val
        density_df <- compute_action_density(dt, P_effective, target_col = col, bin_width = physics_bin_width)
      }

      if (!is.null(density_df)) {
        density_df$normalized_momentum <- P_val
        fwrite(density_df, full_path, compress = "gzip")
      }
    }
    return(data.table(normalized_momentum = P_val, status = "success"))
  }, error = function(e) return(NULL))
}
