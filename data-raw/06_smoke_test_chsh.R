# 06_smoke_test_chsh.R
here::i_am("data-raw/06_smoke_test_chsh.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"

if (!dir.exists(smoke_dir)) {
  dir.create(smoke_dir, recursive = TRUE)
}

# --- 1. PREPARE ANGLES (THE GRANULARITY LIMIT) ---
# We apply a fundamental limit to angular precision.
# 1. PHYSICAL: A finite universe cannot store infinite information (exact 0.0).
#    Space-time is treated as having a "grain" or minimum resolution.
# 2. OPERATIONAL: We offset singularities by this grain to ensure
#    a valid thermodynamic erasure event occurs.

granularity <- 1e-5

# Standard Spin 1/2 Bell Test Angles (0, 45, 90, 135)
# We apply the granularity offset to every target.
target_angles <- c(0.0, 45.0, 90.0, 135.0) + granularity

cat("--- GENERATING SMOKE TEST DATA (SPIN 1/2) ---\n")
cat("Targets (with granularity offset):", paste(target_angles, collapse=", "), "\n")

# --- 1.1 PREVIEW UNCERTAINTIES ---
# Calculate expected uncertainty based on the granularity
preview_uncertainty <- function(deg, type) {
  rad <- deg * (pi / 180)
  s <- abs(sin(rad))
  c <- abs(cos(rad))

  # Clamp to the granularity limit for safety
  if (s < 1e-15) s <- 1e-15
  if (c < 1e-15) c <- 1e-15

  if (type == "Alice (Alpha)") {
    # Alpha = cos^2 / sin
    return((cos(rad)^2) / s)
  } else {
    # Beta = sin^2 / cos
    return((sin(rad)^2) / c)
  }
}

cat("\n--- PREDICTED PHYSICS PARAMETERS ---\n")
unc_table <- data.table(
  Observer = c("Alice", "Alice", "Bob", "Bob"),
  Angle_Deg = c(0.0, 90.0, 45.0, 135.0),
  Actual_Input = c(0.0, 90.0, 45.0, 135.0) + granularity
)
unc_table[, Type := ifelse(Observer == "Alice", "Alice (Alpha)", "Bob (Beta)")]
unc_table[, Uncertainty := mapply(preview_uncertainty, Actual_Input, Type)]

print(unc_table)
cat("------------------------------------\n\n")

# --- 2. EXECUTE SIMULATION ---
SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = target_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = 1e6 + 1,
  n_threads = 4
)

# --- 3. HELPER: LOAD EXPERIMENT DATA ---
load_experiment_data <- function(angle, type) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", type, angle)
  fpath <- file.path(smoke_dir, fname)

  if (!file.exists(fpath)) stop(paste("Missing generated file:", fpath))

  # Load both 'spin' and 'found'
  dt <- fread(fpath, select = c("spin", "found"))
  return(dt)
}

# --- 4. LOAD INDEPENDENT OBSERVATIONS ---
cat("\n--- LOADING OBSERVER DATA ---\n")

# Alice (0 vs 90)
dt_a_0  <- load_experiment_data(0.0 + granularity,  "alpha")
dt_a_90 <- load_experiment_data(90.0 + granularity, "alpha")

# Bob (45 vs 135)
dt_b_45  <- load_experiment_data(45.0 + granularity,  "beta")
dt_b_135 <- load_experiment_data(135.0 + granularity, "beta")

# --- 5. CALCULATE CORRELATIONS ---
calc_correlation <- function(dt_alice, dt_bob) {
  # Validity Mask: Intersection of successful measurements
  valid_indices <- !is.na(dt_alice$spin) & dt_alice$found == TRUE &
    !is.na(dt_bob$spin)   & dt_bob$found == TRUE

  if (sum(valid_indices) == 0) return(NA)

  # Correlation = Mean(SpinA * SpinB)
  mean(dt_alice$spin[valid_indices] * dt_bob$spin[valid_indices])
}

cat("\n--- CALCULATING PAIRWISE CORRELATIONS ---\n")

E_0_45   <- calc_correlation(dt_a_0,  dt_b_45)
E_0_135  <- calc_correlation(dt_a_0,  dt_b_135)
E_90_45  <- calc_correlation(dt_a_90, dt_b_45)
E_90_135 <- calc_correlation(dt_a_90, dt_b_135)

cat("\n--- CORRELATION MATRIX ---\n")
cat(sprintf("E(a~0,  b~45):  %7.4f  (Theory: -0.7071)\n", E_0_45))
cat(sprintf("E(a~0,  b~135): %7.4f  (Theory: +0.7071)\n", E_0_135))
cat(sprintf("E(a~90, b~45):  %7.4f  (Theory: -0.7071)\n", E_90_45))
cat(sprintf("E(a~90, b~135): %7.4f  (Theory: -0.7071)\n", E_90_135))

# --- 6. CHSH STATISTIC ---
S_stat <- abs(E_0_45 - E_0_135) + abs(E_90_45 + E_90_135)

cat("\n--- CHSH VIOLATION RESULTS ---\n")
cat(sprintf("S_stat = %.4f\n", S_stat))
cat("Local Realism Bound:  2.0000\n")
cat("Quantum Bound (2sqrt2): 2.8284\n")

if (!is.na(S_stat) && S_stat > 2.0) {
  cat("\n[PASS] VIOLATION CONFIRMED. The Normalized Action Model violates Bell's Inequalities.\n")
} else {
  cat("\n[FAIL] NO VIOLATION. The system is behaving classically.\n")
}

# --- 7. VISUALIZATION ---
cat("\n--- GENERATING PLOTS ---\n")

load_plot_data <- function(angle, type, label) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", type, angle)
  fpath <- file.path(smoke_dir, fname)
  dt <- fread(fpath, select = c("microstate", "erasure_distance"))
  dt <- dt[!is.na(erasure_distance)]
  if (nrow(dt) > 10000) dt <- dt[seq(1, nrow(dt), length.out = 10000)]
  dt[, Label := label]
  return(dt)
}

plot_data <- rbind(
  load_plot_data(0.0 + granularity,   "alpha", "Alice (0°)"),
  load_plot_data(90.0 + granularity,  "alpha", "Alice (90°)"),
  load_plot_data(45.0 + granularity,  "beta",  "Bob (45°)"),
  load_plot_data(135.0 + granularity, "beta",  "Bob (135°)")
)

gp <- ggplot(plot_data, aes(x = microstate, y = erasure_distance)) +
  geom_point(size = 0.2, alpha = 0.8, color = "#2c3e50") +
  facet_wrap(~Label, ncol = 2, scales = "free_y") +
  labs(
    title = "The Geometry of Erasure (Spin 1/2)",
    subtitle = "Erasure Distance vs Microstate",
    x = "Microstate (theta_mu)",
    y = "Erasure Distance (epsilon)"
  ) +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold", size = 12))

print(gp)
