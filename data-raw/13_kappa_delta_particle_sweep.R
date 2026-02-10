library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "data_raw/13_kappa_delta_particle_sweep"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# 1. PARAMETERS FOR THE GRID SEARCH
alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 180, by = 4) + 1e-5
all_angles <- sort(unique(c(alice_fixed, bob_sweep)))

sim_count <- 5e4

# UPDATED TUNING RANGES
# PRECISION SWEEP
# We are looking for the "Goldilocks" zone between 1.1 and 1.2
# My prediction: The point where RMSE is lowest will also be where S ~= 2.82
delta_p_values <- c(1.12, 1.14, 1.16, 1.18)

# CLEAN DETECTORS ONLY
# We discard 2pi and 4pi because they are too "noisy/sloppy" to see the real physics.
kappa_coeffs   <- c(8, 12, 16, 32)
kappa_values   <- pi * kappa_coeffs

results_list <- list()

# 2. THE GRID SWEEP
cat("--- LAUNCHING GRID SEARCH: DELTA_P vs KAPPA ---\n")

for (d_p in delta_p_values) {
  for (i in seq_along(kappa_values)) {
    k <- kappa_values[i]
    k_coef <- kappa_coeffs[i]

    # Unique ID
    run_id <- sprintf("dp%.1f_k%.0fpi", d_p, k_coef)
    cat(sprintf("\nRunning: Delta_P = %.1f | Kappa = %.0f π\n", d_p, k_coef))

    # A. Run Simulation
    SternBrocotPhysics::micro_macro_bell_erasure_sweep(
      angles = all_angles,
      dir = normalizePath(data_dir, mustWork = TRUE),
      count = sim_count,
      kappa = k,
      delta_particle = d_p,
      mu_start = -pi,
      mu_end = pi,
      n_threads = 6
    )

    # B. Calculate Correlation
    f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
    dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

    run_dt_list <- list()

    for (b_ang in bob_sweep) {
      f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
      if (file.exists(file.path(data_dir, f_b))) {
        dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

        valid <- dt_a$found & dt_b$found
        if (any(valid)) {
          # E = <AB>
          corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))

          # Calculate Residual against Quantum Prediction (-cos(theta))
          # Theta is converted to radians for the cos function
          rads <- (b_ang - alice_fixed) * pi / 180
          q_pred <- -cos(rads)
          resid_sq <- (corr - q_pred)^2

          run_dt_list[[length(run_dt_list) + 1]] <- data.table(
            phi = b_ang - alice_fixed,
            E = corr,
            ResSq = resid_sq
          )
        }
      }
    }

    temp_dt <- rbindlist(run_dt_list)

    # C. Compute S-Value & Fit Metric
    E_45  <- approx(temp_dt$phi, temp_dt$E, xout = 45)$y
    E_135 <- approx(temp_dt$phi, temp_dt$E, xout = 135)$y
    S_val <- if(!is.na(E_45)) abs(3 * E_45 - E_135) else 0

    # RMSE (Root Mean Square Error) from Cosine
    rmse_val <- sqrt(mean(temp_dt$ResSq, na.rm=TRUE))

    label_str <- sprintf("κ=%.0fπ (S=%.2f)", k_coef, S_val)

    temp_dt[, `:=`(
      DeltaP = factor(sprintf("Source Δ = %.1f", d_p)),
      KappaLabel = label_str,
      KappaVal = k_coef,
      S = S_val,
      RMSE = rmse_val
    )]

    results_list[[run_id]] <- temp_dt
  }
}

final_dt <- rbindlist(results_list)

# 3. HELPER: CLASSICAL LIMIT LINE
classical_limit <- function(x_deg) {
  x <- x_deg %% 360
  ifelse(x <= 180, -1 + (2 * x / 180), 1 - (2 * (x - 180) / 180))
}

# 4. PLOT
gp <- ggplot(final_dt, aes(x = phi, y = E, color = KappaLabel)) +

  # Classical Limit (Red Line)
  stat_function(fun = classical_limit, color = "firebrick", linetype = "solid", size = 0.6, alpha=0.6) +

  # Quantum Prediction (Black Dashed)
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", size = 0.8, linetype = "dashed") +

  # Simulation Data
  geom_line(size = 1) +

  facet_wrap(~DeltaP, ncol = 2) +

  scale_color_viridis_d(option = "turbo", name = "Detector κ") +
  scale_x_continuous(breaks = seq(0, 180, by = 45)) +
  ylim(-1.05, 1.05) +

  labs(
    title = "Grid Search: Tuning the Physical Universe",
    subtitle = "Black Dashed: Quantum (-cos) | Red Line: Classical Limit",
    x = "Relative Phase (Degrees)",
    y = "Correlation E"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 12, face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

print(gp)

# 5. PRINT SUMMARY TABLE (Sorted by Fit to Cosine)
# Lower RMSE = Better fit to Quantum Mechanics
cat("\n--- TOP CONFIGURATIONS (Sorted by Fit to Quantum Cosine) ---\n")
summary_dt <- unique(final_dt[, .(DeltaP, KappaLabel, S, RMSE)])
print(summary_dt[order(RMSE)][1:10])
