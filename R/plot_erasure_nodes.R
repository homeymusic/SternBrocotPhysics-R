#' Render the Node Count vs Action Scatter Plot
#'
#' @param dt_summary data.table containing action_A and node_count.
#' @param max_action Numeric, maximum action to plot on the x-axis. Defaults to 50.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family.
#' @param mono_font String for the monospaced font family.
#' @import ggplot2
#' @import data.table
#' @export
plot_erasure_nodes <- function(dt_summary, max_action = 50,
                               style = c("manuscript", "readme"),
                               base_font = "", mono_font = "") {

  style <- match.arg(style)
  is_ms <- style == "manuscript"

  if (base_font == "") base_font <- "sans"
  if (mono_font == "") mono_font <- "mono"

  # Ensure necessary columns exist
  if (!all(c("action_A", "node_count") %in% names(dt_summary))) {
    stop("dt_summary must contain 'action_A' and 'node_count'")
  }

  # Prepare background data: bound explicitly from 1.0 to max_action
  dt_bg <- dt_summary[action_A >= 1.0 & action_A <= max_action & !is.na(node_count) & node_count >= 0]

  # Base Plot
  p <- ggplot() +
    # High-density, solid black scatter points (Line removed entirely)
    geom_point(data = dt_bg, aes(x = action_A, y = node_count),
               color = "black", size = 0.5, alpha = 1.0) +

    scale_x_continuous(breaks = seq(0, max_action, by = 10), limits = c(1.0, max_action)) +
    scale_y_continuous(breaks = seq(0, max(dt_bg$node_count, na.rm = TRUE), by = 10)) +
    theme_minimal(base_family = base_font) +
    theme(panel.grid.minor = element_blank())

  # Style Overrides
  if (!is_ms) {
    p <- p + labs(
      title = "Node Count vs. Classical Action",
      x = expression("Classical Action (" * A/A[0] * ")"),
      y = "Topological Nodes (n)"
    ) +
      theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
  } else {
    # PRL-style mathematical labels
    p <- p + labs(
      x = expression("Classical Action, " * italic(A)/italic(A)[0]),
      y = expression("Topological Nodes, " * italic(n))
    )
  }

  return(p)
}
