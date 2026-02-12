library(ggplot2)
library(data.table)
library(SternBrocotPhysics)
library(testthat)

test_that("Node counts match theoretical expectations for specific momenta", {
  # --- 1. Truth Table Definition ---
  truth_table <- data.table::fread("
    momentum, expected_nodes
    3,         0
    5,         1
    7,         2
    9,         3
    10,        1
    11,        1
    12,        1
    13,        4
    14,        5
    15,        1
    16,        6
    17,        4
  ")

  # --- 2. Setup Paths ---
  fixtures_dir <- test_path("fixtures")
  if (!dir.exists(fixtures_dir)) dir.create(fixtures_dir, recursive = TRUE)

  debug_dir <- test_path("_debug_plots")
  if (!dir.exists(debug_dir)) dir.create(debug_dir)

  # Local Temporary Simulation Path (for on-the-fly fixture generation)
  temp_raw_dir <- file.path(tempdir(), "raw_sim")
  if (!dir.exists(temp_raw_dir)) dir.create(temp_raw_dir)

  # --- 3. Loop through Momentum Steps ---
  for (i in seq_len(nrow(truth_table))) {
    m_val <- truth_table$momentum[i]
    m_str <- sprintf("%013.6f", m_val)
    expected_n <- truth_table$expected_nodes[i]
    fixture_path <- file.path(fixtures_dir, sprintf("density_P_%s.csv.gz", m_str))

    # --- Step 1: Self-Generate Fixture if missing ---
    if (!file.exists(fixture_path)) {
      message(sprintf("Generating missing fixture for P = %s...", m_val))

      # Use the plural erasures() call matching our 01 pattern
      SternBrocotPhysics::erasures(
        momenta   = m_val,
        dir       = normalizePath(temp_raw_dir, mustWork = TRUE),
        count     = 1e5 + 1,
        n_threads = 1
      )

      raw_file <- file.path(temp_raw_dir, sprintf("erasures_P_%s.csv.gz", m_str))
      dt_raw <- data.table::fread(raw_file, select = c("found", "erasure_distance"))
      dt_raw <- dt_raw[found == 1]

      if (nrow(dt_raw) > 0) {
        # Physics calc: Fluctuation Q = d * P^2
        raw_fluc <- dt_raw$erasure_distance * (m_val^2)
        f_rng <- range(raw_fluc, na.rm = TRUE)
        h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)

        density_df <- data.frame(x = h$mids, y = h$counts)
        density_df$x[abs(density_df$x) < 1e-10] <- 0
        data.table::fwrite(data.table::as.data.table(density_df), fixture_path, compress = "gzip")
      }
      if (file.exists(raw_file)) unlink(raw_file)
    }

    # --- Step 2: Run the Measure Logic ---
    density_data <- data.table::fread(fixture_path)
    # The count_nodes function is what we are currently refining
    results <- count_nodes(density_data)

    # --- Step 3: Build Diagnostic Plot ---
    p <- ggplot(density_data, aes(x, y)) +
      geom_col(fill = "black", alpha = 0.25) +
      geom_step(direction = "hv", color = "black", linewidth = 0.3) +
      labs(title = paste("Diagnostic Scan | P =", m_val),
           subtitle = sprintf("Expected: %d | Found: %d", expected_n, results$node_count),
           x = "coordinate q (Action)", y = "density count") +
      theme_minimal(base_family = "mono")

    # Add red dots if any were detected (even false positives)
    if (!is.null(results$nodes) && nrow(results$nodes) > 0) {
      p <- p + geom_point(data = results$nodes, aes(x, y), color = "red", size = 2, shape = 16)
    }

    # Save debug PDF for manual inspection of failures
    pdf_path <- file.path(debug_dir, sprintf("node_debug_P_%s.pdf", m_str))
    ggsave(pdf_path, plot = p, device = "pdf", width = 8, height = 6)

    # --- Step 4: Numeric Assertion with Info ---
    # The info string will print in the test results only upon failure
    test_info <- sprintf("\n---> FAILURE AT P = %s\n---> Expected: %d\n---> Actual: %d\n---> Plot: %s",
                         m_val, expected_n, results$node_count, pdf_path)

    expect_equal(results$node_count, expected_n, info = test_info)

    # Optional visual snapshot test (vdiffr)
    vdiffr::expect_doppelganger(paste0("baseline_nodes_P_", m_str), p)
  }
})
