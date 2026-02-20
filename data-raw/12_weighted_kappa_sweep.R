here::i_am("data-raw/12_weighted_kappa_sweep.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/09_delta_factor"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# 1. PARAMETERS
# Vacuum Weighting: beta = 1.0 is standard exponential decay
vacuum_beta <- 1.0

alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 180, by = 4) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))

# Row count (Reduced for speed since we are re-generating)
rows_to_sweep <- 5e4

# --- KAPPA SELECTION ---
# Select the powers of 2 you want to sweep
selected_powers <- 0:7

# Generate and sort coefficients
kappa_coeffs <- sort(2^selected_powers)
kappa_values <- pi * kappa_coeffs

# --- HELPER: SMART LABELING ---
get_pi_label <- function(k) {
  if (abs(k - round(k)) < 1e-9) {
    if (round(k) == 1) return("π")
    return(sprintf("%.0fπ", k))
  }
  denom <- 1 / k
  if (abs(denom - round(denom)) < 1e-9) {
    return(sprintf("π/%.0f", denom))
  }
  return(sprintf("%.2fπ", k))
}

# Storage
results_list  <- list()
legend_levels <- c()

cat(sprintf("--- RE-ANALYZING KAPPA SWEEP WITH WEIGHTED VACUUM (Beta=%.1f) ---\n", vacuum_beta))

# 2. THE SWEEP & ANALYSIS LOOP
for (i in seq_along(kappa_values)) {
  k      <- kappa_values[i]
  k_coef <- kappa_coeffs[i]

  cat(sprintf("\n--- PROCESSING KAPPA = %.3f (Coefficient: %.4f) ---\n", k, k_coef))

  # A. RE-GENERATE DATA (Required as files are overwritten)
  micro_macro_bell_erasure_sweep(
    angles    = all_angles,
    dir       = normalizePath(data_dir, mustWork = TRUE),
    count     = rows_to_sweep,
    kappa     = k,
    mu_start  = -pi,
    mu_end    = pi,
    n_threads = 6
  )

  # B. LOAD ALICE
  f_a  <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
  dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found", "erasure_distance"))

  run_dt_list <- list()

  # C. LOAD BOB & CALCULATE WEIGHTED CORRELATION
  for (b_ang in bob_sweep) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    if (file.exists(file.path(data_dir, f_b))) {
      dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found", "erasure_distance"))

      valid <- dt_a$found & dt_b$found
      if (any(valid)) {
        sA <- as.numeric(dt_a$spin[valid])
        sB <- as.numeric(dt_b$spin[valid])

        # WEIGHTING LOGIC: Total Erasure Cost
        cost <- abs(dt_a$erasure_distance[valid]) + abs(dt_b$erasure_distance[valid])
        w    <- exp(-vacuum_beta * cost)

        # Weighted Mean Correlation
        # If weights are all effectively zero, handle gracefully
        if (sum(w) > 0) {
          E_w <- sum(sA * sB * w) / sum(w)
        } else {
          E_w <- 0
        }

        run_dt_list[[length(run_dt_list) + 1]] <- data.table(
          phi = b_ang - alice_fixed,
          E   = E_w
        )
      }
    }
  }

  temp_dt <- rbindlist(run_dt_list)

  # D. COMPUTE S-VALUE (Interpolated)
  if (nrow(temp_dt) > 0) {
    E_45  <- approx(temp_dt$phi, temp_dt$E, xout = 45)$y
    E_135 <- approx(temp_dt$phi, temp_dt$E, xout = 135)$y

    if(!is.na(E_45) && !is.na(E_135)) {
      S_val <- abs(3 * E_45 - E_135)
    } else {
      S_val <- 0
    }
  } else {
    S_val <- 0
  }

  # E. CREATE LEGEND LABEL
  pi_str    <- get_pi_label(k_coef)
  label_str <- sprintf("%s (S=%.2f)", pi_str, S_val)

  legend_levels <- c(legend_levels, label_str) # Store order
  temp_dt[, LegendLabel := label_str]

  results_list[[as.character(i)]] <- temp_dt
}

final_dt <- rbindlist(results_list)

# Enforce Legend Order (Small Kappa to Large Kappa)
final_dt[, LegendLabel := factor(LegendLabel, levels = legend_levels)]

# 3. RENDER PLOT
# Helper for Classical Limit
classical_limit <- function(x_deg) {
  x <- x_deg %% 360
  ifelse(x <= 180, -1 + (2 * x / 180), 1 - (2 * (x - 180) / 180))
}

gp <- ggplot(final_dt, aes(x = phi, y = E, color = LegendLabel)) +

  # A. BACKGROUND LIMITS
  stat_function(fun = classical_limit, geom = "area", fill = "grey85", alpha = 0.5) +
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", size = 0.8, linetype = "dashed") +

  # B. DATA
  geom_line(size = 1, alpha = 0.9) +
  geom_point(size = 1.2) +

  # C. MARKERS
  geom_vline(xintercept = 45, linetype = "dotted", alpha = 0.5) +
  annotate("text", x = 45, y = -0.95, label = "45°", size = 3, color = "black") +

  # D. SCALES & THEME
  scale_color_viridis_d(option = "plasma", end = 0.9, direction = -1) +
  scale_x_continuous(breaks = seq(0, 180, by = 45)) +
  ylim(-1.1, 1.1) +

  labs(
    title    = "Weighted Vacuum Sweep",
    subtitle = sprintf("Vacuum Temp Beta = %.1f | Legend: Kappa (CHSH S)", vacuum_beta),
    x        = "Relative Phase (Degrees)",
    y        = "Correlation E (Weighted)",
    color    = "κ (S)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.text     = element_text(size = 10),
    panel.grid.minor = element_blank()
  )

print(gp)
