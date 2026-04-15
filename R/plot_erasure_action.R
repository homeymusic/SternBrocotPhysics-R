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

  dt_plot <- dt_summary[action_A <= max_action * 1.05]

  p <- ggplot(dt_plot, aes(x = action_A)) +
    # Variance Ribbons
    geom_ribbon(aes(ymin = min_len, ymax = max_len, fill = "Total Range"), alpha = 0.4) +
    geom_ribbon(aes(ymin = lower, ymax = upper, fill = "±1 SD"), alpha = 0.5) +
    scale_fill_manual(name = NULL,
                      breaks = c("Total Range", "±1 SD"),
                      values = c("Total Range" = "grey75", "±1 SD" = "grey55")) +

    # Limits and Tendencies (Now mapping BOTH max and min to "Boundary")
    geom_line(aes(y = max_len, color = "Boundary", linetype = "Boundary"), linewidth = 0.4) +
    geom_line(aes(y = min_len, color = "Boundary", linetype = "Boundary"), linewidth = 0.4) +
    geom_line(aes(y = mean_len, color = "Mean", linetype = "Mean"), linewidth = 0.6) +
    geom_step(aes(y = median_len, color = "Median", linetype = "Median"), linewidth = 0.6) +

    # Unified scale mappings with explicit breaks
    scale_color_manual(name = NULL,
                       breaks = c("Boundary", "Mean", "Median"),
                       values = c("Boundary" = "gray40", "Mean" = "gray30", "Median" = "black")) +
    scale_linetype_manual(name = NULL,
                          breaks = c("Boundary", "Mean", "Median"),
                          values = c("Boundary" = "solid", "Mean" = "dashed", "Median" = "solid")) +

    scale_x_continuous(breaks = seq(0, max_action, by = 10), expand = c(0, 0)) +
    coord_cartesian(xlim = c(0, max_action)) +
    theme_minimal(base_family = base_font) +
    theme(
      legend.position = "bottom",
      legend.key.width = unit(2, "lines"),
      panel.grid.minor = element_blank(),
      plot.margin = margin(t = 5, r = 15, b = 5, l = 5)
    )

  if (!is_ms) {
    p <- p + labs(
      title = "Landauer Action vs. Classical Action",
      x = expression("Classical Action, " * A/A[0]),
      y = expression("Landauer Action, " * A[L] ~ "[" * k[B] * T ~ "ln 2" ~ tau * "]")
    ) +
      theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))
  } else {
    p <- p + labs(
      x = expression("Classical Action, " * italic(A)/italic(A)[0]),
      y = expression("Landauer Action, " * italic(A)[L] ~ "[" * italic(k)[B] * italic(T) ~ "ln 2" ~ tau * "]")
    )
  }

  return(p)
}
