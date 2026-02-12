library(ggplot2)
library(data.table)

test_that("Node counts match theoretical expectations for specific momenta", {
  truth_table <- data.table::fread("
    momentum, expected_nodes
    9.97,     1
    9.98,     1
  ")

  # Create a debug directory for your PDFs if it doesn't exist
  debug_dir <- test_path("_debug_plots")
  if (!dir.exists(debug_dir)) dir.create(debug_dir)

  for (i in seq_len(nrow(truth_table))) {
    m_val <- truth_table$momentum[i]
    m_str <- sprintf("%013.6f", m_val)

    file_path <- test_path("fixtures", sprintf("density_P_%s.csv.gz", m_str))
    density_data <- data.table::fread(file_path)

    # Run the counter
    results <- count_nodes(density_data)

    # --- Build Plot ---
    p <- ggplot(density_data, aes(x, y)) +
      geom_col(fill = "black", alpha = 0.25) +
      geom_step(direction = "hv", color = "black", linewidth = 0.3) +
      geom_point(data = results$nodes, aes(x, y), color = "red", size = 2, shape = 16) +
      labs(title = paste("P =", m_val, "| Nodes Found:", results$node_count),
           subtitle = paste("Expected:", truth_table$expected_nodes[i])) +
      theme_minimal(base_family = "mono")

    # 1. Standard vdiffr SVG (Required for the test harness)
    vdiffr::expect_doppelganger(paste0("baseline_nodes_P_", m_str), p)

    # 2. PDF Export (For your external apps and manual inspection)
    # This will save to tests/testthat/debug_plots/
    pdf_path <- file.path(debug_dir, sprintf("node_debug_P_%s.pdf", m_str))
    ggsave(pdf_path, plot = p, device = "pdf", width = 8, height = 6)

    # Numeric check
    expect_equal(results$node_count, truth_table$expected_nodes[i])
  }
})
