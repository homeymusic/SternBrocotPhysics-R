here::i_am("data-raw/12_weighted_kappa_sweep.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
# We use the EXISTING data from the 09 sweep
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/09_delta_factor"
if (!dir.exists(data_dir)) stop("Data dir not found! Please run 09_delta_factor.R first.")

# We sweep the SAME kappas, but now we apply the "Gaussian Source" logic
# We define a fixed 'Beta' (Temperature) for the vacuum weights.
# beta = 1.0 is a standard exponential decay: Weight = exp(-1.0 * total_error)
vacuum_beta <- 1.0

alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 180, by = 4) + 1e-5

# We need to reconstruct the list of kappas from the file names or just use the known list
# Let's use the known list from file 09 to be safe
kappa_coeffs <- c(1/32, 1/4, 1/2, 3/4, 1:8)
kappa_values <- pi * kappa_coeffs

# Storage
results_list <- list()

# 1. THE RE-ANALYSIS LOOP
cat(sprintf("--- RE-ANALYZING KAPPA SWEEP WITH WEIGHTED VACUUM (Beta=%.1f) ---\n", vacuum_beta))

for (i in seq_along(kappa_values)) {
  k <- kappa_values[i]
  k_coef <- kappa_coeffs[i]

  # Check if files exist for this kappa (in case 09 was interrupted)
  # We check Alice's file as a proxy
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
  # NOTE: 09 overwrote files, so we might only have the LAST kappa if not saved separately.
  # WAIT! File 09 overwrote the data_dir for each kappa!
  # If you ran 09 as written, it DELETED the old files each loop.
  # WE NEED TO RE-GENERATE.
}

# --- CORRECTION: RE-GENERATION REQUIRED ---
# Since 09 logic was "overwrite to save space", we must regenerate the data
# to sweep multiple kappas again.

# Let's reduce the count slightly to make it fast
rows_to_sweep <- 5e4

cat("--- RE-GENERATING DATA (Optimized for Speed) ---\n")

for (i in seq_along(kappa_values)) {
  k <- kappa_values[i]
  k_coef <- kappa_coeffs[i]

  cat(sprintf("\nProcessing Kappa = %.2f (%.2f pi)...\n", k, k_coef))

  # A. Generate
  SternBrocotPhysics::micro_macro_bell_erasure_sweep(
    angles = sort(unique(c(alice_fixed, bob_sweep))),
    dir = normalizePath(data_dir, mustWork = TRUE),
    count = rows_to_sweep,
    kappa = k,
    mu_start = -pi, mu_end = pi,
    n_threads = 6
  )

  # B. Load & Analyze Immediately
  dt_a <- fread(file.path(data_dir, f_a))

  run_dt_list <- list()

  for (b_ang in bob_sweep) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    if (file.exists(file.path(data_dir, f_b))) {
      dt_b <- fread(file.path(data_dir, f_b))

      valid <- dt_a$found & dt_b$found
      if (any(valid)) {
        sA <- as.numeric(dt_a$spin[valid])
        sB <- as.numeric(dt_b$spin[valid])

        # THE FIX: Apply Weights
        cost <- abs(dt_a$erasure_distance[valid]) + abs(dt_b$erasure_distance[valid])
        w <- exp(-vacuum_beta * cost)

        # Weighted Mean
        E_w <- sum(sA * sB * w) / sum(w)

        run_dt_list[[length(run_dt_list) + 1]] <- data.table(
          phi = b_ang - alice_fixed,
          E = E_w
        )
      }
    }
  }

  temp_dt <- rbindlist(run_dt_list)

  # C. Legend Label
  if (abs(k_coef - 1/32) < 1e-9) pi_str <- "π/32"
  else if (abs(k_coef - 1) < 1e-9) pi_str <- "π"
  else pi_str <- sprintf("%.2fπ", k_coef)

  # Calc S-value for label
  E_45  <- approx(temp_dt$phi, temp_dt$E, xout = 45)$y
  E_135 <- approx(temp_dt$phi, temp_dt$E, xout = 135)$y
  S_val <- abs(3 * E_45 - E_135)

  temp_dt[, LegendLabel := sprintf("%s (S=%.2f)", pi_str, S_val)]
  results_list[[as.character(i)]] <- temp_dt
}

final_dt <- rbindlist(results_list)

# 2. PLOT
gp <- ggplot(final_dt, aes(x = phi, y = E, color = LegendLabel)) +
  # Limits
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", linetype = "dashed") +
  stat_function(fun = function(x_deg) {
    x <- x_deg %% 360
    ifelse(x <= 180, -1 + (2 * x / 180), 1 - (2 * (x - 180) / 180))
  }, geom = "area", fill = "grey85", alpha = 0.5) +

  geom_line(size = 1) +
  geom_point(size = 1) +

  scale_color_viridis_d(option = "turbo", name = "Kappa (Weighted)") +
  scale_x_continuous(breaks = seq(0, 180, by = 45)) +
  labs(
    title = "Weighted Vacuum Sweep",
    subtitle = sprintf("Vacuum Temp Beta = %.1f | Does ANY Kappa produce a Cosine?", vacuum_beta),
    x = "Relative Phase",
    y = "Correlation E"
  ) +
  theme_minimal()

print(gp)
