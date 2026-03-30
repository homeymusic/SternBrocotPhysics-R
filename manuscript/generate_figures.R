library(data.table)
library(ggplot2)
library(ggforce)
library(patchwork)

# --- 1. Configuration & Data Setup ---
dir_manuscript <- "./manuscript"
dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw_erasures <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities    <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes        <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
file_output_pdf     <- file.path(dir_manuscript, "fig_harmonic_oscillator_grid_final.pdf")

# Target data points from your selection [cite: 1-10]
target_momenta <- c(0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0)
node_counts    <- c(0, 2, 4, 7, 10, 19, 17, 27, 38, 32)

# --- 2. Plotting Function ---
render_combined_erasure_distance_grid <- function() {
  plot_list <- list()

  for (i in seq_along(target_momenta)) {
    momentum_val <- target_momenta[i]
    node_val     <- node_counts[i]
    momentum_str_padded <- sprintf("%013.6f", momentum_val)

    # ---------------------------------------------------------
    # 1. Conjugate Quanta (Left Column) - RESTORED ORIGINAL LOGIC
    # ---------------------------------------------------------
    a_base <- momentum_val / 0.5
    b_base <- 0.5 / momentum_val
    scaling_factor <- 90 / max(a_base, b_base)

    ellipse_df <- data.frame(
      type = factor(c("Q-Conjugate", "P-Conjugate"), levels = c("Q-Conjugate", "P-Conjugate")),
      major = c(a_base, b_base) * scaling_factor,
      minor = c(b_base, a_base) * scaling_factor
    )

    p_ell <- ggplot(ellipse_df) +
      geom_ellipse(aes(x0 = 0, y0 = 0, a = major, b = minor, angle = 0, color = type, fill = type),
                   alpha = 0.2, linewidth = 0.5) +
      scale_fill_manual(values = c("Q-Conjugate" = "black", "P-Conjugate" = "gray60")) +
      scale_color_manual(values = c("Q-Conjugate" = "black", "P-Conjugate" = "gray30")) +
      coord_fixed(xlim = c(-100, 100), ylim = c(-100, 100)) +
      labs(y = sprintf("P = %.3f\nn = %d", momentum_val, node_val)) +
      theme_minimal() +
      theme(legend.position = "none",
            axis.title.x = element_blank(),
            axis.title.y = element_text(angle = 0, vjust = 0.5, hjust = 1, face = "bold",
                                        size = 10, family = "mono", margin = margin(r = 10)),
            axis.text = element_blank(),
            panel.grid = element_line(color = "gray95"),
            aspect.ratio = 1)

    # ---------------------------------------------------------
    # 2. Action Map (Middle Column)
    # ---------------------------------------------------------
    file_raw <- file.path(dir_01_raw_erasures, sprintf("harmonic_oscillator_erasures_stern_brocot_P_%s.csv.gz", momentum_str_padded))
    p_scat <- ggplot() + theme_void() + theme(aspect.ratio = 1)

    if (file.exists(file_raw)) {
      dt_raw_found <- fread(file_raw)[found == 1]
      if (nrow(dt_raw_found) > 0) {
        p_scat <- ggplot(dt_raw_found, aes(x = microstate, y = minimal_action_state)) +
          geom_point(alpha = 0.2, size = 0.05, color = "black", stroke = 0) +
          theme_minimal() +
          theme(axis.title = element_blank(), axis.text = element_blank(),
                panel.grid = element_line(color = "gray95"), aspect.ratio = 1)
      }
    }

    # ---------------------------------------------------------
    # 3. Coordinate Density (Right Column) - GEOMETRIC POLYGON FILL
    # ---------------------------------------------------------
    file_density <- file.path(dir_02_densities, sprintf("harmonic_oscillator_erasure_distance_density_stern_brocot_P_%s.csv.gz", momentum_str_padded))
    p_den <- ggplot() + theme_void() + theme(aspect.ratio = 1)

    if (file.exists(file_density)) {
      dt_hist <- fread(file_density)
      if (nrow(dt_hist) > 0) {
        max_h <- max(dt_hist$density_count, na.rm = TRUE)
        width <- median(diff(dt_hist$coordinate_q), na.rm = TRUE)
        max_q <- max(abs(dt_hist$coordinate_q), na.rm = TRUE) + (width / 2)

        dt_hist[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q)*100)]
        pct_bar_width <- (width / max_q) * 100

        # Build the exact geometric skyline coordinates
        skyline_x <- c(dt_hist$pct_q[1] - pct_bar_width/2,
                       rep(dt_hist$pct_q, each = 2) + rep(c(-pct_bar_width/2, pct_bar_width/2), nrow(dt_hist)),
                       dt_hist$pct_q[nrow(dt_hist)] + pct_bar_width/2)
        skyline_y <- c(0, rep(dt_hist$pct_density, each = 2), 0)
        dt_skyline <- data.table(x = skyline_x, y = skyline_y)

        p_den <- ggplot(dt_skyline, aes(x = x, y = y)) +
          # THE FIX: Single polygon fill prevents spires while respecting step geometry
          geom_polygon(fill = "gray85", color = NA) +
          geom_path(color = "black", linewidth = 0.4) +
          coord_cartesian(xlim = c(-100, 100), ylim = c(0, 105)) +
          theme_minimal() +
          theme(axis.title = element_blank(), axis.text = element_blank(),
                panel.grid = element_line(color = "gray95"), aspect.ratio = 1)

        # Re-overlay nodes
        file_nodes <- file.path(dir_03_nodes, sprintf("harmonic_oscillator_erasure_distance_nodes_stern_brocot_P_%s.csv.gz", momentum_str_padded))
        if(file.exists(file_nodes)){
          dt_n <- fread(file_nodes)
          dt_n[, `:=`(pct_y = (density_count/max_h)*100, pct_x = (coordinate_q/max_q)*100)]
          p_den <- p_den + geom_point(data=dt_n, aes(x=pct_x, y=pct_y), size=0.8, color="black")
        }
      }
    }

    # Headers and labels [cite: 11-13]
    if (i == 1) {
      p_ell  <- p_ell  + labs(title = "Phase Blobs")
      p_scat <- p_scat + labs(title = "Action Map")
      p_den  <- p_den  + labs(title = "Erasure Density")
    }

    plot_list[[length(plot_list) + 1]] <- p_ell
    plot_list[[length(plot_list) + 1]] <- p_scat
    plot_list[[length(plot_list) + 1]] <- p_den
  }

  wrap_plots(plot_list, ncol = 3) +
    plot_annotation(title = "Harmonic Oscillator Erasure Density",
                    theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5, family = "mono")))
}

# --- 3. Render ---
pdf(file = file_output_pdf, width = 8.5, height = 22)
print(render_combined_erasure_distance_grid())
dev.off()
