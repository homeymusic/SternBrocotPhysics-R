library(data.table)
library(SternBrocotPhysics) # Loads your new plotting function!

# --- 1. Configuration ---
latex_font <- "CMU Serif"
dir_manuscript <- "./manuscript"
if (!dir.exists(dir_manuscript)) dir.create(dir_manuscript)
file_output_pdf <- file.path(dir_manuscript, "harmonic_oscillator.pdf")

dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_01_raw_erasures <- file.path(dir_base_data_4TB, "01_harmonic_oscillator_erasures")
dir_02_densities    <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes        <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
dir_04_summary      <- file.path(dir_base_data_4TB, "04_harmonic_oscillator_summary")

file_summary <- file.path(dir_04_summary, "harmonic_oscillator_erasure_displacement_summary.csv.gz")

# --- 2. Data Selection (Manuscript Actions) ---
dt_summary <- fread(file_summary)
dt_summary[, action_A := normalized_momentum^2]

target_a_ratios <- c(1, 3.14, 4.14, 5.5, 8.0, 9.0, 50.0)
dt_selected <- rbindlist(lapply(target_a_ratios, function(target_ratio) {
  target_p <- sqrt(target_ratio)
  dt_summary[which.min(abs(normalized_momentum - target_p))]
}))

# --- 3. Render ---
dynamic_height <- nrow(dt_selected) * 2.3 + 1.2
cairo_pdf(file = file_output_pdf, width = 8.5, height = dynamic_height, family = latex_font)
print(plot_erasure_grid(dt_selected, dir_01_raw_erasures, dir_02_densities, dir_03_nodes,
                        style = "manuscript", base_font = latex_font,
                        show_nodes = FALSE)) # Dots effectively turned off
dev.off()

cat("Manuscript figure generated successfully:", file_output_pdf, "\n")
