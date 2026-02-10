library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
# We save directly to the package's figure directory for the README
output_dir <- "man/figures"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# TEMP DATA DIR
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_bell_test"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

FIXED_KAPPA <- 4 / pi
# CIRCLE_PROJECTION <- 2 / pi
CIRCLE_PROJECTION <- (sqrt(5) - 1) / 2

# --- SIMULATION PARAMETERS ---
# Full 360 degree sweep for symmetry
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 360, by = 10) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))
sim_count   <- 1e5

cat("--- GENERATING HERO SHOT ---\n")
cat(sprintf("Delta: pi / 2 (%.6f) | Kappa: 4/π (%.4f)\n", CIRCLE_PROJECTION, FIXED_KAPPA))

# 1. RUN SIMULATION
SternBrocotPhysics::micro_macro_bell_erasure_sweep(
  angles = all_angles,
  dir = normalizePath(data_dir, mustWork = TRUE),
  count = sim_count,
  kappa = FIXED_KAPPA,
  delta_particle = CIRCLE_PROJECTION,
  mu_start = -pi,
  mu_end = pi,
  n_threads = 6
)

# 2. PROCESS DATA
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

plot_data <- list()

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

# 3. METRICS
E_45  <- approx(dt_plot$phi, dt_plot$E, xout = 45)$y
E_135 <- approx(dt_plot$phi, dt_plot$E, xout = 135)$y
S_val <- abs(3 * E_45 - E_135)
dt_plot[, Quantum := -cos(phi * pi / 180)]
rmse_val <- sqrt(mean((dt_plot$E - dt_plot$Quantum)^2))

# 4. PLOT
subtitle_str <- sprintf("Parameters: Δ=2/π, κ=4/π | S=%.5f (Target 2.828) | RMSE=%.4f",
                        S_val, rmse_val)

# Classical Limit Function (Sawtooth)
classical_sawtooth <- function(x) {
  ifelse(x <= 180, -1 + (2*x/180), 3 - (2*x/180))
}

gp <- ggplot(dt_plot, aes(x = phi)) +

  # Classical Limit (Red Line)
  stat_function(fun = classical_sawtooth,
                color = "gray", size = 0.8, alpha = 0.6) +

  # Quantum Prediction (Black Dashed)
  stat_function(fun = function(x) -cos(x * pi / 180),
                color = "darkgray", size = 1) +

  geom_point(aes(y = E), color = "red", alpha = 0.5, size = 0.1) +

  scale_x_continuous(
    breaks = seq(0, 360, by = 45),           # Create breaks every 45 degrees
    labels = paste0(seq(0, 360, by = 45), "°") # Automatically add "°" to the numbers
  ) +

  ylim(-1.1, 1.1) +

  labs(
    title = "Bell Test",
    subtitle = subtitle_str,
    x = "Relative Phase",
    y = "Correlation E"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(face = "italic", hjust = 0.5, color="grey30"),
    panel.grid.minor = element_blank()
  )

print(gp)

# 5. SAVE
save_path <- file.path(output_dir, "hero_bell.png")
ggsave(save_path, plot = gp, width = 10, height = 6, dpi = 300)

cat(sprintf("\nImage saved to: %s\n", save_path))
# Cleanup temp data
unlink(data_dir, recursive = TRUE)
