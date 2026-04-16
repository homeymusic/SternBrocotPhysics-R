#' Render the Complete Causal Chain Erasure Grid
#'
#' @param dt_meta data.table containing normalized_momentum and action_A.
#' @param dir_raw Directory containing raw erasures.
#' @param dir_densities Directory containing erasure densities.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family.
#' @import ggplot2
#' @import ggforce
#' @import patchwork
#' @import data.table
#' @export
plot_causal_chain <- function(dt_meta, dir_raw, dir_densities,
                              style = c("manuscript", "readme"),
                              base_font = "") {

  style <- match.arg(style)
  is_ms <- style == "manuscript"
  plot_list <- list()
  num_rows <- nrow(dt_meta)

  # Setup Axes Labels
  if (is_ms) {
    ax_x_ell <- expression("Position, " * italic(q)/italic(q)[0])
    ax_y_ell <- expression("Momentum, " * italic(p)/italic(p)[0])

    ax_y_raw_eps <- expression("Raw Disp., " * italic("\u03F5"))
    ax_y_pos <- expression("Blob Center, " * italic(q)[b]/italic(q)[0])
    ax_x_mic <- expression("Microstate, " * italic(q)[mu]^"*" / italic(q)[0])
    ax_x_eps <- expression("Position, " * italic(q)/italic(q)[0])

    ax_y_den <- "Density (%)"
  } else {
    ax_x_ell <- "Position, q/q_0"; ax_y_ell <- "Momentum, p/p_0"
    ax_y_raw_eps <- "Raw Disp., \u03F5"
    ax_y_pos <- "Blob Center, q_b/q_0"
    ax_x_mic <- "Microstate, q*/q_0"; ax_x_eps <- "Position, q/q_0"
    ax_y_den <- "Density (%)"
  }

  for (i in seq_len(num_rows)) {
    current_row <- dt_meta[i]
    p_val   <- current_row$normalized_momentum
    a_ratio <- current_row$action_A
    p_str   <- sprintf("%013.6f", p_val)

    max_ax <- p_val / 1.0
    min_ax <- 1.0 / p_val
    plot_lim_x <- max_ax * 1.05

    file_raw     <- file.path(dir_raw, sprintf("harmonic_oscillator_erasures_stern_brocot_P_%s.csv.gz", p_str))
    file_density <- file.path(dir_densities, sprintf("harmonic_oscillator_erasure_displacement_density_stern_brocot_P_%s.csv.gz", p_str))

    custom_breaks <- c(-max_ax, 0, max_ax)
    label_format <- function(x) sprintf("%.1f", x)

    # --- Col 0: Row Label ---
    p_label <- ggplot() + theme_void() + coord_cartesian(xlim = c(0, 1), ylim = c(0, 1))
    row_label_str <- if(is_ms) sprintf('"%.1f" * A[0]', a_ratio) else sprintf("A = %.1f", a_ratio)
    p_label <- p_label + annotate("text", x=0.95, y=0.5, label=row_label_str, parse=is_ms, family=base_font, size=4, hjust=1, fontface=ifelse(is_ms, "plain", "bold"))

    # --- Col 1: Ellipses ---
    df_ell <- data.frame(max_ax = max_ax, min_ax = min_ax, x0 = 0, y0 = 0, angle = 0)
    p_ell <- ggplot(df_ell) +
      geom_ellipse(aes(x0=x0, y0=y0, a=max_ax, b=max_ax, angle=angle), fill=NA, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=max_ax, b=min_ax, angle=angle), fill="#A9A9A9", alpha=0.25, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=min_ax, b=max_ax, angle=angle), fill="#A9A9A9", alpha=0.25, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=min_ax, b=min_ax, angle=angle), fill="#FFFFFF", alpha=1.0, color="#5E5E5E", linewidth=0.3) +
      coord_fixed(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
      scale_x_continuous(breaks=custom_breaks, labels=label_format) +
      scale_y_continuous(breaks=custom_breaks, labels=label_format) +
      theme_bw(base_family=base_font) + theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8)) +
      labs(x = ax_x_ell, y = ax_y_ell)

    p_raw_eps1 <- ggplot() + theme_void() + theme(aspect.ratio=1)
    p_raw_eps2 <- ggplot() + theme_void() + theme(aspect.ratio=1) # NEW PLOT
    p_scat1    <- ggplot() + theme_void() + theme(aspect.ratio=1)
    p_den1     <- ggplot() + theme_void() + theme(aspect.ratio=1)
    p_cross    <- ggplot() + theme_void() + theme(aspect.ratio=1)
    p_scat2    <- ggplot() + theme_void() + theme(aspect.ratio=1)
    p_den2     <- ggplot() + theme_void() + theme(aspect.ratio=1)

    if (file.exists(file_raw)) {
      dt_raw <- fread(file_raw, colClasses=c(encoded_sequence="character"))[found == 1]
      dt_raw[, `:=`(
        y_pos = blob_center * max_ax,
        x_mic = selected_microstate * max_ax,
        x_eps = erasure_displacement * (max_ax^3) * (pi / 2)
      )]

      max_eps_raw <- max(abs(dt_raw$erasure_displacement), na.rm = TRUE)

      # --- Col 2: Unscaled Erasure Displacement vs Selected Microstate ---
      p_raw_eps1 <- ggplot(dt_raw, aes(x=x_mic, y=erasure_displacement)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-max_eps_raw*1.05, max_eps_raw*1.05), expand=FALSE) +
        scale_x_continuous(breaks=custom_breaks, labels=label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_mic, y = ax_y_raw_eps)

      # --- Col 3: NEW - Unscaled Erasure Displacement vs Blob Center ---
      p_raw_eps2 <- ggplot(dt_raw, aes(x=y_pos, y=erasure_displacement)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-max_eps_raw*1.05, max_eps_raw*1.05), expand=FALSE) +
        scale_x_continuous(breaks=custom_breaks, labels=label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_y_pos, y = ax_y_raw_eps)

      # --- Col 4: Microstate Scatter ---
      p_scat1 <- ggplot(dt_raw, aes(x=x_mic, y=y_pos)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        scale_x_continuous(breaks=custom_breaks, labels=label_format) +
        scale_y_continuous(breaks=custom_breaks, labels=label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_mic, y = ax_y_pos)

      # --- Col 5: Microstate Density ---
      dt_mic_hist <- dt_raw[, .(count = .N), by = x_mic]
      dt_mic_hist[, pct := (count / sum(count)) * 100]

      p_den1 <- ggplot(dt_mic_hist) +
        geom_segment(aes(x=x_mic, xend=x_mic, y=0, yend=pct), color="black", linewidth=ifelse(a_ratio > 10, 0.1, 0.5)) +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, max(dt_mic_hist$pct)*1.15), expand=FALSE) +
        scale_x_continuous(breaks=custom_breaks, labels=label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_mic, y = ax_y_den)

      # --- Col 6: Position vs. Microstate Cross-Correlation ---
      p_cross <- ggplot(dt_raw, aes(x=x_eps, y=x_mic)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        scale_x_continuous(breaks=custom_breaks, labels=label_format) +
        scale_y_continuous(breaks=custom_breaks, labels=label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_eps, y = ax_x_mic)

      # --- Col 7: Position Scatter ---
      p_scat2 <- ggplot(dt_raw, aes(x=x_eps, y=y_pos)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        scale_x_continuous(breaks=custom_breaks, labels=label_format) +
        scale_y_continuous(breaks=custom_breaks, labels=label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_eps, y = ax_y_pos)
    }

    # --- Col 8: Position Density ---
    if (file.exists(file_density)) {
      dt_hist <- fread(file_density)
      total_count <- sum(dt_hist$density_count, na.rm=TRUE)
      dt_hist[, pct := (density_count / total_count) * 100]
      dt_hist[, coordinate_q := coordinate_q * max_ax * (pi / 2)]
      width <- median(diff(dt_hist$coordinate_q), na.rm=TRUE)

      if (nrow(dt_hist) > 0) {
        step_x <- c(dt_hist$coordinate_q[1] - width/2, rep(dt_hist$coordinate_q, each=2) + rep(c(-width/2, width/2), nrow(dt_hist)), dt_hist$coordinate_q[nrow(dt_hist)] + width/2)
        step_y <- c(0, rep(dt_hist$pct, each=2), 0)
        p_den2 <- ggplot(data.frame(x=step_x, y=step_y), aes(x=x, y=y)) +
          geom_polygon(fill="gray85", color=NA) + geom_path(color="black", linewidth=0.4) +
          coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, max(step_y)*1.15), expand=FALSE) +
          scale_x_continuous(breaks=custom_breaks, labels=label_format) +
          theme_bw(base_family=base_font) +
          theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
          labs(x = ax_x_eps, y = ax_y_den)
      }
    }

    # --- Formatting & Cleanup ---
    if (i == 1) {
      font_face  <- ifelse(is_ms, "plain", "bold")
      p_label    <- p_label + labs(title=" ")
      p_ell      <- p_ell      + labs(title="Quantum of Action") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_raw_eps1 <- p_raw_eps1 + labs(title="Disp. vs Selection") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_raw_eps2 <- p_raw_eps2 + labs(title="Disp. vs Center") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_scat1    <- p_scat1    + labs(title="Absolute Selection") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_den1     <- p_den1     + labs(title="Selection Density") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_cross    <- p_cross    + labs(title="Microstate vs. Position") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_scat2    <- p_scat2    + labs(title="Relative Position") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
      p_den2     <- p_den2     + labs(title="Position Density") + theme(plot.title=element_text(size=9, hjust=0.5, face=font_face))
    }

    if (i != num_rows) {
      p_ell      <- p_ell + theme(axis.title.x=element_blank())
      p_raw_eps1 <- p_raw_eps1 + theme(axis.title.x=element_blank())
      p_raw_eps2 <- p_raw_eps2 + theme(axis.title.x=element_blank())
      p_scat1    <- p_scat1 + theme(axis.title.x=element_blank())
      p_den1     <- p_den1 + theme(axis.title.x=element_blank())
      p_cross    <- p_cross + theme(axis.title.x=element_blank())
      p_scat2    <- p_scat2 + theme(axis.title.x=element_blank())
      p_den2     <- p_den2 + theme(axis.title.x=element_blank())
    }

    # We preserve all Y-axes text & titles to keep the physics readable
    plot_list <- c(plot_list, list(p_label, p_ell, p_raw_eps1, p_raw_eps2, p_scat1, p_den1, p_cross, p_scat2, p_den2))
  }

  # Adjusted for 9 total columns (1 label + 8 plots)
  final_plot <- wrap_plots(plot_list, ncol = 9, widths = c(0.18, 1, 1, 1, 1, 1, 1, 1, 1)) &
    theme(plot.margin = margin(t = 2, r = 2, b = 2, l = 2))

  return(final_plot)
}
