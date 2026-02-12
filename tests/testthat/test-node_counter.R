library(ggplot2)
library(data.table)

test_that("Node counts match theoretical expectations for specific momenta", {
  truth_table <- data.table::fread("
    momentum, expected_nodes
    9.97,     1
    9.98,     1
  ")

  for (i in seq_len(nrow(truth_table))) {
    m_val <- truth_table$momentum[i]
    m_str <- sprintf("%013.6f", m_val)

    file_path <- test_path("fixtures", sprintf("density_P_%s.csv.gz", m_str))
    density_data <- data.table::fread(file_path)

    # Run the counter
    results <- count_nodes(density_data)

    # --- Baseline Visualization (Matching your README style) ---
    # We use density_data explicitly in the dots to avoid scope issues
    p <- ggplot(density_data, aes(x, y)) +
      geom_col(fill = "black", alpha = 0.25) + # Match README bars
      geom_step(direction = "hv", color = "black", linewidth = 0.3) +
      geom_point(data = results$nodes, aes(x, y), color = "red", size = 2, shape = 16) +
      labs(title = paste("P =", m_val, "| Nodes Found:", results$node_count),
           subtitle = paste("Expected in Truth Table:", truth_table$expected_nodes[i])) +
      theme_minimal(base_family = "mono")

    # Capture visual fingerprint regardless of pass/fail
    vdiffr::expect_doppelganger(paste0("baseline_nodes_P_", m_str), p)

    # Numeric check against truth table
    expect_equal(results$node_count, truth_table$expected_nodes[i],
                 info = paste("Baseline deviation at P =", m_val))
  }
})
