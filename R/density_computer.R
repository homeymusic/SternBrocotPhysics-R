#' Compute Action Density from Raw Data
#'
#' @param dt A data.table containing 'found' and the target column.
#' @param p The momentum value (numeric).
#' @param target_col The exact string name of the column to process.
#' @param n_bins The exact number of unique quantum states to use as the bin count.
#' @return A data.table with columns: normalized_momentum, coordinate_q, density_count.
#' @export
compute_action_density <- function(dt, p, target_col, n_bins) {
  if ("found" %in% names(dt)) dt <- dt[dt$found == 1, ]
  if (nrow(dt) == 0) return(NULL)

  # Scale strictly to physical action space
  raw_fluc <- dt[[target_col]] * (p * p)

  # Safety catch for 0 variance or single-state ground systems
  if (n_bins <= 1 || diff(range(raw_fluc, na.rm=TRUE)) == 0) {
    return(data.table::data.table(
      normalized_momentum = p,
      coordinate_q = 0, # Force to exact absolute zero
      density_count = nrow(dt)
    ))
  }

  # The system is perfectly symmetric, so max(abs()) is the true outer bound
  max_extent <- max(abs(raw_fluc), na.rm = TRUE)

  # EXACT SYMMETRIC GRID MATH:
  # n_bins is GUARANTEED to be odd here.
  bins_one_side <- (n_bins - 1) / 2
  state_spacing <- max_extent / bins_one_side

  # Build breaks symmetrically outwards from EXACTLY 0.0
  breaks_seq <- (seq(-bins_one_side - 1, bins_one_side) + 0.5) * state_spacing

  h <- graphics::hist(raw_fluc, breaks = breaks_seq, plot = FALSE)

  density_df <- data.table::data.table(
    normalized_momentum = p,
    coordinate_q        = h$mids,
    density_count       = h$counts
  )

  # Snap microscopic floating-point noise directly to absolute zero
  density_df$coordinate_q[abs(density_df$coordinate_q) < 1e-10] <- 0
  nz_indices <- which(density_df$density_count > 0)

  if (length(nz_indices) > 0) {
    # Dynamically find the center to crop empty edge space
    center_idx <- which.min(abs(density_df$coordinate_q))
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

    p_str <- gsub(".*harmonic_oscillator_erasures_P_([0-9.]+)\\.csv\\.gz", "\\1", basename(f))
    P_val <- as.numeric(p_str)
    P_effective <- P_val * 2 * pi

    dt <- fread(f, select = c("found", target_cols))

    # -------------------------------------------------------------
    # THE NEW DISCRETE BINDING LOGIC (STRICT DETERMINISM)
    # -------------------------------------------------------------
    if ("minimal_action_state" %in% names(dt)) {
      # Use signif() to safely group floating-point representations of the exact same state
      unique_states <- unique(signif(dt[found == 1, minimal_action_state], 7))
      n_unique_states <- length(unique_states)

      # 🚨 FAIL FAST ALARM BELL 🚨
      # If the deterministic Stern-Brocot symmetry is broken, kill the process.
      if (n_unique_states %% 2 == 0) {
        stop(sprintf(
          "\n[CRITICAL PHYSICS FAILURE] Deterministic symmetry broken at P=%s.\nFound an EVEN number of states (%d).\nThe Stern-Brocot phase space must be strictly symmetric (odd).",
          p_str, n_unique_states
        ))
      }
    } else {
      # For metrics that don't have discrete state lists, enforce an odd baseline
      n_unique_states <- max(5, floor(P_val * 10))
      if (n_unique_states %% 2 == 0) n_unique_states <- n_unique_states + 1
    }

    for (col in target_cols) {
      full_path <- file.path(out_path, sprintf("harmonic_oscillator_%s_density_P_%s.csv.gz", col, p_str))

      if (col == "minimal_program_length") {
        # Program length is already naturally grouped by exact integer values
        dt_active <- dt[found == 1]
        if(nrow(dt_active) > 0) {
          density_df <- dt_active[, .(density_count = .N), by = .(coordinate_q = get(col))]
          setorder(density_df, coordinate_q)
        } else {
          density_df <- NULL
        }
      } else {
        # Pass the exact number of discrete states to the histogram
        density_df <- compute_action_density(dt, P_effective, target_col = col, n_bins = n_unique_states)
      }

      if (!is.null(density_df)) {
        density_df$normalized_momentum <- P_val
        fwrite(density_df, full_path, compress = "gzip")
      } else {
        empty_df <- data.table(normalized_momentum = P_val, coordinate_q = numeric(), density_count = numeric())
        fwrite(empty_df, full_path, compress = "gzip")
      }
    }
    return(data.table(normalized_momentum = P_val, status = "success"))
  }, error = function(e) {
    # If the fail-fast alarm triggers, propagate it up out of the tryCatch
    if (grepl("CRITICAL PHYSICS FAILURE", e$message)) stop(e$message)
    return(NULL)
  })
}
