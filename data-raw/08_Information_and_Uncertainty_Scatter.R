library(here)
library(data.table)
library(ggplot2)
library(viridis)

here::i_am("data-raw/08_Information_and_Uncertainty_Scatter.R")

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell_curve"

alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 360, by = 1) + 1e-5

# 1. LOAD DATA
plot_data <- list()

cat("--- GENERATING CONJUGATE SCATTER DATA (LINEAR) ---\n")

for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  path_b <- file.path(data_dir, f_b)

  if (file.exists(path_b)) {
    dt_b <- fread(path_b, select = c("uncertainty", "program_length", "found"))
    dt_b <- dt_b[found == TRUE]

    if (nrow(dt_b) > 0) {
      # Random sample to keep plot responsive
      if (nrow(dt_b) > 500) dt_b <- dt_b[sample(.N, 500)]

      dt_b[, phi := b_ang - alice_fixed]
      dt_b[, phase_label := abs(sin(phi * pi / 180))]
      plot_data[[length(plot_data) + 1]] <- dt_b
    }
  }
}

dt_all <- rbindlist(plot_data)

# 2. CREATE THE SCATTER PLOT (LINEAR SCALES)
gp <- ggplot(dt_all, aes(x = uncertainty, y = program_length)) +

  # --- THE DATA CLOUD ---
  geom_point(aes(color = phi), alpha = 0.3, size = 0.8) +

  # --- COLOR SCALE (Phase) ---
  scale_color_viridis_c(option = "plasma", name = "Phase (°)",
                        breaks = c(0, 90, 180, 270, 360)) +

  scale_x_log10(breaks = scales::trans_breaks("log10", function(x) 10^x),
                labels = scales::trans_format("log10", scales::math_format(10^.x))) +

  scale_y_log10(breaks = c(1, 2, 5, 10, 20, 50, 100)) +


  labs(
    title = "The Equation of State: Information vs. Uncertainty",
    subtitle = "Linear Plot showing the hyperbolic trade-off (Conjugacy)",
    x = "Detector Uncertainty (Delta)",
    y = "Thermodynamic Cost (Bits)"
  ) +

  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.minor = element_blank()
  )

print(gp)
