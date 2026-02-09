here::i_am("data-raw/09_delta_factor.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/09_delta_factor"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# 1. PARAMETERS FOR THE SWEEP
alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 180, by = 4) + 1e-5
all_angles <- sort(unique(c(alice_fixed, bob_sweep)))

# Reduced microstate resolution for rapid prototyping
mu_count <- 1e5
mu_start <- -pi
mu_end <- pi

# Kappa: The requested spectrum from Fine Structure (pi/32) to Extreme Locking (8pi)
# We calculate them explicitly but keep the coefficients for nice labeling later
kappa_coeffs <- c(1/32, 1/4, 1/2, 3/4, 1:8)
kappa <- pi * kappa_coeffs

# Storage for results and legend ordering
all_results <- list()
legend_levels <- c()

# 2. THE SWEEP LOOP
for (i in seq_along(kappa)) {
  k <- kappa[i]
  k_coef <- kappa_coeffs[i]

  cat(sprintf("\n--- TESTING KAPPA = %.3f (Coefficient: %.2f) ---\n", k, k_coef))

  # A. Run Simulation
  SternBrocotPhysics::micro_macro_bell_erasure_sweep(
    angles = all_angles,
    dir = normalizePath(data_dir, mustWork = TRUE),
    count = mu_count,
    kappa = k,
    mu_start = mu_start,
    mu_end = mu_end,
    n_threads = 6
  )

  # B. Calculate Correlation E(phi)
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
  dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

  run_dt_list <- list()

  for (b_ang in bob_sweep) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    if (file.exists(file.path(data_dir, f_b))) {
      dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

      valid <- dt_a$found & dt_b$found
      if (any(valid)) {
        corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
        run_dt_list[[length(run_dt_list) + 1]] <- data.table(
          phi = b_ang - alice_fixed,
          E = corr
        )
      }
    }
  }

  temp_dt <- rbindlist(run_dt_list)

  # C. Compute CHSH S-Value for Legend
  # We interpolate E at exactly 45 and 135 degrees since our sweep is by 4s
  E_45  <- approx(temp_dt$phi, temp_dt$E, xout = 45)$y
  E_135 <- approx(temp_dt$phi, temp_dt$E, xout = 135)$y

  # S = |3*E(45) - E(135)| assuming Rotational Invariance
  # If E(45) is negative and E(135) is positive (Bell curve), this sums magnitudes.
  if(!is.na(E_45) && !is.na(E_135)) {
    S_val <- abs(3 * E_45 - E_135)
  } else {
    S_val <- 0
  }

  # D. Create "Pi-Based" Legend Label
  # E.g., "π/4 (2.10)" or "3π (2.65)"
  if (abs(k_coef - 1/32) < 1e-9) pi_str <- "π/32"
  else if (abs(k_coef - 1/4) < 1e-9) pi_str <- "π/4"
  else if (abs(k_coef - 1/2) < 1e-9) pi_str <- "π/2"
  else if (abs(k_coef - 3/4) < 1e-9) pi_str <- "3π/4"
  else if (abs(k_coef - 1) < 1e-9) pi_str <- "π"
  else pi_str <- sprintf("%dπ", as.integer(k_coef))

  label_str <- sprintf("%s (%.2f)", pi_str, S_val)
  legend_levels <- c(legend_levels, label_str) # Store for factor ordering

  # Assign label to data
  temp_dt[, LegendLabel := label_str]
  all_results[[as.character(i)]] <- temp_dt
}

final_dt <- rbindlist(all_results)
# Enforce Legend Order (Small Kappa to Large Kappa)
final_dt[, LegendLabel := factor(LegendLabel, levels = legend_levels)]

# 3. HELPER: CLASSICAL LIMIT (Triangle Wave)
classical_limit <- function(x_deg) {
  x <- x_deg %% 360
  ifelse(x <= 180, -1 + (2 * x / 180), 1 - (2 * (x - 180) / 180))
}

# 4. RENDER THE COMPARISON PLOT
gp <- ggplot(final_dt, aes(x = phi, y = E, color = LegendLabel)) +

  # A. BACKGROUND LIMITS
  stat_function(fun = classical_limit, geom = "area", fill = "grey85", alpha = 0.5) +
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", size = 0.8, linetype = "dashed") +

  # B. DATA LINES
  geom_line(size = 1, alpha = 0.9) +
  geom_point(size = 1.2) +

  # C. MARKERS
  geom_vline(xintercept = 45, linetype = "dotted", alpha = 0.5) +
  annotate("text", x = 45, y = -0.95, label = "45°", size = 3, color = "black") +

  # D. SCALES & THEME
  # Using a spectral palette to distinguish the many lines
  scale_color_viridis_d(option = "plasma", end = 0.9, direction = -1) +
  scale_x_continuous(breaks = seq(0, 180, by = 45)) +
  ylim(-1.1, 1.1) +

  labs(
    title = "Emergence of Bell Violation",
    subtitle = "Legend: Kappa (CHSH S-Value) | Grey: Classical Limit (S=2) | Dashed: Quantum Target (S=2.82)",
    x = "Relative Phase (Degrees)",
    y = "Correlation E",
    color = "κ (S)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.text = element_text(size = 10),
    panel.grid.minor = element_blank()
  )

print(gp)
