library(ggplot2)
library(data.table)
library(SternBrocotPhysics)
library(testthat)

test_that("Node counts match theoretical expectations for specific momenta", {
  # --- 1. Truth Table ---
  truth_table <- data.table::fread("
    momentum, expected_nodes
    0.5,       0
    1.639,     1
  ")

  # --- 2. Setup Paths ---
  fixtures_dir    <- test_path("fixtures")
  debug_plots_dir <- test_path("_debug_plots")
  debug_data_dir  <- test_path("_debug_data")
  temp_raw_dir    <- file.path(tempdir(), "raw_sim")

  # Ensure directories exist
  for (d in c(fixtures_dir, debug_plots_dir, debug_data_dir, temp_raw_dir)) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }

  # --- 3. Loop ---
  for (i in seq_len(nrow(truth_table))) {
    m_val <- truth_table$momentum[i]
    m_str <- sprintf("%013.6f", m_val)
    expected_n <- truth_table$expected_nodes[i]

    fixture_path <- file.path(fixtures_dir, sprintf("density_P_%s.csv.gz", m_str))

    # --- FORCED GENERATION ---
    # We no longer check if the file exists. We always regenerate to ensure
    # the fixtures match the current package version logic.
    message(sprintf("Generating fresh fixture for P = %s...", m_val))

    SternBrocotPhysics::erasures(
      momenta   = m_val,
      dir       = normalizePath(temp_raw_dir, mustWork = TRUE),
      n_threads = 1
    )

    raw_file <- file.path(temp_raw_dir, sprintf("erasures_P_%s.csv.gz", m_str))

    # --- UPDATED TEST LOGIC ---
    if (file.exists(raw_file)) {
      dt_raw <- data.table::fread(raw_file, select = c("found", "erasure_distance"))

      # MATCH THE PRODUCTION SCALING:
      p_effective <- m_val * 2 * pi
      density_df <- SternBrocotPhysics::compute_density(dt_raw, p_effective, bin_width = 1.0)

      if (!is.null(density_df)) {
        # MATCH PRODUCTION METADATA RESTORATION:
        density_df$normalized_momentum <- m_val
        data.table::fwrite(density_df, fixture_path, compress = "gzip")
      }
      unlink(raw_file)
    }

    # --- ASSERTION ---
    density_data <- data.table::fread(fixture_path)
    data.table::setnames(density_data, old = c("coordinate_q", "density_count"), new = c("x", "y"))

    results <- count_nodes(density_data)

    bw <- if(nrow(density_data) > 1) diff(density_data$x[1:2])[1] else 0.1

    # --- DEBUGGING & PLOTS ---
    p <- ggplot(density_data, aes(x, y)) +
      geom_col(fill = "black", alpha = 0.25, width = bw) +
      geom_step(direction = "mid", color = "black", linewidth = 0.3) +
      labs(title = paste("Diagnostic | P =", m_val),
           subtitle = sprintf("Actual: %s | Expected: %s", results$node_count, expected_n)) +
      theme_minimal()

    if (!is.null(results$nodes) && nrow(results$nodes) > 0) {
      p <- p + geom_point(data = results$nodes, aes(x, y), color = "red", size = 2)
    }

    pdf_path <- file.path(debug_plots_dir, sprintf("node_debug_P_%s.pdf", m_str))
    ggsave(pdf_path, plot = p, device = "pdf", width = 8, height = 6)

    # --- FAILURE DUMP ---
    is_mismatch <- if (is.na(expected_n)) !is.na(results$node_count) else (is.na(results$node_count) || results$node_count != expected_n)

    if (is_mismatch) {
      dump_file <- file.path(debug_data_dir, sprintf("FAILURE_DATA_P_%s.csv", m_str))
      data.table::fwrite(density_data, dump_file)
      message(sprintf("[!!!] FAILURE P=%s. Data dumped.", m_val))
    }

    test_info <- sprintf("FAILURE P=%s (Expected: %s, Actual: %s)", m_val, expected_n, results$node_count)
    if (is.na(expected_n)) {
      expect_true(is.na(results$node_count), info = test_info)
    } else {
      expect_equal(results$node_count, expected_n, info = test_info)
    }

    vdiffr::expect_doppelganger(paste0("baseline_nodes_P_", m_str), p)
  }

  # Final Cleanup of temp simulation files
  unlink(temp_raw_dir, recursive = TRUE)
})
