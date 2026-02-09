here::i_am("data-raw/07_canonical_bell_curve.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell_curve"
rows_to_sweep <- 1e6
alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 360, by = 2) + 1e-5
all_angles <- sort(unique(c(alice_fixed, bob_sweep)))

# 1. CLEAN SLATE
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)
unlink(list.files(data_dir, full.names = TRUE))

# 2. GENERATE DATA
cat("--- GENERATING CANONICAL DATA (0 to 2π Sweep) ---\n")
SternBrocotPhysics::micro_macro_bell_erasure_sweep(
  angles = all_angles,
  dir = normalizePath(data_dir, mustWork = TRUE),
  count = rows_to_sweep,
  n_threads = 6
)

# 3. CALCULATE CORRELATION
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

results <- list()
for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

  phi_deg <- b_ang - alice_fixed
  valid <- dt_a$found & dt_b$found

  if (any(valid)) {
    corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
    results[[as.character(b_ang)]] <- data.table(phi = phi_deg, E = corr)
  }
}
manifold_dt <- rbindlist(results)

# 4. HELPER: CLASSICAL TRIANGLE WAVE FUNCTION
# This represents the best possible correlation for a standard local hidden variable
classical_limit <- function(x_deg) {
  # Normalize to 0-360
  x <- x_deg %% 360

  # Linear Sawtooth Logic
  ifelse(x <= 180,
         -1 + (2 * x / 180),      # 0 to 180: Line from -1 to +1
         1 - (2 * (x - 180) / 180) # 180 to 360: Line from +1 to -1
  )
}

# 5. RENDER THE DIAGNOSTIC PLOT
gp <- ggplot(manifold_dt, aes(x = phi, y = E)) +

  # A. THE CLASSICAL LIMIT (Grey Area)
  # If you are inside this grey triangle (closer to 0), you are classical.
  # If you are OUTSIDE (closer to Red), you are Quantum.
  stat_function(fun = classical_limit, geom = "area", fill = "grey50", alpha = 0.2) +
  stat_function(fun = classical_limit, color = "grey40", linetype = "dotted", size = 0.8) +

  # B. THE QUANTUM TARGET (Red Dashed)
  stat_function(fun = function(x) -cos(x * pi / 180), color = "#e74c3c", size = 1, linetype = "dashed") +

  # C. YOUR DATA (Blue Line)
  geom_line(color = "#2c3e50", size = 0.8) +
  geom_point(color = "#3498db", size = 1.5, alpha = 0.8) +

  # D. MARKERS (45 Degree "Battlegrounds")
  geom_vline(xintercept = c(45, 135, 225, 315), color = "#27ae60", linetype = "solid", alpha = 0.5) +

  # E. ANNOTATIONS
  annotate("text", x = 45, y = -0.2, label = "Max Violation Zone\n(45°)", color = "#27ae60", fontface = "bold", size = 3) +
  annotate("text", x = 180, y = 0.2, label = "Classical Limit\n(Grey Triangle)", color = "grey40", size = 3) +

  # SCALES
  scale_x_continuous(breaks = seq(0, 360, by = 45),
                     labels = c("0", "45", "90", "135", "180", "225", "270", "315", "360")) +
  ylim(-1.1, 1.1) +
  labs(
    title = "Bell Test Diagnostic: Classical vs. Quantum",
    subtitle = "Grey Area: Local Realist Limit | Red Line: Quantum Target | Blue: Simulation",
    x = "Relative Phase phi (Degrees)",
    y = "Correlation Coefficient E"
  ) +
  theme_minimal()

print(gp)
