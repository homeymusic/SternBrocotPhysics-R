library(data.table)
library(SternBrocotPhysics)
library(ggplot2)
library(patchwork)

# --- 1. Configuration ---
latex_font <- "CMU Serif"
mono_font  <- "CMU Typewriter Text"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_04_summary    <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

# Input files
file_nodes     <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")
file_action    <- file.path(dir_04_summary, "harmonic_oscillator_sequence_length_summary.csv.gz")
file_disp_dist <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_distribution_summary.csv.gz")

file_output_pdf <- file.path(dir_manuscript, "action_grid.pdf")
file_output_png <- file.path(dir_manuscript, "action_grid.png")

fig_w <- 8.5
fig_h <- 10.0

# --- 2. Data Load & Prep ---
if (!file.exists(file_nodes)) stop("Nodes summary missing!")
if (!file.exists(file_action)) stop("Sequence length summary missing!")
if (!file.exists(file_disp_dist)) stop("Displacement distribution summary missing!")

dt_nodes  <- fread(file_nodes)
dt_action <- fread(file_action)
dt_disp   <- fread(file_disp_dist)

if (!"action_A" %in% names(dt_nodes)) dt_nodes[, action_A := normalized_momentum^2]
if (!"action_A" %in% names(dt_action)) dt_action[, action_A := normalized_momentum^2]
if (!"action_A" %in% names(dt_disp)) dt_disp[, action_A := normalized_momentum^2]

# --- 3. Generate Individual Plot Objects ---
max_A <- 50
plot_style <- "manuscript"

p_nodes <- plot_erasure_nodes(
  dt_summary = dt_nodes, max_action = max_A, style = plot_style,
  base_font = latex_font, mono_font = mono_font
)

p_action <- plot_erasure_action(
  dt_summary = dt_action, max_action = max_A, style = plot_style,
  base_font = latex_font
)

p_disp <- plot_erasure_displacement(
  dt_summary = dt_disp, max_action = max_A, style = plot_style,
  base_font = latex_font
)

# --- 4. Combine with Patchwork ---
# With both plots having identical min/max Boundary aesthetic mappings,
# patchwork will collect and unify the guides perfectly on its own.
p_combined <- p_nodes / p_action / p_disp +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "bottom",
    plot.margin = margin(t = 5, r = 15, b = 5, l = 5)
  )

p_combined[[1]] <- p_combined[[1]] + theme(axis.title.x = element_blank())
p_combined[[2]] <- p_combined[[2]] + theme(axis.title.x = element_blank())

# --- 5. Export ---
ggsave(
  filename = file_output_pdf,
  plot = p_combined,
  device = cairo_pdf,
  width = fig_w,
  height = fig_h
)

ggsave(
  filename = file_output_png,
  plot = p_combined,
  device = "png",
  type = "cairo",
  width = fig_w,
  height = fig_h,
  dpi = 600,
  bg = "white"
)

cat("✅ Action vertical grid generated successfully:\n")
cat("PDF Master:", file_output_pdf, "\n")
cat("PNG Manuscript:", file_output_png, "\n")
