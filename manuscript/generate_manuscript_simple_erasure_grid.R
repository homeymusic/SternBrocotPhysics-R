library(data.table)
library(SternBrocotPhysics) # Custom physics library
library(ggplot2)
library(ggforce)
library(patchwork)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

# Output filenames
file_output_pdf  <- file.path(dir_manuscript, "simple_erasure_grid.pdf")
file_output_png  <- file.path(dir_manuscript, "simple_erasure_grid.png")

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw        <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities  <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes      <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

file_summary <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")

# --- 2. Data Selection ---
dt_summary <- fread(file_summary)
dt_summary[, action_A := normalized_momentum^2]

# Targets defined by the user
target_a_ratios <- c(1, 3, 4, 5.5, 8, 9, 50)
dt_selected <- rbindlist(lapply(target_a_ratios, function(target_ratio) {
  target_p <- sqrt(target_ratio)
  dt_summary[which.min(abs(normalized_momentum - target_p))]
}))

# --- 3. Rendering Logic ---

# Function call to generate the patchwork object
# Note: show_nodes = FALSE to reduce visual noise/rendering time as requested
p_final <- plot_simple_erasure_grid(
  dt_meta = dt_selected,
  dir_raw = dir_01_raw,
  dir_densities = dir_02_densities,
  dir_nodes = dir_03_nodes,
  style = "manuscript",
  base_font = latex_font,
  show_nodes = FALSE
)

# Add a tiny bit of margin to ensure axis labels aren't clipped during rasterization
p_final <- p_final + theme(plot.margin = margin(10, 10, 10, 10))

# Calculate dimensions based on number of rows
# Reduced width to 6.5 so the 2 columns maintain roughly the same square aspect ratio
fig_width  <- 6.5
fig_height <- nrow(dt_selected) * 2.3 + 1.2

# --- 4. Export ---

# Save PDF (Vector Master)
ggsave(
  filename = file_output_pdf,
  plot = p_final,
  device = cairo_pdf,
  width = fig_width,
  height = fig_height,
  limitsize = FALSE
)

# Save PNG (High-Res Bitmap for Manuscript/Overleaf)
# 600 DPI is the gold standard for PRL/Physical Review manuscripts.
ggsave(
  filename = file_output_png,
  plot = p_final,
  device = "png",
  type = "cairo",    # Vital for correct font rendering on bitmap
  width = fig_width,
  height = fig_height,
  dpi = 600,
  bg = "white",
  limitsize = FALSE
)

cat("Success! Files generated:\n")
cat("PDF (Vector):", file_output_pdf, "\n")
cat("PNG (600 DPI):", file_output_png, "\n")
