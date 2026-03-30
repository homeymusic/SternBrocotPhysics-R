library(data.table)
library(ggplot2)
library(ggforce)
library(patchwork)

# --- 1. Configuration ---
dir_manuscript <- "./manuscript"
dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw_erasures <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities    <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes        <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
file_output_pdf     <- file.path(dir_manuscript, "fig_harmonic_oscillator_PRL_submission.pdf")

# Data mapping from selection
target_tilde_p <- c(0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0)
node_counts    <- c(0, 2, 4, 7, 10, 19, 17, 27, 38, 32)

render_prl_submission_grid <- function() {
  plot_list <- list()
  num_rows <- length(target_tilde_p)

  for (i in seq_along(target_tilde_p)) {
    p_val <- target_tilde_p[i]
    n_val <- node_counts[i]
    p_str <- sprintf("%013.6f", p_val)
    action_coeff <- 4 * (p_val^2)

    # ---------------------------------------------------------
    # Column 1: Quantum of Action
    # ---------------------------------------------------------
    a_base <- p_val / 0.5
    b_base <- 0.5 / p_val
    scaling <- 90 / max(a_base, b_base)

    df_ell <- data.frame(type = factor(c("Q", "P"), levels = c("Q", "P")),
                         major = c(a_base, b_base) * scaling,
                         minor = c(b_base, a_base) * scaling)

    p_ell <- ggplot(df_ell) +
      geom_ellipse(aes(x0=0, y0=0, a=major, b=minor, angle=0, fill=type),
                   alpha=0.2, color="black", linewidth=0.3) +
      scale_fill_manual(values=c("Q"="black", "P"="gray60")) +
      coord_fixed(xlim=c(-100,100), ylim=c(-100,100)) +
      scale_x_continuous(breaks = c(-100, 0, 100)) +
      scale_y_continuous(breaks = c(-100, 0, 100)) +
      theme_bw(base_family = "serif") +
      theme(legend.position="none",
            panel.grid.minor=element_blank(),
            axis.text = element_text(size=8)) +
      labs(x = expression("Coordinate, " * italic(q)), y = expression("Momentum, " * italic(p)))

    # ---------------------------------------------------------
    # Column 2: Microstate vs Minimal-Action Mapping
    # ---------------------------------------------------------
    file_raw <- file.path(dir_01_raw_erasures, sprintf("harmonic_oscillator_erasures_stern_brocot_P_%s.csv.gz", p_str))
    p_scat <- ggplot() + theme_void() + theme(aspect.ratio=1)

    # Construct Row Subtitle: Action and Node Count
    row_subtitle <- bquote(bold(A == .(sprintf("%.1f", action_coeff))*A[0] ~~~~~ "node count" == .(n_val)))

    if (file.exists(file_raw)) {
      dt_raw <- fread(file_raw)[found == 1]
      p_scat <- ggplot(dt_raw, aes(x=microstate, y=minimal_action_state)) +
        geom_point(alpha=0.15, size=0.01, stroke=0, color="black") +
        scale_x_continuous(breaks = c(0, 50, 100)) +
        scale_y_continuous(breaks = c(0, 50, 100)) +
        # Move row context here to serve as a centered row subtitle
        labs(subtitle = row_subtitle) +
        theme_bw(base_family = "serif") +
        theme(panel.grid.minor=element_blank(),
              axis.text = element_text(size=8),
              plot.subtitle = element_text(size=10, hjust=0.5, face="bold"),
              # Ensure y-axis title fits
              axis.title.y = element_text(size=9)) +
        labs(x = expression("Coordinate Microstate, " * italic(q)[mu]),
             y = expression("Minimal-Action State, " * italic(q)^"*"))
    }

    # ---------------------------------------------------------
    # Column 3: Coordinate Density (Perfect Skyline)
    # ---------------------------------------------------------
    file_density <- file.path(dir_02_densities, sprintf("harmonic_oscillator_erasure_distance_density_stern_brocot_P_%s.csv.gz", p_str))
    p_den <- ggplot() + theme_void() + theme(aspect.ratio=1)
    if (file.exists(file_density)) {
      dt_hist <- fread(file_density)
      max_h <- max(dt_hist$density_count)
      width <- median(diff(dt_hist$coordinate_q))
      max_q <- max(abs(dt_hist$coordinate_q)) + (width/2)
      dt_hist[, `:=`(pct_h = (density_count/max_h)*100, pct_q = (coordinate_q/max_q)*100)]

      step_x <- c(dt_hist$pct_q[1] - (width/max_q)*50,
                  rep(dt_hist$pct_q, each=2) + rep(c(-(width/max_q)*50, (width/max_q)*50), nrow(dt_hist)),
                  dt_hist$pct_q[nrow(dt_hist)] + (width/max_q)*50)
      step_y <- c(0, rep(dt_hist$pct_h, each=2), 0)

      p_den <- ggplot(data.frame(x=step_x, y=step_y), aes(x=x, y=y)) +
        geom_polygon(fill="gray85", color=NA) +
        geom_path(color="black", linewidth=0.4) +
        scale_x_continuous(breaks = c(-100, 0, 100)) +
        scale_y_continuous(breaks = c(0, 50, 100)) +
        coord_cartesian(xlim=c(-100,100), ylim=c(0,110)) +
        theme_bw(base_family = "serif") +
        theme(panel.grid.minor=element_blank(), axis.text = element_text(size=8)) +
        labs(x = expression("Coordinate, " * italic(q) == (italic(A)/italic(h)) * epsilon[italic(q)]),
             y = "Density Count")

      file_nodes <- file.path(dir_03_nodes, sprintf("harmonic_oscillator_erasure_distance_nodes_stern_brocot_P_%s.csv.gz", p_str))
      if(file.exists(file_nodes)){
        dt_n <- fread(file_nodes)
        dt_n[, `:=`(pct_y = (density_count/max_h)*100, pct_x = (coordinate_q/max_q)*100)]
        p_den <- p_den + geom_point(data=dt_n, aes(x=pct_x, y=pct_y), size=0.8, color="black")
      }
    }

    # Titles (Top Row Only)
    if (i == 1) {
      p_ell  <- p_ell  + labs(title = "Quantum of Action")
      p_scat <- p_scat + labs(title = "Microstate vs. Minimal-Action State")
      p_den  <- p_den  + labs(title = "Coordinate Density")
    }

    # Hide axis titles for non-bottom rows to save vertical space
    if (i != num_rows) {
      p_ell <- p_ell + theme(axis.title.x = element_blank())
      p_scat <- p_scat + theme(axis.title.x = element_blank())
      p_den <- p_den + theme(axis.title.x = element_blank())
    }

    plot_list <- c(plot_list, list(p_ell, p_scat, p_den))
  }

  wrap_plots(plot_list, ncol = 3) +
    plot_annotation(theme = theme(plot.title = element_text(family="serif", size=14, face="bold", hjust=0.5)))
}

# --- 3. Render ---
pdf(file = file_output_pdf, width = 8.5, height = 24)
print(render_prl_submission_grid())
dev.off()
