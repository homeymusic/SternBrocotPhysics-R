#' Render the Landauer Action vs Classical Action Plot
#'
#' @param dt_summary data.table containing sequence length summary metrics.
#' @param max_action Numeric, maximum action to plot on the x-axis. Defaults to 50.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family.
#' @import ggplot2
#' @import data.table
#' @export
plot_erasure_action <- function(dt_summary, max_action = 50,
                                style = c("manuscript", "readme"),
                                base_font = "") {

  style <- match.arg(style)
  is_ms <- style == "manuscript"

  if (base_font == "") base_font <- "sans"

  # Ensure necessary columns exist
  req_cols <- c("action_A", "min_len", "max_len", "lower", "upper", "mean_len", "median_len")
  if (!all(req_cols %in% names(dt_summary))) {
    stop("dt_summary is missing required columns.")
  }

  # Filter data slightly past max_action to ensure smooth ribbon edges
  dt_plot <- dt_summary[action_A <= max_action * 1.05]

  # Base Plot
  p <- ggplot(dt_plot, aes(x = action_A)) +
    # Variance Ribbons (darkened for better visibility)
    geom_ribbon(aes(ymin = min_len, ymax = max_len, fill = "Total Range"), alpha = 0.4) +
    geom_ribbon(aes(ymin = lower, ymax = upper, fill = "±1 SD"), alpha = 0.5) +
    scale_fill_manual(name = "Variance", values = c("Total Range" = "grey75", "±1 SD" = "grey55")) +

    # Explicit outline for the maximum value (Top edge of the total range)
    geom_line(aes(y = max_len, color = "Maximum"), linewidth = 0.6) +

    # Central Tendencies
    geom_line(aes(y = mean_len, color = "Mean"), linewidth = 0.8, linetype = "dashed") +
    geom_step(aes(y = median_len, color = "Median"), linewidth = 1.2) +

    scale_color_manual(name = "Metric",
                       values = c("Mean" = "gray30",
                                  "Median" = "black",
                                  "Maximum" = "gray40")) +

    scale_x_continuous(breaks = seq(0, max_action, by = 10)) +
    coord_cartesian(xlim = c(0, max_action)) +
    theme_minimal(base_family = base_font) +
    theme(
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )

  # Style Overrides
  if (!is_ms) {
    p <- p + labs(
      title = "Landauer Action vs. Classical Action",
      x = expression("Classical Action, " * A/A[0]),
      y = expression("Landauer Action, " * A[L] ~ "[" * k[B] * T ~ "ln 2" ~ tau * "]")
    ) +
      theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
  } else {
    # PRL-style mathematical labels
    p <- p + labs(
      x = expression("Classical Action, " * italic(A)/italic(A)[0]),
      y = expression("Landauer Action, " * italic(A)[L] ~ "[" * italic(k)[B] * italic(T) ~ "ln 2" ~ tau * "]")
    )
  }

  return(p)
}
