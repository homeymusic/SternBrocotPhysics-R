here::i_am("data-raw/13_kappa_delta_particle_sweep.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/13_kappa_delta_particle_sweep"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# 1. PARAMETERS FOR THE GRID SEARCH
alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 180, by = 4) + 1e-5
all_angles <- sort(unique(c(alice_fixed, bob_sweep)))

# Reasonable simulation count for a grid sweep
# (Deterministic source is fast, so we can afford 50k-100k)
sim_count <- 5e4

# A. Source Uncertainty (Delta Particle)
# User Hypothesis: Around 0.2 or 0.4
delta_p_values <- c(0.1, 0.2, 0.4, 0.8)

# B. Detector Uncertainty (Kappa)
# User Hypothesis: Around 16pi
# Previous plots showed saturation around 16pi-32pi
kappa_coeffs <- c(8, 16, 32, 64)
kappa_values <- pi * kappa_coeffs

results_list <- list()

# 2. THE GRID SWEEP
cat("--- LAUNCHING GRID SEARCH: DELTA_P vs KAPPA ---\n")

for (d_p in delta_p_values) {
  for (i in seq_along(kappa_values)) {
    k <- kappa_values[i]
    k_coef <- kappa_coeffs[i]

    # Construct a unique ID for this run
    run_id <- sprintf("dp%.1f_k%.0fpi", d_p, k_coef)
    cat(sprintf("\nRunning: Delta_P = %.1f | Kappa = %.0f π\n", d_p, k_coef))

    # A. Run Simulation (Physical Source + Physical Detector)
    SternBrocotPhysics::micro_macro_bell_erasure_sweep(
      angles = all_angles,
      dir = normalizePath(data_dir, mustWork = TRUE),
      count = sim_count,
      kappa = k,               # Detector Squeeze
      delta_particle = d_p,    # Source Quantization
      mu_start = -pi,
      mu_end = pi,
      n_threads = 6
    )

    # B. Calculate Correlation
    f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
    dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found", "erasure_distance"))

    # Optional: Quick check on source quantization?
    # mean_source_cost <- mean(abs(dt_a$erasure_distance))
    # cat(sprintf("  -> Mean Source Cost: %.4f\n", mean_source_cost))

    run_dt_list <- list()

    for (b_ang in bob_sweep) {
      f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
      if (file.exists(file.path(data_dir, f_b))) {
        dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

        valid <- dt_a$found & dt_b$found
        if (any(valid)) {
          # Standard Correlation E = <AB>
          corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
          run_dt_list[[length(run_dt_list) + 1]] <- data.table(
            phi = b_ang - alice_fixed,
            E = corr
          )
        }
      }
    }

    temp_dt <- rbindlist(run_dt_list)

    # C. Compute S-Value
    E_45  <- approx(temp_dt$phi, temp_dt$E, xout = 45)$y
    E_135 <- approx(temp_dt$phi, temp_dt$E, xout = 135)$y
    S_val <- if(!is.na(E_45)) abs(3 * E_45 - E_135) else 0

    # D. Labeling
    label_str <- sprintf("κ=%.0fπ (S=%.2f)", k_coef, S_val)

    temp_dt[, `:=`(
      DeltaP = factor(sprintf("Source Δ = %.1f", d_p)),
      KappaLabel = label_str,
      KappaVal = k_coef,
      S = S_val
    )]

    results_list[[run_id]] <- temp_dt
  }
}

final_dt <- rbindlist(results_list)

# 3. HELPER: CLASSICAL LIMIT
classical_limit <- function(x_deg) {
  x <- x_deg %% 360
  ifelse(x <= 180, -1 + (2 * x / 180), 1 - (2 * (x - 180) / 180))
}

# 4. PLOT: FACET BY SOURCE DELTA
# We want to find the Delta that allows Kappa to hit the target.
gp <- ggplot(final_dt, aes(x = phi, y = E, color = KappaLabel)) +
  # Reference Lines
  stat_function(fun = classical_limit, geom = "area", fill = "grey85", alpha = 0.5) +
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", size = 0.8, linetype = "dashed") +

  geom_line(size = 1) +
  geom_point(size = 1, alpha = 0.6) +

  # Facet by the Source Parameter
  facet_wrap(~DeltaP, ncol = 2) +

  scale_color_viridis_d(option = "turbo", name = "Detector κ") +
  scale_x_continuous(breaks = seq(0, 180, by = 45)) +
  ylim(-1.1, 1.1) +

  labs(
    title = "Grid Search: Tuning the Physical Universe",
    subtitle = "Facets: Source Uncertainty (Δp) | Color: Detector Squeeze (κ)",
    x = "Relative Phase (Degrees)",
    y = "Correlation E"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(size = 12, face = "bold"),
    legend.position = "bottom"
  )

print(gp)

# 5. PRINT SUMMARY TABLE (Top Performers)
cat("\n--- TOP CONFIGURATIONS ---\n")
summary_dt <- unique(final_dt[, .(DeltaP, KappaLabel, S)])
print(summary_dt[order(-S)][1:10])
