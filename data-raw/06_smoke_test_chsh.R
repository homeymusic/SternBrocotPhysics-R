# 06_smoke_test_chsh.R
here::i_am("data-raw/06_smoke_test_chsh.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
# Use a dedicated smoke test directory to avoid polluting the main scan
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"

if (!dir.exists(smoke_dir)) {
  dir.create(smoke_dir, recursive = TRUE)
}

# --- 1. GENERATE REQUIRED DATA ---
# We need specific angles for the CHSH inequality:
# Alice: 0, 45
# Bob:   22.5, 67.5
target_angles <- c(0.0, 22.5, 45.0, 67.5)

cat("--- GENERATING SMOKE TEST DATA ---\n")
# This creates BOTH Alpha and Beta files for all 4 angles.
# We will pick and choose the ones we need for the CHSH pairing.
SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = target_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = 1e6 + 1,  # High statistics for precision
  n_threads = 4
)

# --- 2. HELPER: LOAD EXACT FILE ---
load_spin_exact <- function(angle, type) {
  # Format matches C++: micro_macro_erasures_type_000000.000000.csv.gz
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", type, angle)
  fpath <- file.path(smoke_dir, fname)

  if (!file.exists(fpath)) stop(paste("Missing generated file:", fpath))

  # Only read the spin column
  fread(fpath, select = "spin")[["spin"]]
}

# --- 3. LOAD INDEPENDENT OBSERVATIONS ---
cat("\n--- LOADING OBSERVER DATA ---\n")

# Alice's Detectors (Type = Alpha)
a_0  <- load_spin_exact(0.0,  "alpha")
a_45 <- load_spin_exact(45.0, "alpha")

# Bob's Detectors (Type = Beta)
b_22 <- load_spin_exact(22.5, "beta")
b_67 <- load_spin_exact(67.5, "beta")

# --- 4. CALCULATE CORRELATIONS ---
# E(a, b) = Mean(Alice_Spin * Bob_Spin)
# Rows are synchronized by the shared microstate mu.

E_0_22  <- mean(a_0  * b_22) # Diff = 22.5 deg
E_0_67  <- mean(a_0  * b_67) # Diff = 67.5 deg
E_45_22 <- mean(a_45 * b_22) # Diff = 22.5 deg
E_45_67 <- mean(a_45 * b_67) # Diff = 22.5 deg (abs diff)

cat("\n--- CORRELATION MATRIX ---\n")
cat(sprintf("E(a=0,  b=22.5) [d=22.5]: %7.4f  (Theory: -0.9239)\n", E_0_22))
cat(sprintf("E(a=0,  b=67.5) [d=67.5]: %7.4f  (Theory: -0.3827)\n", E_0_67))
cat(sprintf("E(a=45, b=22.5) [d=22.5]: %7.4f  (Theory: -0.9239)\n", E_45_22))
cat(sprintf("E(a=45, b=67.5) [d=22.5]: %7.4f  (Theory: -0.9239)\n", E_45_67))

# --- 5. CHSH STATISTIC ---
# S = | E(a,b) - E(a,b') | + | E(a',b) + E(a',b') |
# We organize terms to maximize the violation check (Standard CHSH form)
# S = | E_0_22 - E_0_67 | + | E_45_22 + E_45_67 |

S_stat <- abs(E_0_22 - E_0_67) + abs(E_45_22 + E_45_67)

cat("\n--- CHSH VIOLATION RESULTS ---\n")
cat(sprintf("S_stat = %.4f\n", S_stat))
cat("Local Realism Bound:  2.0000\n")
cat("Quantum Bound (2sqrt2): 2.8284\n")

if (S_stat > 2.0) {
  cat("\n[PASS] VIOLATION CONFIRMED. The Normalized Action Model violates Bell's Inequalities.\n")
} else {
  cat("\n[FAIL] NO VIOLATION. The system is behaving classically.\n")
}

# --- 6. VISUALIZATION ---
df_plot <- data.table(
  pair = c("0-22.5", "0-67.5", "45-22.5", "45-67.5"),
  delta_phi = c(22.5, 67.5, 22.5, 22.5),
  correlation = c(E_0_22, E_0_67, E_45_22, E_45_67)
)

print(df_plot)
