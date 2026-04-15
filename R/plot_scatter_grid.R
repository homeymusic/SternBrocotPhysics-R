#' Render the Microstate and Erasure Displacement Scatter Grid
#'
#' @param dt_meta data.table containing normalized_momentum and action_A.
#' @param dir_raw Directory containing raw erasures.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family.
#' @param overarching_title Optional title for the readme style.
#' @import ggplot2
#' @import patchwork
#' @import data.table
#' @export
plot_scatter_grid <- function(dt_meta, dir_raw,
                              style = c("manuscript", "readme"),
                              base_font = "", overarching_title = NULL) {

  style <- match.arg(style)
  is_ms <- style == "manuscript"
  plot_list <- list()
  num_rows <- nrow(dt_meta)

  # Setup Axes Labels (Rotated and Renamed to match Density Plots)
  if (is_ms) {
    ax_y_pos <- expression("Blob Center, " * italic(q)[b]/italic(q)[0])
    ax_x_mic <- expression("Selected Microstate, " * italic(q)[mu]^"*" / italic(q)[0])
    ax_x_eps <- expression("Position, " * italic(q)/italic(q)[0])
  } else {
    ax_y_pos <- "Blob Center, q_b/q_0"
    ax_x_mic <- "Selected Microstate, q*/q_0"
    ax_x_eps <- "Position, q/q_0"
  }

  for (i in seq_len(num_rows)) {
    current_row <- dt_meta[i]
    p_val   <- current_row$normalized_momentum
    a_ratio <- current_row$action_A
    p_str   <- sprintf("%013.6f", p_val)

    # Physics Alignment
    max_ax <- p_val / 1.0
    plot_lim_x <- max_ax * 1.05

    file_raw <- file.path(dir_raw, sprintf("harmonic_oscillator_erasures_stern_brocot_P_%s.csv.gz", p_str))

    # --- Column 1: Row Label ---
    p_label <- ggplot() + theme_void() + coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off")
    if (is_ms) {
      row_label_str <- sprintf('"%.1f" * A[0]', a_ratio)
      p_label <- p_label + annotate("text", x=1, y=0.5, label=row_label_str, parse=TRUE, family=base_font, size=4, hjust=1)
    } else {
      row_label_str <- sprintf("A = %.1f", a_ratio)
      p_label <- p_label + annotate("text", x=1, y=0.5, label=row_label_str, family=base_font, size=4, hjust=1, fontface="bold")
    }

    p_scat1 <- ggplot() + theme_void() + theme(aspect.ratio=1)
    p_scat2 <- ggplot() + theme_void() + theme(aspect.ratio=1)

    if (file.exists(file_raw)) {
      dt_raw <- fread(file_raw, colClasses=c(encoded_sequence="character"))[found == 1]

      # ROTATED MAPPING: Y is the lab sweep (q_b), X is the physical outputs (q_mu* and q)
      dt_raw[, `:=`(
        y_pos = blob_center * max_ax,
        x_mic = selected_microstate * max_ax,
        x_eps = erasure_displacement * (max_ax^3) * (pi / 2)
      )]

      custom_breaks <- c(-max_ax, 0, max_ax)
      label_format <- function(x) sprintf("%.1f", x)

      # --- Column 2: Selected Microstate (X) vs Blob Center (Y) ---
      p_scat1 <- ggplot(dt_raw, aes(x=x_mic, y=y_pos)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        scale_x_continuous(breaks = custom_breaks, labels = label_format) +
        scale_y_continuous(breaks = custom_breaks, labels = label_format) +
        theme_bw(base_family = base_font) +
        theme(panel.grid.minor=element_blank(), axis.text = element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_mic, y = ax_y_pos)

      # --- Column 3: Position (X) vs Blob Center (Y) ---
      p_scat2 <- ggplot(dt_raw, aes(x=x_eps, y=y_pos)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        scale_x_continuous(breaks = custom_breaks, labels = label_format) +
        scale_y_continuous(breaks = custom_breaks, labels = label_format) +
        theme_bw(base_family = base_font) +
        theme(panel.grid.minor=element_blank(), axis.text = element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_eps, y = ax_y_pos)
    }

    # --- Row Header Cleanup ---
    if (i == 1) {
      p_label <- p_label + labs(title = " ") +
        theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))

      p_scat1 <- p_scat1 + labs(title = "Blob Center vs. Selected Microstate") +
        theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))

      # Renamed Title to match axes
      p_scat2 <- p_scat2 + labs(title = "Blob Center vs. Position") +
        theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
    }

    if (i != num_rows) {
      p_scat1 <- p_scat1 + theme(axis.title.x = element_blank())
      p_scat2 <- p_scat2 + theme(axis.title.x = element_blank())
    }

    plot_list <- c(plot_list, list(p_label, p_scat1, p_scat2))
  }

  final_plot <- wrap_plots(plot_list, ncol = 3, widths = c(0.25, 1, 1))

  if (!is_ms && !is.null(overarching_title)) {
    final_plot <- final_plot + plot_annotation(
      title = overarching_title,
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5, family = base_font))
    )
  }

  return(final_plot)
}
