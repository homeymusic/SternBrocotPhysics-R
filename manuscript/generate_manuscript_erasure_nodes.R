library(data.table)
library(SternBrocotPhysics)
library(ggplot2)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
mono_font  <- "CMU Typewriter Text"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")
file_summary      <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")

# Output filenames
file_output_pdf  <- file.path(dir_manuscript, "erasure_nodes.pdf")
file_output_png  <- file.path(dir_manuscript, "erasure_nodes.png")

# --- 2. Data Load ---
if (!file.exists(file_summary)) stop("Summary file not found!")
dt_summary <- fread(file_summary)
dt_summary[, action_A := normalized_momentum^2]

# --- 3. Generate Node Plot Object ---
p_nodes <- plot_erasure_nodes(
  dt_summary = dt_summary,
  max_action = 50,
  style = "manuscript",
  base_font = latex_font,
  mono_font = mono_font
)

# Add padding to prevent label clipping during rasterization
p_nodes <- p_nodes + theme(plot.margin = margin(10, 10, 10, 10))

# Standard dimensions
fig_w <- 8.5
fig_h <- 6.0

# --- 4. Export ---

# 4A. Render as PDF (Vector Master)
# Best for archival and highest possible quality printing
ggsave(
  filename = file_output_pdf,
  plot = p_nodes,
  device = cairo_pdf,
  width = fig_w,
  height = fig_h
)

# 4B. Render as PNG (High-Res Bitmap for Overleaf/Manuscript)
# This eliminates scrolling lag while maintaining print-ready sharpness
ggsave(
  filename = file_output_png,
  plot = p_nodes,
  device = "png",
  type = "cairo",    # Ensures fonts and anti-aliasing are handled correctly
  width = fig_w,
  height = fig_h,
  dpi = 600,         # 600 DPI is standard for publication-quality line/node art
  bg = "white"
)

cat("Figures generated successfully:\n")
cat("PDF Master:", file_output_pdf, "\n")
cat("PNG Manuscript:", file_output_png, "\n")
