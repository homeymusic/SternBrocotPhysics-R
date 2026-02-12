library(ggplot2)
library(data.table)
library(SternBrocotPhysics)

test_that("Node counts match theoretical expectations for specific momenta", {
  truth_table <- data.table::fread("
    momentum, expected_nodes
    3,        0
    5,        1
    7,        2
    9,        3
    10,       1
    11,       1
    12,       1
    13,       4
    14,       5
    15,       1
    16,       6
    17,       6
  ")

  # Setup Paths
  fixtures_dir <- test_path("fixtures")
  if (!dir.exists(fixtures_dir)) dir.create(fixtures_dir, recursive = TRUE)

  debug_dir <- test_path("_debug_plots")
  if (!dir.exists(debug_dir)) dir.create(debug_dir)

  # Local Temporary Simulation Path
  temp_raw_dir <- file.path(tempdir(), "raw_sim")
  if (!dir.exists(temp_raw_dir)) dir.create(temp_raw_dir)

  for (i in seq_len(nrow(truth_table))) {
    m_val <- truth_table$momentum[i]
    m_str <- sprintf("%013.6f", m_val)
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
      dt_raw <- data.table::fread(raw_file, select = c("found", "erasure_distance"))

      # Use explicit subsetting to avoid NSE issues in tests
      dt_raw <- dt_raw[dt_raw[["found"]] == 1, ]

      if (nrow(dt_raw) > 0) {
        # Physics calc: Fluctuation = d * P^2
        raw_fluc <- dt_raw[["erasure_distance"]] * (m_val^2)
        f_rng <- range(raw_fluc, na.rm = TRUE)

        h <- graphics::hist(raw_fluc, breaks = seq(f_rng[1], f_rng[2], length.out = 402), plot = FALSE)

        # Create as standard data.frame first to bypass cedta() issues
        density_df <- data.frame(x = h$mids, y = h$counts)

        # FIX: Standard base R assignment instead of :=
        density_df$x[abs(density_df$x) < 1e-10] <- 0

        # Convert to data.table only for the final save
        data.table::fwrite(data.table::as.data.table(density_df), fixture_path, compress = "gzip")
      }
      unlink(raw_file)
    }

    # --- Step 2: Run the Test ---
    density_data <- data.table::fread(fixture_path)
    results <- count_nodes(density_data)

    # --- Step 3: Build Plot ---
    p <- ggplot(density_data, aes(x, y)) +
      geom_col(fill = "black", alpha = 0.25) +
      geom_step(direction = "hv", color = "black", linewidth = 0.3) +
      geom_point(data = results$nodes, aes(x, y), color = "red", size = 2, shape = 16) +
      labs(title = paste("P =", m_val, "| Nodes Found:", results$node_count),
           subtitle = paste("Expected:", truth_table$expected_nodes[i])) +
      theme_minimal(base_family = "mono")

    # 1. Standard vdiffr SVG
    vdiffr::expect_doppelganger(paste0("baseline_nodes_P_", m_str), p)

    # 2. PDF Export
    pdf_path <- file.path(debug_dir, sprintf("node_debug_P_%s.pdf", m_str))
    ggsave(pdf_path, plot = p, device = "pdf", width = 8, height = 6)

    # Numeric check
    expect_equal(results$node_count, truth_table$expected_nodes[i])
  }
})
