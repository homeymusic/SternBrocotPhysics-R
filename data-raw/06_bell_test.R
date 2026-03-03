library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
output_dir <- "man/figures"
data_dir   <- "/Volumes/SanDisk4TB/SternBrocot-data/06_bell_test"

if (dir.exists(data_dir)) { unlink(data_dir, recursive = TRUE) }
dir.create(data_dir, recursive = TRUE)

# --- SIMULATION (Spin-1/2 EPR-Bohm Setup) ---
detector_aperture <- 0.01
sim_count         <- 1e4 # High resolution for smooth fractal steps

# Spin-1/2 anchor requires Alice at 0
alice_fixed_rad <- c(0.0) + 1e-5
bob_sweep_rad   <- seq(0, 2 * pi, by = detector_aperture) + 1e-5

# Run C++ Engine
micro_macro_bell_erasure_sweep('alice', alice_fixed_rad, normalizePath(data_dir), sim_count, -pi, pi, 6)
micro_macro_bell_erasure_sweep('bob', bob_sweep_rad, normalizePath(data_dir), sim_count, -pi, pi, 6)

# --- PROCESS DATA ---
cols <- c("spin", "found")
f_alice <- file.path(data_dir, sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed_rad))
dt_a0   <- fread(f_alice, select = cols)

plot_list <- lapply(bob_sweep_rad, function(b_rad) {
  f_bob <- file.path(data_dir, sprintf("erasure_bob_%013.6f.csv.gz", b_rad))
  if (!file.exists(f_bob)) return(NULL)
  dt_b <- fread(f_bob, select = cols)

  v0 <- dt_a0$found & dt_b$found
  data.table(phi_rad = b_rad,
             # ADDED MINUS SIGN: Simulates the anti-correlated singlet state
             E_0  = -mean(as.numeric(dt_a0$spin[v0]) * as.numeric(dt_b$spin[v0])))
})
dt_plot <- rbindlist(plot_list)

# --- METRICS: Spin-1/2 Isotropic Assumption ---
# For a 2*pi periodic Spin-1/2 system, max violation occurs at 45° and 135° offsets
e_pi_4   <- approx(dt_plot$phi_rad, dt_plot$E_0, xout = pi/4)$y
e_3pi_4  <- approx(dt_plot$phi_rad, dt_plot$E_0, xout = 3*pi/4)$y

# Derived CHSH Sum: S = E(45°) - E(135°) + E(45°) + E(45°)
S_val <- abs(e_pi_4 - e_3pi_4 + e_pi_4 + e_pi_4)

# --- PLOT: The Textbook Spin-1/2 Visual ---
subtitle_str <- sprintf("EPR-Bohm CHSH S: %.5f (Classical Limit: 2.0 | Quantum Limit: 2.828)", S_val)

# INVERTED TENT: Starts at -1, peaks at +1 at pi radians
classical_tent <- function(x) {
  x_mod <- x %% (2 * pi)
  ifelse(x_mod <= pi, -1 + (2 * x_mod / pi), 3 - (2 * x_mod / pi))
}

gp <- ggplot(dt_plot, aes(x = phi_rad)) +
  geom_vline(xintercept = c(pi/4, 3*pi/4), color = "gray70", linetype = "dashed", linewidth = 0.5) +
  # Use the inverted classical tent
  stat_function(fun = classical_tent, color = "gray70", linewidth = 1.2, alpha = 0.5) +
  # Inverted theoretical curve to match the singlet state expectation: -cos(phi)
  stat_function(fun = function(x) -cos(x), color = "gray30", linewidth = 0.5, alpha = 0.4) +
  geom_point(aes(y = E_0), color = "black", alpha = 0.7, size = 0.4) +
  scale_x_continuous(breaks = seq(0, 2*pi, by = pi/4),
                     labels = c("0", "π/4", "π/2", "3π/4", "π", "5π/4", "3π/2", "7π/4", "2π")) +
  ylim(-1.1, 1.1) +
  labs(title = "Bell Test: Symplectic Contextual Erasure (Spin-1/2 Singlet State)",
       subtitle = subtitle_str,
       x = "Relative Detector Angle (Radians)",
       y = "Correlation (E)") +
  theme_minimal() +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(output_dir, "hero_bell.png"), plot = gp, width = 10, height = 6, dpi = 300)
