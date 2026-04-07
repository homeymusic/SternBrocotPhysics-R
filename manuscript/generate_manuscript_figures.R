library(data.table)
library(ggplot2)
library(ggforce)
library(patchwork)

# --- 1. FIXED FILENAME FOR MANUSCRIPT ---
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

# Stable slug for LaTeX and GitHub tracking
file_output_pdf <- file.path(dir_manuscript, "harmonic_oscillator.pdf")

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw_erasures <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities    <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes        <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
dir_04_summary      <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

file_summary <- file.path(dir_04_summary, "harmonic_oscillator_erasure_distance_summary.csv.gz")

# --- 2. Data Selection (Summary-Driven) ---
dt_summary <- fread(file_summary)
target_values <- c(0.5, 0.777, 1.037, 1.373, 1.975, 10.0)

# Pull exact simulation metadata for the closest matches [cite: 1-10]
dt_selected <- rbindlist(lapply(target_values, function(v) {
  dt_summary[which.min(abs(normalized_momentum - v))]
}))

# --- 3. Plotting Function ---
render_prl_grid <- function(dt_meta) {
  plot_list <- list()
  num_rows <- nrow(dt_meta)

  for (i in seq_len(num_rows)) {
    p_val   <- dt_meta[i, normalized_momentum]
    n_val   <- dt_meta[i, node_count]
    p_str   <- sprintf("%013.6f", p_val)
    a_ratio <- 4 * (p_val^2) # A relative to A_0 (where P=0.5)

    # Column 1: Quantum of Action (Phase Space)
    a_base <- p_val / 0.5
    b_base <- 0.5 / p_val
    scaling <- 90 / max(a_base, b_base)

    p_ell <- ggplot(data.frame(type=factor(c("Q","P"), levels=c("Q","P")),
                               major=c(a_base, b_base)*scaling,
                               minor=c(b_base, a_base)*scaling)) +
      geom_ellipse(aes(x0=0, y0=0, a=major, b=minor, angle=0, fill=type),
                   alpha=0.2, color="black", linewidth=0.3) +
      scale_fill_manual(values=c("Q"="black", "P"="gray60")) +
      coord_fixed(xlim=c(-100,100), ylim=c(-100,100)) +
      scale_x_continuous(breaks = c(-100, 0, 100)) +
      scale_y_continuous(breaks = c(-100, 0, 100)) +
      theme_bw(base_family = "serif") +
      theme(legend.position="none", panel.grid.minor=element_blank(), axis.text=element_text(size=8)) +
      labs(x = expression("Coordinate, " * italic(q)), y = expression("Momentum, " * italic(p)))

    # Column 2: Mapping (Microstate vs. Action State) [cite: 11-13]
    file_raw <- file.path(dir_01_raw_erasures, sprintf("harmonic_oscillator_erasures_stern_brocot_P_%s.csv.gz", p_str))
    p_scat <- ggplot() + theme_void() + theme(aspect.ratio=1)

    # Centered Row Subtitle
    row_subtitle <- bquote(bold(A == .(sprintf("%.1f", a_ratio))*A[0] ~~~~~ "node count" == .(n_val)))

    if (file.exists(file_raw)) {
      dt_raw <- fread(file_raw)[found == 1]
      p_scat <- ggplot(dt_raw, aes(x=microstate, y=minimal_action_state)) +
        geom_point(alpha=0.15, size=0.01, stroke=0, color="black") +
        scale_x_continuous(breaks = c(0, 50, 100)) +
        scale_y_continuous(breaks = c(0, 50, 100)) +
        labs(subtitle = row_subtitle) +
        theme_bw(base_family = "serif") +
        theme(panel.grid.minor=element_blank(), axis.text = element_text(size=8),
              plot.subtitle=element_text(size=10, hjust=0.5, face="bold"),
              axis.title.y=element_text(size=9)) +
        labs(x = expression("Coordinate Microstate, " * italic(q)[mu]),
             y = expression("Minimal-Action State, " * italic(q)^"*"))
    }

    # Column 3: Coordinate Density (Skyline + Emergent Nodes) [cite: 1-10]
    file_density <- file.path(dir_02_densities, sprintf("harmonic_oscillator_erasure_distance_density_stern_brocot_P_%s.csv.gz", p_str))
    p_den <- ggplot() + theme_void() + theme(aspect.ratio=1)
    if (file.exists(file_density)) {
      dt_hist <- fread(file_density)
      max_h <- max(dt_hist$density_count); width <- median(diff(dt_hist$coordinate_q))
      max_q <- max(abs(dt_hist$coordinate_q)) + (width/2)
      dt_hist[, `:=`(pct_h = (density_count/max_h)*100, pct_q = (coordinate_q/max_q)*100)]

      # Correct Skyline Staircase Geometry
      step_x <- c(dt_hist$pct_q[1]-(width/max_q)*50,
                  rep(dt_hist$pct_q, each=2)+rep(c(-(width/max_q)*50, (width/max_q)*50), nrow(dt_hist)),
                  dt_hist$pct_q[nrow(dt_hist)]+(width/max_q)*50)
      step_y <- c(0, rep(dt_hist$pct_h, each=2), 0)

      p_den <- ggplot(data.frame(x=step_x, y=step_y), aes(x=x, y=y)) +
        geom_polygon(fill="gray85", color=NA) +
        geom_path(color="black", linewidth=0.4) +
        scale_x_continuous(breaks=c(-100, 0, 100)) +
        scale_y_continuous(breaks=c(0, 50, 100)) +
        coord_cartesian(xlim=c(-100,100), ylim=c(0,110)) +
        theme_bw(base_family="serif") +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8)) +
        labs(x = expression("Coordinate, " * italic(q) == (italic(A)/italic(h)) * epsilon[italic(q)]),
             y = "Density Count")

      # Re-load emergent node dots [cite: 1-10]
      file_nodes <- file.path(dir_03_nodes, sprintf("harmonic_oscillator_erasure_distance_nodes_stern_brocot_P_%s.csv.gz", p_str))
      if(file.exists(file_nodes)){
        dt_n <- fread(file_nodes)
        if (nrow(dt_n) > 0) {
          dt_n[, `:=`(pct_y = (density_count/max_h)*100, pct_x = (coordinate_q/max_q)*100)]
          p_den <- p_den + geom_point(data=dt_n, aes(x=pct_x, y=pct_y), size=0.8, color="black")
        }
      }
    }

    # Column Headers (Top Row)
    if (i == 1) {
      p_ell  <- p_ell  + labs(title = "Quantum of Action")
      p_scat <- p_scat + labs(title = "Microstate vs. Minimal-Action State")
      p_den  <- p_den  + labs(title = "Coordinate Density")
    }
    # Standardize X-labels (Bottom Row Only)
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

# --- 4. Render with Dynamic Height ---
# Ensures aspect ratio is preserved: ~2.3in per row + title/axis overhead
dynamic_height <- nrow(dt_selected) * 2.3 + 1.2

pdf(file = file_output_pdf, width = 8.5, height = dynamic_height)
print(render_prl_grid(dt_selected))
dev.off()

cat("Figure generated successfully:", file_output_pdf, "\n")
