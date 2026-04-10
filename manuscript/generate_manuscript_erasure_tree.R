library(data.table)
library(SternBrocotPhysics)
library(svglite)

latex_font <- "CMU Serif"
mono_font  <- "CMU Typewriter Text" # Added mono font for \mathtt equivalent
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

# --- 4. Generate Tree Plot Object ---
p_tree <- plot_erasure_tree(
  max_N = 5,
  q_bin = "10",
  q_num = 1,
  q_den = 2,
  q_target = (sqrt(5)-1)/2,
  style = "manuscript",
  base_font = latex_font,
  mono_font = mono_font # Passed to the function
)

# --- 4A. Render as PDF ---
file_output_tree_pdf <- file.path(dir_manuscript, "erasure_tree.pdf")
cairo_pdf(file = file_output_tree_pdf, width = 8.5, height = 6.0, family = latex_font)
print(p_tree)
dev.off()
cat("Manuscript tree figure (PDF) generated successfully:", file_output_tree_pdf, "\n")

# --- 4B. Render as SVG for OmniGraffle ---
file_output_tree_svg <- file.path(dir_manuscript, "erasure_tree.svg")
svglite::svglite(file = file_output_tree_svg, width = 8.5, height = 6.0)
print(p_tree)
dev.off()
cat("Manuscript tree figure (SVG) generated successfully:", file_output_tree_svg, "\n")
