#' Render the Simple Harmonic Oscillator Erasure Grid (2-Column)
#'
#' @param dt_meta data.table containing normalized_momentum, action_A, and optionally node_count.
#' @param dir_raw Directory containing raw erasures.
#' @param dir_densities Directory containing erasure densities.
#' @param dir_nodes Directory containing topological nodes.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family (e.g., "CMU Serif").
#' @param overarching_title Optional title for the readme style.
#' @param show_nodes Logical, whether to plot the discrete node dots on the density map. Defaults to TRUE.
#' @import ggplot2
#' @import ggforce
#' @import patchwork
#' @import data.table
#' @export
plot_simple_erasure_grid <- function(dt_meta, dir_raw, dir_densities, dir_nodes,
                                     style = c("manuscript", "readme"),
                                     base_font = "", overarching_title = NULL,
                                     show_nodes = TRUE) {
  style <- match.arg(style)
  plot_list <- list()
  num_rows <- nrow(dt_meta)

  # Setup aesthetics based on style
  is_ms <- style == "manuscript"

  # Column 1
  ax_x_ell <- if(is_ms) expression("Position, " * italic(q)/italic(q)[0]) else "Position, q/q_0"
  ax_y_ell <- if(is_ms) expression("Momentum, " * italic(p)/italic(p)[0]) else "Momentum, p/p_0"

  # Column 2 (Density)
  ax_x_den <- if(is_ms) expression("Position, " * italic(q)/italic(q)[0]) else "Position, q/q_0"
  ax_y_den <- "Density (%)"

  for (i in seq_len(num_rows)) {
    current_row <- dt_meta[i]
    p_val   <- current_row$normalized_momentum
    a_ratio <- current_row$action_A
    p_str   <- sprintf("%013.6f", p_val)

    # Physics Alignment (Ground State P=1.0)
    max_ax <- p_val / 1.0
    min_ax <- 1.0 / p_val

    # Load Data (Only need density and nodes now)
    file_density <- file.path(dir_densities, sprintf("harmonic_oscillator_erasure_displacement_density_stern_brocot_P_%s.csv.gz", p_str))
    file_nodes   <- file.path(dir_nodes, sprintf("harmonic_oscillator_erasure_displacement_nodes_stern_brocot_P_%s.csv.gz", p_str))

    # --- Density Data & Limits ---
    lim_x <- max_ax
    total_count <- 1.0
    dt_hist <- data.table()
    if (file.exists(file_density)) {
      dt_hist <- fread(file_density)
      total_count <- sum(dt_hist$density_count, na.rm=TRUE)
      dt_hist[, pct := if(total_count > 0) (density_count / total_count) * 100 else 0]

      # Scale the relative coordinates by the classical boundary and undo the 2/pi projection
      dt_hist[, coordinate_q := coordinate_q * max_ax * (pi / 2)]

      width <- median(diff(dt_hist$coordinate_q), na.rm=TRUE)
      active_q <- dt_hist[density_count > 0, coordinate_q]
      if (length(active_q) > 0) {
        max_q <- max(abs(active_q), na.rm=TRUE) + (width/2)
        lim_x <- max(max_ax, max_q)
      }
    }
    plot_lim_x <- lim_x * 1.05

    # --- Setup Custom Physical Axes Boundaries ---
    custom_breaks <- c(-max_ax, 0, max_ax)
    label_format <- function(x) sprintf("%.1f", x)

    # --- Column 0: Row Label ---
    p_label <- ggplot() + theme_void() + coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off")
    if (is_ms) {
      row_label_str <- sprintf('"%.1f" * A[0]', a_ratio)
      p_label <- p_label + annotate("text", x=1, y=0.5, label=row_label_str, parse=TRUE, family=base_font, size=4, hjust=1)
    } else {
      n_val <- if("node_count" %in% names(current_row)) current_row$node_count else NA
      row_label_str <- sprintf("A = %.1f\nn = %s", a_ratio, ifelse(is.na(n_val), "?", n_val))
      p_label <- p_label + annotate("text", x=1, y=0.5, label=row_label_str, family=base_font, size=4, hjust=1, fontface="bold")
    }

    # --- Column 1: Ellipses ---
    df_ell <- data.frame(max_ax = max_ax, min_ax = min_ax, x0 = 0, y0 = 0, angle = 0)
    p_ell <- ggplot(df_ell) +
      geom_ellipse(aes(x0=x0, y0=y0, a=max_ax, b=max_ax, angle=angle), fill=NA, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=max_ax, b=min_ax, angle=angle), fill="#A9A9A9", alpha=0.25, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=min_ax, b=max_ax, angle=angle), fill="#A9A9A9", alpha=0.25, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=min_ax, b=min_ax, angle=angle), fill="#FFFFFF", alpha=1.0, color="#5E5E5E", linewidth=0.3) +
      coord_fixed(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
      scale_x_continuous(breaks = custom_breaks, labels = label_format) +
      scale_y_continuous(breaks = custom_breaks, labels = label_format) +
      theme_bw(base_family = base_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8)) +
      labs(x = ax_x_ell, y = ax_y_ell)

    # --- Column 2: Density Skyline ---
    p_den <- ggplot() + theme_void() + theme(aspect.ratio=1)
    if (nrow(dt_hist) > 0) {
      step_x <- c(dt_hist$coordinate_q[1] - width/2,
                  rep(dt_hist$coordinate_q, each=2) + rep(c(-width/2, width/2), nrow(dt_hist)),
                  dt_hist$coordinate_q[nrow(dt_hist)] + width/2)
      step_y <- c(0, rep(dt_hist$pct, each=2), 0)

      den_max_y <- max(step_y, na.rm=TRUE)
      den_lim_y <- if(is.na(den_max_y) || den_max_y == 0) 1.0 else den_max_y * 1.15

      p_den <- ggplot(data.frame(x=step_x, y=step_y), aes(x=x, y=y)) +
        geom_polygon(fill="gray85", color=NA) +
        geom_path(color="black", linewidth=0.4) +
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, den_lim_y), expand=FALSE) +
        scale_x_continuous(breaks = custom_breaks, labels = label_format) +
        theme_bw(base_family=base_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = ax_x_den, y = ax_y_den)

      # LOGIC: Only add dots if show_nodes is TRUE
      if(show_nodes && file.exists(file_nodes)){
        dt_n <- fread(file_nodes)
        if (nrow(dt_n) > 0) {
          dt_n[, pct := (density_count / total_count) * 100]

          # Apply the same pi/2 multiplier to the nodes
          dt_n[, coordinate_q := coordinate_q * max_ax * (pi / 2)]

          p_den <- p_den + geom_point(data=dt_n, aes(x=coordinate_q, y=pct), size=0.8, color="black")
        }
      }
    }

    # --- Row Header Cleanup ---
    if (i == 1) {
      p_label <- p_label + labs(title = " ") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))
      p_ell   <- p_ell   + labs(title = "Quantum of Action") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
      p_den   <- p_den   + labs(title = "Landauer Erasure Density") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
    }

    if (i != num_rows) {
      p_ell  <- p_ell  + theme(axis.title.x = element_blank())
      p_den  <- p_den  + theme(axis.title.x = element_blank())
    }

    plot_list <- c(plot_list, list(p_label, p_ell, p_den))
  }

  # Adjusted layout: 3 columns total (label, plot1, plot2)
  final_plot <- wrap_plots(plot_list, ncol = 3, widths = c(0.25, 1, 1))

  # Add overarching title for README style
  if (!is_ms && !is.null(overarching_title)) {
    final_plot <- final_plot + plot_annotation(
      title = overarching_title,
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5, family = base_font))
    )
  }

  return(final_plot)
}
