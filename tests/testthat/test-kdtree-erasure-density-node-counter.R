library(ggplot2)
library(data.table)
library(SternBrocotPhysics)
library(testthat)

test_that("KD-Tree erasure density node counts match theoretical expectations", {
  # --- 1. Truth Table (Currently Stern-Brocot values, expected to fail!) ---
  truth_table <- data.table::fread("
    momentum, expected_nodes
    0.1,       0
    0.25,      1
    0.5,       1
    0.75,      0
    1,         1
    2,         1
    3,         4
    4,         13
    5,         17
    6,         10
    7,         22
    8,         15
    9,         25
    10,        17
  ")

  # --- 2. Setup Paths & Enforce Clean Slate ---
  fixtures_dir    <- test_path("fixtures_kdtree_erasure")
  debug_plots_dir <- test_path("_debug_plots_kdtree_erasure")
  debug_data_dir  <- test_path("_debug_data_kdtree_erasure")
  temp_raw_dir    <- file.path(tempdir(), "raw_sim_kdtree_erasure")

  # NUKE THE DIRECTORIES to prevent stale fixture reads
  unlink(fixtures_dir, recursive = TRUE)
  unlink(debug_plots_dir, recursive = TRUE)
  unlink(debug_data_dir, recursive = TRUE)
  unlink(temp_raw_dir, recursive = TRUE)

  # Recreate fresh directories
  for (d in c(fixtures_dir, debug_plots_dir, debug_data_dir, temp_raw_dir)) {
    dir.create(d, recursive = TRUE)
  }

  # --- 3. Loop ---
  for (i in seq_len(nrow(truth_table))) {
    m_val <- truth_table$momentum[i]
    m_str <- sprintf("%013.6f", m_val)
    expected_n <- truth_table$expected_nodes[i]

    # Look specifically for the kdtree erasure processed output
    fixture_path <- file.path(fixtures_dir, sprintf("harmonic_oscillator_erasure_distance_density_kdtree_P_%s.csv.gz", m_str))

    # Pass the 'kdtree' algorithm parameter
    harmonic_oscillator_erasures(
      momenta   = m_val,
      dir       = normalizePath(temp_raw_dir, mustWork = TRUE),
      algorithm = "kdtree",
      n_threads = 1
    )

    # Look specifically for the kdtree raw C++ output
    raw_file <- file.path(temp_raw_dir, sprintf("harmonic_oscillator_erasures_kdtree_P_%s.csv.gz", m_str))

    # --- REFACTORED TEST LOGIC ---
    if (file.exists(raw_file)) {
      process_action_densities(
        f = raw_file,
        out_path = fixtures_dir,
        target_cols = c("erasure_distance")
      )
      unlink(raw_file)
    }

    if (!file.exists(fixture_path)) {
      fail(sprintf("Fixture file was not created by process_action_densities for P=%s", m_val))
      next
    }

    # --- ASSERTION ---
    density_data <- data.table::fread(fixture_path)
    data.table::setnames(density_data, old = c("coordinate_q", "density_count"), new = c("x", "y"))

    results <- count_nodes(density_data)

    bw <- if(nrow(density_data) > 1) diff(density_data$x[1:2])[1] else 0.1

    # --- TRUE SKYLINE PATH LOGIC ---
    skyline_x <- c(density_data$x[1] - bw/2,
                   rep(density_data$x, each = 2) + rep(c(-bw/2, bw/2), nrow(density_data)),
                   density_data$x[nrow(density_data)] + bw/2)

    skyline_y <- c(0, rep(density_data$y, each = 2), 0)

    outline_data <- data.table::data.table(x = skyline_x, y = skyline_y)

    # --- DEBUGGING & PLOTS ---
    p <- ggplot() +
      geom_col(data = density_data, aes(x, y), fill = "black", alpha = 0.25, width = bw) +
      geom_path(data = outline_data, aes(x, y), color = "black", linewidth = 0.3) +
      labs(title = paste("Diagnostic (KD-Tree | Erasure) | P =", m_val),
           subtitle = sprintf("Actual: %s | Expected: %s | Bins: %d",
                              results$node_count, expected_n, nrow(density_data))) +
      theme_minimal()

    if (!is.null(results$nodes) && nrow(results$nodes) > 0) {
      p <- p + geom_point(data = results$nodes, aes(x, y), color = "blue", size = 2)
    }

    # --- FAILURE DUMP ---
    is_mismatch <- if (is.na(expected_n)) !is.na(results$node_count) else (is.na(results$node_count) || results$node_count != expected_n)

    if (is_mismatch) {
      pdf_path <- file.path(debug_plots_dir, sprintf("node_debug_kdtree_erasure_P_%s.pdf", m_str))
      ggsave(pdf_path, plot = p, device = "pdf", width = 8, height = 6)

      dump_file <- file.path(debug_data_dir, sprintf("FAILURE_DATA_kdtree_erasure_P_%s.csv", m_str))
      data.table::fwrite(density_data, dump_file)

      message(sprintf("[!!!] FAILURE P=%s. Plot and Data dumped.", m_val))
    }

    test_info <- sprintf("FAILURE P=%s (Expected: %s, Actual: %s)", m_val, expected_n, results$node_count)
    if (is.na(expected_n)) {
      expect_true(is.na(results$node_count), info = test_info)
    } else {
      expect_equal(results$node_count, expected_n, info = test_info)
    }

    vdiffr::expect_doppelganger(paste0("baseline_nodes_kdtree_erasure_P_", m_str), p)
  }

  unlink(temp_raw_dir, recursive = TRUE)
})
