library(ggplot2)
library(data.table)
library(SternBrocotPhysics)
library(testthat)

test_that("Node counts match theoretical expectations for specific momenta", {
  # --- 1. Truth Table Definition ---
  # P=1 is NA (Vacuum), P=17 is 4 (Conservative Physics)
  truth_table <- data.table::fread("
    momentum, expected_nodes
    1,         NA
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

  # Local Temporary Simulation Path
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

      SternBrocotPhysics::erasures(
        momenta   = m_val,
        dir       = normalizePath(temp_raw_dir, mustWork = TRUE),
        count     = 1e5 + 1,
        n_threads = 1
      )

      raw_file <- file.path(temp_raw_dir, sprintf("erasures_P_%s.csv.gz", m_str))

      if (file.exists(raw_file)) {
        dt_raw <- data.table::fread(raw_file, select = c("found", "erasure_distance"))

        # FIX: Explicit subsetting to avoid testthat scoping error
        dt_raw <- dt_raw[dt_raw$found == 1, ]

        if (nrow(dt_raw) > 0) {
          raw_fluc <- dt_raw$erasure_distance * (m_val^2)
          f_rng <- range(raw_fluc, na.rm = TRUE)
          h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)

          density_df <- data.frame(x = h$mids, y = h$counts)
          density_df$x[abs(density_df$x) < 1e-10] <- 0
          data.table::fwrite(data.table::as.data.table(density_df), fixture_path, compress = "gzip")
        }
        unlink(raw_file)
      } else {
        # Fallback for vacuum state (P=1 often produces no valid erasures)
        # Create a dummy zero-signal file so we test the NA logic
        dummy_df <- data.table::data.table(x=seq(-10,10,0.1), y=0)
        data.table::fwrite(dummy_df, fixture_path, compress = "gzip")
      }
    }

    # --- Step 2: Run the Measure Logic ---
    density_data <- data.table::fread(fixture_path)
    results <- count_nodes(density_data)

    # --- Step 3: Build Diagnostic Plot ---
    p <- ggplot(density_data, aes(x, y)) +
      geom_col(fill = "black", alpha = 0.25) +
      geom_step(direction = "hv", color = "black", linewidth = 0.3) +
      labs(title = paste("Diagnostic Scan | P =", m_val),
           subtitle = sprintf("Expected: %s | Found: %s",
                              ifelse(is.na(expected_n), "NA", expected_n),
                              ifelse(is.na(results$node_count), "NA", results$node_count)),
           x = "coordinate q (Action)", y = "density count") +
      theme_minimal(base_family = "mono")

    if (!is.null(results$nodes) && nrow(results$nodes) > 0) {
      p <- p + geom_point(data = results$nodes, aes(x, y), color = "red", size = 2, shape = 16)
    }

    pdf_path <- file.path(debug_dir, sprintf("node_debug_P_%s.pdf", m_str))
    ggsave(pdf_path, plot = p, device = "pdf", width = 8, height = 6)

    # --- Step 4: Assertion ---
    test_info <- sprintf("\n---> FAILURE AT P = %s\n---> Expected: %s\n---> Actual: %s\n---> Plot: %s",
                         m_val,
                         ifelse(is.na(expected_n), "NA", expected_n),
                         ifelse(is.na(results$node_count), "NA", results$node_count),
                         pdf_path)

    if (is.na(expected_n)) {
      expect_true(is.na(results$node_count), info = test_info)
    } else {
      expect_equal(results$node_count, expected_n, info = test_info)
    }

    vdiffr::expect_doppelganger(paste0("baseline_nodes_P_", m_str), p)
  }
})
