library(data.table)
library(SternBrocotPhysics) # Assuming plot_erasure_nodes is exported here, or source it directly
library(svglite)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
mono_font  <- "CMU Typewriter Text"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")
file_summary      <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")

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

# --- 4A. Render as PDF ---
file_output_nodes_pdf <- file.path(dir_manuscript, "erasure_nodes.pdf")
cairo_pdf(file = file_output_nodes_pdf, width = 8.5, height = 6.0, family = latex_font)
print(p_nodes)
dev.off()
cat("Manuscript nodes figure (PDF) generated successfully:", file_output_nodes_pdf, "\n")

# --- 4B. Render as SVG for OmniGraffle ---
file_output_nodes_svg <- file.path(dir_manuscript, "erasure_nodes.svg")
svglite::svglite(file = file_output_nodes_svg, width = 8.5, height = 6.0)
print(p_nodes)
dev.off()
cat("Manuscript nodes figure (SVG) generated successfully:", file_output_nodes_svg, "\n")
