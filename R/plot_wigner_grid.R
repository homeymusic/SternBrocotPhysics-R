#' Render the Wigner-Husimi Kinematic Grid (4-Column Layout)
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
plot_wigner_grid <- function(dt_meta, style = c("manuscript", "readme"),
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

  # --- Analytical Physics Helper Functions ---
  hermite_H <- function(n, x) {
    if (n == 0) return(rep(1, length(x)))
    if (n == 1) return(2 * x)
    H_prev2 <- rep(1, length(x))
    H_prev1 <- 2 * x
    for (i in 1:(n - 1)) {
      H_curr <- 2 * x * H_prev1 - 2 * i * H_prev2
      H_prev2 <- H_prev1
      H_prev1 <- H_curr
    }
    return(H_prev1)
  }

  laguerre_L <- function(n, x) {
    if (n == 0) return(rep(1, length(x)))
    if (n == 1) return(1 - x)
    L_prev2 <- rep(1, length(x))
    L_prev1 <- 1 - x
    for (i in 1:(n - 1)) {
      L_curr <- ((2 * i + 1 - x) * L_prev1 - i * L_prev2) / (i + 1)
      L_prev2 <- L_prev1
      L_prev1 <- L_curr
    }
    return(L_prev1)
  }

  # God's-Eye Exact Density (Used as the base for the kinematic scan)
  psi_sq <- function(n, x) {
    log_norm <- - (n * log(2) + lfactorial(n) + 0.5 * log(pi))
    norm_const <- exp(log_norm)
    H_val <- hermite_H(n, x)
    return(norm_const * exp(-x^2) * H_val^2)
  }

  wigner_W <- function(n, q, p) {
    r2 <- 2 * (q^2 + p^2)
    L_val <- laguerre_L(n, r2)
    return(((-1)^n / pi) * exp(-(q^2 + p^2)) * L_val)
  }

  # --- Main Rendering Loop ---
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

    # --- Column 0: Row Label ---
    p_label <- ggplot() + theme_void() + coord_cartesian(xlim = c(-3, 1), ylim = c(0, 1), clip = "off")
    if (is_ms) {
      row_label_str <- sprintf('italic(A) == "%.1f" * A[0]', a_ratio)
      p_label <- p_label + annotate("text", x=0.9, y=0.5, label=row_label_str, parse=TRUE, family=base_font, size=4, hjust=1)
    } else {
      row_label_str <- sprintf("A = %.1f\nn = %s", a_ratio, n_val)
      p_label <- p_label + annotate("text", x=0.9, y=0.5, label=row_label_str, family=base_font, size=4, hjust=1, fontface="bold")
    }

    # --- Generate Grid Data ---
    grid_res <- 400 # Bumped up resolution to handle high-n node fidelity
    q_seq <- seq(-plot_lim_x, plot_lim_x, length.out = grid_res)
    p_seq <- seq(-plot_lim_x, plot_lim_x, length.out = grid_res)

    dt_wigner2d <- as.data.table(expand.grid(q = q_seq, p = p_seq))
    dt_wigner2d[, w := wigner_W(n_val, q, p)]

    # --- High-Fidelity Kinematic Convolution ---
    # 1. Get the underlying continuous textbook density
    exact_density <- psi_sq(n_val, q_seq)

    # 2. Define the scanner's spatial profile (Width of the de Gosson cigar)
    # Squeezed state spatial variance dictates a standard deviation of delta_q / sqrt(2)
    scanner_profile <- dnorm(q_seq, mean = 0, sd = delta_q / sqrt(2))

    # 3. Perform the true 1D Convolution (The mathematical scan)
    step_size <- diff(q_seq)[1]
    # In R, convolve with rev() calculates the standard polynomial convolution
    true_husimi_density <- convolve(exact_density, rev(scanner_profile), type = "open") * step_size

    # 4. Perfectly align the output back to the spatial coordinates
    peak_idx <- which.max(scanner_profile)
    aligned_density <- true_husimi_density[peak_idx:(peak_idx + length(q_seq) - 1)]

    # Compile the final density and CDF
    dt_density <- data.table(q = q_seq)
    dt_density[, density := aligned_density]
    dt_density[, cdf := cumsum(density) / sum(density)]

    # Dataframes for Geometric Outlines
    df_circles <- data.frame(x0 = 0, y0 = 0, r_A = Delta_q, r_a = delta_q)
    df_cigars <- data.frame(
      x0 = 0, y0 = 0,
      aq_a = delta_q, aq_b = Delta_p,
      ap_a = Delta_q, ap_b = delta_p
    )

    # --- Column 1: Wigner Landscape & Apparatus ---
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

    # --- Column 2: Analytical Staircase (Cumulative Probability) ---
    p_stair <- ggplot(dt_density, aes(x=q, y=cdf)) +
      geom_line(color="black", linewidth=0.8) +
      coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, 1), expand=FALSE) +
      scale_x_continuous(breaks = custom_breaks, labels = label_format) +
      theme_bw(base_family=base_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1, plot.margin = margin(2, 4, 2, 4)) +
      labs(x = ax_x_stair, y = ax_y_stair)

    # --- Column 3: Squeezed Husimi Observable (True Blurred Density) ---
    y_lim_den <- max(dt_density$density) * 1.15
    p_den <- ggplot(dt_density, aes(x=q, y=density)) +
      geom_ribbon(aes(ymin=0, ymax=density), fill="gray85", color=NA) +
      geom_path(color="black", linewidth=0.4) +
      coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(0, y_lim_den), expand=FALSE) +
      scale_x_continuous(breaks = custom_breaks, labels = label_format) +
      theme_bw(base_family=base_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), axis.text.y=element_blank(), axis.ticks.y=element_blank(), aspect.ratio=1, plot.margin = margin(2, 4, 2, 4)) +
      labs(x = ax_x_den, y = ax_y_den)

    # --- Row Header Cleanup ---
    if (i == 1) {
      p_label <- p_label + labs(title = " ") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))
      p_ell   <- p_ell   + labs(title = "Wigner Action Landscape") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
      p_stair <- p_stair + labs(title = "Analytical Staircase") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
      p_den   <- p_den   + labs(title = "Husimi Density") + theme(plot.title=element_text(size=11, hjust=0.5, face=ifelse(is_ms, "plain", "bold")))
    }

    if (i != num_rows) {
      p_ell   <- p_ell   + theme(axis.title.x = element_blank())
      p_stair <- p_stair + theme(axis.title.x = element_blank())
      p_den   <- p_den   + theme(axis.title.x = element_blank())
    }

    plot_list <- c(plot_list, list(p_label, p_ell, p_stair, p_den))
  }

  # Adjusted ncol to 4 (Label, Wigner Geometry, Staircase, Density)
  final_plot <- wrap_plots(plot_list, ncol = 4, widths = c(0.35, 1, 1, 1))

  if (!is_ms && !is.null(overarching_title)) {
    final_plot <- final_plot + plot_annotation(
      title = overarching_title,
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5, family = base_font))
    )
  }

  return(final_plot)
}
