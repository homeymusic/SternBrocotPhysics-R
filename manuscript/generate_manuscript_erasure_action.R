library(data.table)
library(SternBrocotPhysics) # Ensure package is rebuilt before sourcing
library(ggplot2)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")
file_seq_len      <- file.path(dir_04_summary, "harmonic_oscillator_sequence_length_summary.csv.gz")

# Output filenames
file_output_pdf  <- file.path(dir_manuscript, "erasure_action.pdf")
file_output_png  <- file.path(dir_manuscript, "erasure_action.png")

# --- 2. Data Load ---
if (!file.exists(file_seq_len)) stop("Sequence length summary file not found!")
dt_summary <- fread(file_seq_len)
dt_summary[, action_A := normalized_momentum^2]

# --- 3. Generate Action Plot Object ---
p_action <- plot_erasure_action(
  dt_summary = dt_summary,
  max_action = 50,
  style = "manuscript",
  base_font = latex_font
)

# Add padding to prevent label clipping during rasterization
p_action <- p_action + theme(plot.margin = margin(10, 10, 10, 10))

# Standard dimensions
fig_w <- 8.5
fig_h <- 6.0

# --- 4. Export ---

# 4A. Render as PDF (Vector Master)
ggsave(
  filename = file_output_pdf,
  plot = p_action,
  device = cairo_pdf,
  width = fig_w,
  height = fig_h
)

# 4B. Render as PNG (High-Res Bitmap for Overleaf/Manuscript)
ggsave(
  filename = file_output_png,
  plot = p_action,
  device = "png",
  type = "cairo",
  width = fig_w,
  height = fig_h,
  dpi = 600,
  bg = "white"
)

cat("Figures generated successfully:\n")
cat("PDF Master:", file_output_pdf, "\n")
cat("PNG Manuscript:", file_output_png, "\n")
