library(data.table)
library(ggplot2)
library(ggforce)
library(patchwork)

# --- 0. FONT SETUP FOR PRL MANUSCRIPT ---
latex_font <- "CMU Serif"

# --- 1. FIXED FILENAME FOR MANUSCRIPT ---
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)
file_output_pdf <- file.path(dir_manuscript, "harmonic_oscillator.pdf")

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw_erasures <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities    <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes        <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
dir_04_summary      <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

file_summary <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")

# --- 2. Data Selection (Action-Driven) ---
dt_summary <- fread(file_summary)
target_a_ratios <- c(2^(0:4), 400)

dt_selected <- rbindlist(lapply(target_a_ratios, function(target_ratio) {
  target_p <- sqrt(target_ratio) / 2
  dt_summary[which.min(abs(normalized_momentum - target_p))]
}))

# --- 3. Plotting Function ---
render_prl_grid <- function(dt_meta) {
  plot_list <- list()
  num_rows <- nrow(dt_meta)

  for (i in seq_len(num_rows)) {
    p_val   <- dt_meta[i, normalized_momentum]
    p_str   <- sprintf("%013.6f", p_val)
    a_ratio <- 4 * (p_val^2)

    # --- THE PHYSICS ALIGNMENT ---
    # Theoretical boundaries: Ensures perfect circle at A_0 (p=0.5) -> max_ax = 1, min_ax = 1
    max_ax <- p_val / 0.5
    min_ax <- 0.5 / p_val

    file_density <- file.path(dir_02_densities, sprintf("harmonic_oscillator_erasure_displacement_density_stern_brocot_P_%s.csv.gz", p_str))

    lim_x <- max_ax
    total_count <- 1.0

    if (file.exists(file_density)) {
      dt_hist <- fread(file_density)

      # Scale C++ output to match the theoretical 2P boundary
      dt_hist[, coordinate_q := coordinate_q / pi]

      # Convert raw counts to Density (Percent of total)
      total_count <- sum(dt_hist$density_count, na.rm=TRUE)
      if (total_count > 0) {
        dt_hist[, pct := (density_count / total_count) * 100]
      } else {
        dt_hist[, pct := 0]
      }

      width <- median(diff(dt_hist$coordinate_q), na.rm=TRUE)

      active_q <- dt_hist[density_count > 0, coordinate_q]
      if (length(active_q) > 0) {
        max_q <- max(abs(active_q), na.rm=TRUE) + (width/2)
        lim_x <- max(max_ax, max_q)
      }
    }

    # Strict limits to keep the 3 data columns identical
    plot_lim_x <- lim_x * 1.05

    # --- Column 0: Row Label (Far Left) ---
    # Simplified expression to avoid truncation
    row_label_expr <- bquote(.(sprintf("%.1f", a_ratio)) * A[0])

    p_label <- ggplot() +
      annotate("text", x = 1, y = 0.5, label = row_label_expr, parse = TRUE,
               family = latex_font, size = 4, hjust = 1) +
      theme_void() +
      coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off")

    # --- Column 1: Quantum of Action (Phase Space) ---
    df_ell <- data.frame(
      max_ax = max_ax, min_ax = min_ax,
      x0 = 0, y0 = 0, angle = 0
    )

    p_ell <- ggplot(df_ell) +
      geom_ellipse(aes(x0=x0, y0=y0, a=max_ax, b=max_ax, angle=angle), fill=NA, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=max_ax, b=min_ax, angle=angle), fill="#A9A9A9", alpha=0.25, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=min_ax, b=max_ax, angle=angle), fill="#A9A9A9", alpha=0.25, color="#5E5E5E", linewidth=0.3) +
      geom_ellipse(aes(x0=x0, y0=y0, a=min_ax, b=min_ax, angle=angle), fill="#FFFFFF", alpha=1.0, color="#5E5E5E", linewidth=0.3) +
      coord_fixed(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
      theme_bw(base_family = latex_font) +
      theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8)) +
      labs(x = expression("Position, " * italic(q)/italic(q)[0]),
           y = expression("Momentum, " * italic(p)/italic(p)[0]))

    # --- Column 2: Mapping (Target vs. Selected Microstate) ---
    file_raw <- file.path(dir_01_raw_erasures, sprintf("harmonic_oscillator_erasures_stern_brocot_P_%s.csv.gz", p_str))
    p_scat <- ggplot() + theme_void() + theme(aspect.ratio=1)

    if (file.exists(file_raw)) {
      dt_raw <- fread(file_raw, colClasses=c(encoded_sequence="character"))[found == 1]

      dt_raw[, `:=`(x_scaled = blob_center * max_ax, y_scaled = selected_microstate * max_ax)]

      p_scat <- ggplot(dt_raw, aes(x=x_scaled, y=y_scaled)) +
        geom_point(alpha=0.3, size=0.5, stroke=0, color="black") +
        coord_fixed(xlim=c(-plot_lim_x, plot_lim_x), ylim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        theme_bw(base_family = latex_font) +
        theme(panel.grid.minor=element_blank(),
              axis.text = element_text(size=8),
              axis.title.y = element_text(size=9)) +
        labs(x = expression("Blob Center, " * italic(q)[b]/italic(q)[0]),
             y = expression("Selected Microstate, " * italic(q)[mu]^"*" / italic(q)[0]))
    }

    # --- Column 3: Landauer Erasure Density (Skyline + Emergent Nodes) ---
    p_den <- ggplot() + theme_void() + theme(aspect.ratio=1)

    if (file.exists(file_density)) {
      step_x <- c(dt_hist$coordinate_q[1] - width/2,
                  rep(dt_hist$coordinate_q, each=2) + rep(c(-width/2, width/2), nrow(dt_hist)),
                  dt_hist$coordinate_q[nrow(dt_hist)] + width/2)
      step_y <- c(0, rep(dt_hist$pct, each=2), 0)

      p_den <- ggplot(data.frame(x=step_x, y=step_y), aes(x=x, y=y)) +
        geom_polygon(fill="gray85", color=NA) +
        geom_path(color="black", linewidth=0.4) +
        # Allow Y-axis to dynamically fill without strict ceilings
        coord_cartesian(xlim=c(-plot_lim_x, plot_lim_x), expand=FALSE) +
        theme_bw(base_family=latex_font) +
        theme(panel.grid.minor=element_blank(), axis.text=element_text(size=8), aspect.ratio=1) +
        labs(x = expression("Position, " * italic(q)/italic(q)[0]),
             y = "Density (%)")

      file_nodes <- file.path(dir_03_nodes, sprintf("harmonic_oscillator_erasure_displacement_nodes_stern_brocot_P_%s.csv.gz", p_str))
      if(file.exists(file_nodes)){
        dt_n <- fread(file_nodes)
        if (nrow(dt_n) > 0) {
          dt_n[, coordinate_q := coordinate_q / pi]
          dt_n[, pct := (density_count / total_count) * 100]
          p_den <- p_den + geom_point(data=dt_n, aes(x=coordinate_q, y=pct), size=0.8, color="black")
        }
      }
    }

    # --- Column Headers & Axis Cleanup ---
    if (i == 1) {
      p_label <- p_label + labs(title = " ") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))

      p_ell  <- p_ell  + labs(title = "Quantum of Action") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))
      p_scat <- p_scat + labs(title = "Microstate vs. Blob Center") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))
      p_den  <- p_den  + labs(title = "Landauer Erasure Density") + theme(plot.title=element_text(size=11, hjust=0.5, face="plain"))
    }

    if (i != num_rows) {
      p_ell  <- p_ell  + theme(axis.title.x = element_blank())
      p_scat <- p_scat + theme(axis.title.x = element_blank())
      p_den  <- p_den  + theme(axis.title.x = element_blank())
    }

    plot_list <- c(plot_list, list(p_label, p_ell, p_scat, p_den))
  }

  wrap_plots(plot_list, ncol = 4, widths = c(0.25, 1, 1, 1))
}

# --- 4. Render with Cairo PDF for Font Embedding ---
dynamic_height <- nrow(dt_selected) * 2.3 + 1.2

cairo_pdf(file = file_output_pdf, width = 8.5, height = dynamic_height, family = latex_font)
print(render_prl_grid(dt_selected))
dev.off()

cat("Figure generated successfully:", file_output_pdf, "\n")
