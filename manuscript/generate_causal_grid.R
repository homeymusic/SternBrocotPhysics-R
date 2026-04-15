library(data.table)
library(SternBrocotPhysics)
library(ggplot2)
library(patchwork)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

file_output_pdf  <- file.path(dir_manuscript, "causal_chain_grid.pdf")
file_output_png  <- file.path(dir_manuscript, "causal_chain_grid.png")

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw        <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities  <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

file_summary <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")

# --- 2. Data Selection ---
if (!file.exists(file_summary)) stop("Summary file missing!")
dt_summary <- fread(file_summary)
if (!"action_A" %in% names(dt_summary)) dt_summary[, action_A := normalized_momentum^2]

# Targets: 1 low-action quantum row, 1 high-action classical row
target_a_ratios <- c(1, 3, 50)
dt_selected <- rbindlist(lapply(target_a_ratios, function(target_ratio) {
  target_p <- sqrt(target_ratio)
  dt_summary[which.min(abs(normalized_momentum - target_p))]
}))

# --- 3. Rendering Logic ---
p_final <- plot_5col_erasure_grid(
  dt_meta = dt_selected,
  dir_raw = dir_01_raw,
  dir_densities = dir_02_densities,
  style = "manuscript",
  base_font = latex_font
)

# FIX: Add a 10-point left margin to the overarching plot to prevent label clipping
p_final <- p_final + theme(plot.margin = margin(t=5, r=5, b=5, l=15))

# Dimensions for a 2-column landscape layout in PRL
fig_width  <- 8.6
fig_height <- 3.8

# --- 4. Export ---
ggsave(
  filename = file_output_pdf,
  plot = p_final,
  device = cairo_pdf,
  width = fig_width,
  height = fig_height,
  limitsize = FALSE
)

ggsave(
  filename = file_output_png,
  plot = p_final,
  device = "png",
  type = "cairo",
  width = fig_width,
  height = fig_height,
  dpi = 600,
  bg = "white",
  limitsize = FALSE
)

cat("✅ 5-Column Causal Grid generated successfully:\n")
cat("PDF (Vector):", file_output_pdf, "\n")
cat("PNG (600 DPI):", file_output_png, "\n")
