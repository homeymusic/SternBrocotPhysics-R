library(data.table)
library(SternBrocotPhysics) # Ensure package is rebuilt before sourcing
library(svglite)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")
file_seq_len      <- file.path(dir_04_summary, "harmonic_oscillator_sequence_length_summary.csv.gz")

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

# --- 4A. Render as PDF ---
file_output_action_pdf <- file.path(dir_manuscript, "erasure_action.pdf")
cairo_pdf(file = file_output_action_pdf, width = 8.5, height = 6.0, family = latex_font)
print(p_action)
dev.off()
cat("Manuscript action figure (PDF) generated successfully:", file_output_action_pdf, "\n")

# --- 4B. Render as SVG for OmniGraffle ---
file_output_action_svg <- file.path(dir_manuscript, "erasure_action.svg")
svglite::svglite(file = file_output_action_svg, width = 8.5, height = 6.0)
print(p_action)
dev.off()
cat("Manuscript action figure (SVG) generated successfully:", file_output_action_svg, "\n")
