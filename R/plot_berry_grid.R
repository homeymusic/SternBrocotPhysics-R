#' Render the Wigner-Husimi Kinematic Grid (Pure Berry Chord Geometry)
#'
#' @param dt_meta data.table containing quantum_n and action_A.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family (e.g., "CMU Serif").
#' @param overarching_title Optional title for the readme style.
#' @import ggplot2
#' @import ggforce
#' @import patchwork
#' @import data.table
#' @import stats
#' @export
plot_berry_grid <- function(dt_meta, style = c("manuscript", "readme"),
                            base_font = "", overarching_title = NULL) {
  style <- match.arg(style)
  plot_list <- list()
  num_rows <- nrow(dt_meta)
  is_ms <- style == "manuscript"

  # Axis Labels
  ax_x_ell <- if(is_ms) expression("Position, " * italic(q)/italic(q)[0]) else "Position, q/q_0"
  ax_y_ell <- if(is_ms) expression("Momentum, " * italic(p)/italic(p)[0]) else "Momentum, p/p_0"
  ax_x_stair <- if(is_ms) expression("Position, " * italic(q)/italic(q)[0]) else "Position, q/q_0"
  ax_y_stair <- "Cumulative Probability"
  ax_x_den <- if(is_ms) expression("Position, " * italic(q)/italic(q)[0]) else "Position, q/q_0"
  ax_y_den <- "Probability Density P(q)"

  # --- 1. PURE GEOMETRIC FUNCTIONS (No Schrödinger Wave Equations) ---

  # Calculate the geometric area of the circular segment cut by the chord
  chord_area <- function(r, R) {
    return(R^2 * acos(r/R) - r * sqrt(R^2 - r^2))
  }

  # Berry's Geometric 2D Wigner Landscape
  berry_wigner <- function(n, q, p) {
    R <- sqrt(2*n + 1)
    r <- sqrt(q^2 + p^2)
    val <- numeric(length(r))

    idx_in <- r < R
    if (any(idx_in)) {
      r_in <- r[idx_in]
      Area <- chord_area(r_in, R)
      # Soft cap on the caustic denominator to prevent infinity at the boundary
      denom <- pmax((R^2 - r_in^2)^0.25, 0.1)
      val[idx_in] <- (1 / (pi * denom)) * cos(Area - pi/4)
    }

    # Evanescent geometric tail
    idx_out <- r >= R
    if (any(idx_out)) {
      r_out <- r[idx_out]
      Area_out <- r_out * sqrt(r_out^2 - R^2) - R^2 * acosh(r_out/R)
      denom <- pmax((r_out^2 - R^2)^0.25, 0.1)
      val[idx_out] <- (1 / (2 * pi * denom)) * exp(-Area_out)
    }
    return(val)
  }

  # Semiclassical WKB Spatial Density (1D projection of the chord geometry)
  berry_wkb_density <- function(n, q) {
    R <- sqrt(2*n + 1)
    val <- numeric(length(q))

    idx_in <- abs(q) < R
    if (any(idx_in)) {
      q_in <- q[idx_in]
      # The 1D spatial phase is exactly half the 2D geometric chord area!
      Area <- chord_area(abs(q_in), R)

      # Soft cap on the classical probability caustic
      class_prob <- 1 / (pi * pmax(sqrt(R^2 - q_in^2), 0.05))
      val[idx_in] <- 2 * class_prob * cos((0.5 * Area) - pi/4)^2
    }

    idx_out <- abs(q) >= R
    if (any(idx_out)) {
      q_out <- q[idx_out]
      Area_out <- abs(q_out) * sqrt(q_out^2 - R^2) - R^2 * acosh(abs(q_out)/R)
      class_prob <- 1 / (2 * pi * pmax(sqrt(q_out^2 - R^2), 0.05))
      val[idx_out] <- class_prob * exp(-2 * Area_out)
    }
    return(val)
  }

  # --- 2. MAIN RENDERING LOOP ---
  for (i in seq_len(num_rows)) {
    current_row <- dt_meta[i]
    n_val   <- current_row$quantum_n
    a_ratio <- current_row$action_A

    Delta_q <- sqrt(a_ratio)
    Delta_p <- sqrt(a_ratio)
    delta_q <- 1 / Delta_p
    delta_p <- 1 / Delta_q

    plot_lim_x <- Delta_q * 1.15
    custom_breaks <- c(-round(Delta_q, 1), 0, round(Delta_q, 1))
    label_format <- function(x) sprintf("%.1f", x)

    # Row Label
    p_label <- ggplot() + theme_void() + coord_cartesian(xlim = c(-3, 1), ylim = c(0, 1), clip = "off")
    row_label_str <- sprintf('italic(A) == "%.1f" * A[0]', a_ratio)
    p_label <- p_label + annotate("text", x=0.9, y=0.5, label=row_label_str, parse=TRUE, family=base_font, size=4, hjust=1)

    # Generate Grid Data (Lower res for geometry processing speed, but enough for clean convolutions)
    grid_res <- 400
    q_seq <- seq(-plot_lim_x, plot_lim_x, length.out = grid_res)
    p_seq <- seq(-plot_lim_x, plot_lim_x, length.out = grid_res)

    dt_wigner2d <- as.data.table(expand.grid(q = q_seq, p = p_seq))
    dt_wigner2d[, w := berry_wigner(n_val, q, p)]

    # --- 3. THE KINEMATIC SCAN (Convolution) ---
    raw_geometric_density <- berry_wkb_density(n_val, q_seq)

    # The Scanner (a_q)
    scanner_profile <- dnorm(q_seq, mean = 0, sd = delta_q / sqrt(2))

    # Execute Scan (Convolution naturally cures the geometric caustics)
    step_size <- diff(q_seq)[1]
    true_husimi_density <- convolve(raw_geometric_density, rev(scanner_profile), type = "open") * step_size

    peak_idx <- which.max(scanner_profile)
    aligned_density <- true_husimi_density[peak_idx:(peak_idx + length(q_seq) - 1)]

    dt_density <- data.table(q = q_seq)
    dt_density[, density := aligned_density]
    # Normalize to 1.0 to ensure perfect CDF mapping
    dt_density[, density := density / (sum(density) * step_size)]
    dt_density[, cdf := cumsum(density) * step_size]

    # Geometric Outlines
    df_circles <- data.frame(x0 = 0, y0 = 0, r_A = Delta_q, r_a = delta_q)
    df_cigars <- data.frame(x0 = 0, y0 = 0, aq_a = delta_q, aq_b = Delta_p, ap_a = Delta_q, ap_b = delta_p)

    # Column 1: Geometric Action Landscape & Apparatus
    p_ell <- ggplot(dt_wigner2d, aes(x=q, y=p)) +
      geom_raster(aes(fill = w), interpolate = TRUE) +
      scale_fill_gradient2(low = "white", mid = "gray50", high = "black", midpoint = 0, guide="none") +
      geom_circle(data = df_circles, aes(x0=x0, y0=y0, r=r_A), inherit.aes=FALSE, color="black", linetype="solid", linewidth=0.3) +
      geom_ellipse(data = df_cigars, aes(x0=x0, y0=y0, a=aq_a, b=aq_b, angle=0), inherit.aes=FALSE, color="black", linetype="dotted", linewidth=0.5) +
      geom_ellipse(data = df_cigars, aes(x0=x0, y0=y0, a=ap_a, b=ap_b, angle=0), inherit.aes=FALSE, color="black", linetype="dotted", linewidth=0.5) +
      geom_circle(data = df_circles, aes(x0=x0, y0=y0, r=r_a), inherit.aes=FALSE, color="black", linetype="dashed", linewidth=0.3) +
      coord_fixed(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
      scale_x_continuous(breaks = custom_breaks, labels = label_format) +
      scale_y_continuous(breaks = custom_breaks, labels = label_format) +
      theme_bw(base_family = base_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), plot.margin = margin(2, 4, 2, 4)) +
      labs(x = ax_x_ell, y = ax_y_ell)

    # Column 2: Analytical Staircase
    p_stair <- ggplot(dt_density, aes(x=q, y=cdf)) +
      geom_line(color="black", linewidth=0.8) +
      coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, 1), expand=FALSE) +
      scale_x_continuous(breaks = custom_breaks, labels = label_format) +
      theme_bw(base_family=base_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1, plot.margin = margin(2, 4, 2, 4)) +
      labs(x = ax_x_stair, y = ax_y_stair)

    # Column 3: Squeezed Husimi Observable (True Blurred Density)
    y_lim_den <- max(dt_density$density) * 1.15
    p_den <- ggplot(dt_density, aes(x=q, y=density)) +
      geom_ribbon(aes(ymin=0, ymax=density), fill="gray85", color=NA) +
      geom_path(color="black", linewidth=0.4) +
      coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, y_lim_den), expand=FALSE) +
      scale_x_continuous(breaks = custom_breaks, labels = label_format) +
      theme_bw(base_family=base_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), axis.text.y=element_blank(), axis.ticks.y=element_blank(), aspect.ratio=1, plot.margin = margin(2, 4, 2, 4)) +
      labs(x = ax_x_den, y = ax_y_den)

    # Headers
    if (i == 1) {
      p_label <- p_label + labs(title = " ") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))
      p_ell   <- p_ell   + labs(title = "Geometric Action Landscape") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
      p_stair <- p_stair + labs(title = "Analytical Staircase") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
      p_den   <- p_den   + labs(title = "Kinematic Density") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
    }
    if (i != num_rows) {
      p_ell   <- p_ell   + theme(axis.title.x = element_blank())
      p_stair <- p_stair + theme(axis.title.x = element_blank())
      p_den   <- p_den   + theme(axis.title.x = element_blank())
    }

    plot_list <- c(plot_list, list(p_label, p_ell, p_stair, p_den))
  }

  final_plot <- wrap_plots(plot_list, ncol = 4, widths = c(0.35, 1, 1, 1))
  return(final_plot)
}
