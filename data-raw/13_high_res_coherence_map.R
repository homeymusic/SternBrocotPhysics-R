# --- 13_high_res_coherence_map.R ---
# Goal: Map the "Breathing" Information Budget at 0.5° resolution.
# Required: SternBrocotPhysics package must be installed.

library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
rows_expected <- 1e6 + 1
n_threads <- 6  # Adjust based on your Mac's CPU cores

# Ensure directory exists
if (!dir.exists(smoke_dir)) dir.create(smoke_dir, recursive = TRUE)

# --- 1. PREPARE HIGH-RES ANGLES ---
# 0.5 degree steps = 181 sampling points across 90 degrees
sweep_angles <- seq(0, 90, by = 0.5) + 1e-5

# --- 2. GENERATE SIMULATION DATA ---
# This invokes the C++ simulator for the full high-res sweep
cat(sprintf("--- GENERATING %d HIGH-RES SIMULATION FILES ---\n", length(sweep_angles)))
cat("This may take a few minutes depending on your drive speed...\n")

SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = sweep_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = rows_expected,
  n_threads = n_threads
)

# --- 3. ANALYSIS LOOP ---
cat("\n--- CALCULATING COHERENCE SUMS (ALICE + BOB) ---\n")
sweep_summary <- data.table()

for (ang in sweep_angles) {
  # Load Alice binary outcomes
  fname_a <- sprintf("micro_macro_erasures_alice_%013.6f.csv.gz", ang)
  dt_a <- fread(file.path(smoke_dir, fname_a), select = "spin")

  # Load Bob binary outcomes
  fname_b <- sprintf("micro_macro_erasures_bob_%013.6f.csv.gz", ang)
  dt_b <- fread(file.path(smoke_dir, fname_b), select = "spin")

  # Calculate uncertainty budgets (Delta)
  rad <- ang * (pi / 180)
  delta_a <- cos(rad)^2
  delta_b <- sin(rad)^2

  # Calculate Coherence (Percentage of 'Up' spins)
  up_a <- (sum(dt_a$spin == 1) / nrow(dt_a)) * 100
  up_b <- (sum(dt_b$spin == 1) / nrow(dt_b)) * 100

  # Pole correction: Force zero coherence when the window width is zero
  if (delta_a < 1e-10) up_a <- 0.0
  if (delta_b < 1e-10) up_b <- 0.0

  sweep_summary <- rbind(sweep_summary, data.table(
    Angle = ang,
    Alice_U = up_a,
    Bob_U   = up_b,
    Coherence_Total = up_a + up_b
  ))
}

# --- 4. FINDING RESONANCE PEAKS ---
# Sort by highest coherence to find the "Surplus" nodes
top_resonances <- sweep_summary[order(-Coherence_Total)][1:5]
print("--- TOP 5 RATIONAL RESONANCE PEAKS ---")
print(top_resonances)

# --- 5. PLOTTING THE HIGH-RES RESONANCE ---
cat("\n--- RENDERING HIGH-RES PLOT ---\n")
gp_high_res <- ggplot(sweep_summary, aes(x = Angle, y = Coherence_Total)) +
  geom_line(color = "#2c3e50", size = 1) +
  # The 100% Classical Invariance Line
  geom_hline(yintercept = 100, linetype = "dashed", color = "red") +
  # Vertical markers for the primary peaks observed in previous runs
  geom_vline(xintercept = c(0, 35, 45, 55, 90), alpha = 0.2, color = "blue", linetype = "dotted") +
  labs(
    title = "High-Resolution System Resonance Curve",
    subtitle = "181 Points (0.5° Sampling) | Total Coherence Sum (Alice ↑% + Bob ↑%)",
    x = "Angle (Degrees)",
    y = "Total Coherence Sum (%)",
    caption = "Dashed Red: Classical Limit (100%) | Dotted Blue: Known Rational Nodes"
  ) +
  theme_minimal()

print(gp_high_res)

# Export for external tools
fwrite(sweep_summary, file.path(smoke_dir, "high_res_coherence_data.csv"))
cat("\n✅ High-res map complete. Plot rendered and CSV exported.\n")
