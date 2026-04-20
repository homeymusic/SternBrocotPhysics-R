library(data.table)
library(ggplot2)
library(ggforce)
library(patchwork)
# library(YourPackageNameHere) # Ensure package is loaded if running externally

# --- 1. Configuration ---
latex_font <- "CMU Serif"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

# Output filenames
file_output_pdf  <- file.path(dir_manuscript, "berry_grid.pdf")
file_output_png  <- file.path(dir_manuscript, "berry_grid.png")

# --- 2. Data Selection ---
target_n_levels <- c(0, 1, 2, 5, 25)

dt_selected <- data.table(
  quantum_n = target_n_levels,
  action_A = 2 * target_n_levels + 1
)

# --- 3. Rendering Logic ---
cat("Generating Berry geometric landscape and executing kinematic scans...\n")

p_final <- plot_berry_grid(
  dt_meta = dt_selected,
  style = "manuscript",
  base_font = latex_font
)

p_final <- p_final + theme(plot.margin = margin(10, 10, 10, 10))

# Adjusted width for 4-column layout
fig_width  <- 8.5
fig_height <- nrow(dt_selected) * 2.3 + 1.2

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

cat("Success! Kinematic Berry geometric plots generated in", dir_manuscript, ":\n")
cat("PDF (Vector):", file_output_pdf, "\n")
cat("PNG (600 DPI):", file_output_png, "\n")
