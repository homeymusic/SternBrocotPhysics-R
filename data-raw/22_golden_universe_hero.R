library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "data_raw/22_golden_universe_hero"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# THE GOLDEN CONSTANTS
PHI     <- (1 + sqrt(5)) / 2
INV_PHI <- 1 / PHI  # 0.6180339...
FIXED_KAPPA <- 4 / pi

# High Resolution Sweep (Every 1 degree)
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 180, by = 1) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))

# Maximum Precision (100k particles)
sim_count   <- 1e5

cat(sprintf("--- GENERATING HERO SHOT: THE GOLDEN UNIVERSE ---\n"))
cat(sprintf("Delta: 1/φ (%.6f) | Kappa: 4/π (%.4f)\n", INV_PHI, FIXED_KAPPA))

# 1. RUN SIMULATION
micro_macro_bell_erasure_sweep(
  angles = all_angles,
  dir = normalizePath(data_dir, mustWork = TRUE),
  count = sim_count,
  kappa = FIXED_KAPPA,
  delta_particle = INV_PHI,
  mu_start = -pi,
  mu_end = pi,
  n_threads = 6
)

# 2. PROCESS DATA
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

plot_data <- list()

cat("Processing correlations...\n")
for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  if (file.exists(file.path(data_dir, f_b))) {
    dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

    valid <- dt_a$found & dt_b$found
    if (any(valid)) {
      corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
      plot_data[[length(plot_data) + 1]] <- data.table(phi = b_ang - alice_fixed, E = corr)
    }
  }
}
dt_plot <- rbindlist(plot_data)

# 3. COMPUTE FINAL METRICS
E_45  <- approx(dt_plot$phi, dt_plot$E, xout = 45)$y
E_135 <- approx(dt_plot$phi, dt_plot$E, xout = 135)$y
S_val <- abs(3 * E_45 - E_135)

# RMSE against Quantum Cosine
dt_plot[, Quantum := -cos(phi * pi / 180)]
rmse_val <- sqrt(mean((dt_plot$E - dt_plot$Quantum)^2))

# 4. PLOT
subtitle_str <- sprintf("Constants: Δ=1/φ, κ=4/π | Result: S=%.5f (Target 2.8284), RMSE=%.4f",
                        S_val, rmse_val)

gp <- ggplot(dt_plot, aes(x = phi)) +

  # Classical Limit (Shaded Region)
  stat_function(fun = function(x) ifelse(x<=180, -1 + (2*x/180), NA),
                geom="area", fill="red", alpha=0.05) +
  stat_function(fun = function(x) ifelse(x<=180, 1 - (2*(x-180)/180), NA),
                geom="area", fill="red", alpha=0.05) +

  # Quantum Prediction (Black Dashed)
  stat_function(fun = function(x) -cos(x * pi / 180),
                color = "black", size = 1, linetype = "dashed") +

  # Simulation (Gold Line for the Golden Ratio)
  geom_line(aes(y = E), color = "goldenrod3", size = 1.5, alpha = 0.9) +

  # Annotations
  annotate("text", x = 45, y = -0.3, label = "Classical Limit", color = "firebrick", angle = 45, alpha=0.7) +
  annotate("text", x = 135, y = 0.3, label = "Quantum Limit (-cos)", color = "black", angle = 45, alpha=0.7) +

  scale_x_continuous(breaks = seq(0, 180, by = 45)) +
  ylim(-1.05, 1.05) +

  labs(
    title = "The Golden Universe: Quantum Mechanics from Maximum Irrationality",
    subtitle = subtitle_str,
    x = "Relative Phase (Degrees)",
    y = "Correlation E"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

print(gp)
