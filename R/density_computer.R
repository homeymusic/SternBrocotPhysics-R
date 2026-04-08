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

    # --- THE REGEX FIX ---
    # Safely extract both the algorithm and the momentum from the new C++ filenames
    base_f <- basename(f)
    matches <- regmatches(base_f, regexec("harmonic_oscillator_erasures_(.*)_P_([0-9.]+)\\.csv\\.gz", base_f))

    if (length(matches[[1]]) == 3) {
      algo_str <- matches[[1]][2]
      p_str    <- matches[[1]][3]
    } else {
      # Fallback just in case you process an old file generated before the refactor
      p_str    <- gsub(".*_P_([0-9.]+)\\.csv\\.gz", "\\1", base_f)
      algo_str <- "stern_brocot"
    }

    P_val <- as.numeric(p_str)
    P_effective <- P_val

    # --- THE FREAD FIX ---
    # Dynamically guarantee 'selected_microstate' is always loaded for the physics check
    cols_to_read <- unique(c("found", "selected_microstate", target_cols))
    dt <- fread(f, select = cols_to_read, colClasses = list(character = "encoded_sequence"))

    # -------------------------------------------------------------
    # THE NEW DISCRETE BINDING LOGIC (STRICT DETERMINISM)
    # -------------------------------------------------------------
    if (!"selected_microstate" %in% names(dt)) {
      stop(sprintf(
        "\n[FATAL PIPELINE ERROR] Missing 'selected_microstate' at P=%s.\nCannot determine absolute phase-space granularity. Ensure 'selected_microstate' is in target_cols.",
        p_str
      ))
    }

    unique_states <- unique(signif(dt[found == 1, selected_microstate], 7))
    n_unique_states <- length(unique_states)

    if (n_unique_states %% 2 == 0) {
      stop(sprintf(
        "\n[CRITICAL PHYSICS FAILURE] Deterministic symmetry broken at P=%s.\nFound an EVEN number of states (%d).\nThe phase space must be strictly symmetric (odd).",
        p_str, n_unique_states
      ))
    }

    for (col in target_cols) {
      # --- OUTPUT FILENAME FIX ---
      # Inject the algorithm string into the output file so kdtree and stern_brocot don't overwrite each other
      full_path <- file.path(out_path, sprintf("harmonic_oscillator_%s_density_%s_P_%s.csv.gz", col, algo_str, p_str))

      # UPDATED to match "sequence_length"
      if (col == "sequence_length") {
        dt_active <- dt[found == 1]
        if(nrow(dt_active) > 0) {
          density_df <- dt_active[, .(density_count = .N), by = .(coordinate_q = get(col))]
          setorder(density_df, coordinate_q)
        } else {
          density_df <- NULL
        }
      } else {
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
    if (grepl("CRITICAL PHYSICS FAILURE", e$message)) stop(e$message)
    # Print the error so it doesn't fail silently next time!
    message(sprintf("Error processing file %s: %s", basename(f), e$message))
    return(NULL)
  })
}
