# 06_smoke_test_chsh.R
here::i_am("data-raw/06_smoke_test_chsh.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"

# --- 1. CLEAN SLATE PROTOCOL (CRITICAL FIX) ---
# We must wipe previous runs to ensure row-count synchronization.
# If Alice has 1M rows from yesterday and Bob has 1M+1 rows from today,
# the physics correlation breaks immediately.
if (dir.exists(smoke_dir)) {
  message("🧹 Wiping old smoke test data to ensure synchronization...")
  old_files <- list.files(smoke_dir, full.names = TRUE)
  if (length(old_files) > 0) unlink(old_files)
} else {
  dir.create(smoke_dir, recursive = TRUE)
}

# --- 2. PREPARE ANGLES ---
# Granularity Limit: The "pixel size" of the universe.
# Prevents infinite precision (energy) singularities.
granularity <- 1e-5
target_angles <- c(0.0, 45.0, 90.0, 135.0) + granularity

cat("--- GENERATING SMOKE TEST DATA ---\n")
cat("Targets:", paste(target_angles, collapse=", "), "\n")

# --- 3. PREVIEW PHYSICS ---
# Verify we aren't hitting floating point singularities
preview_uncertainty <- function(deg, type) {
  rad <- deg * (pi / 180)
  s <- max(abs(sin(rad)), 1e-15) # Safety clamp
  c <- max(abs(cos(rad)), 1e-15)

  if (type == "Alice (Alpha)") return((cos(rad)^2) / s)
  else return((sin(rad)^2) / c)
}

unc_table <- data.table(
  Observer = c("Alice", "Alice", "Bob", "Bob"),
  Angle = c(0, 90, 45, 135),
  Input = target_angles
)
unc_table[, Type := ifelse(Observer == "Alice", "Alice (Alpha)", "Bob (Beta)")]
unc_table[, Uncertainty := mapply(preview_uncertainty, Input, Type)]
print(unc_table)
cat("\n")

# --- 4. EXECUTE SIMULATION ---
SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = target_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = 1e6 + 1,
  n_threads = 4
)

# --- 5. LOADING & SYNC CHECK ---
load_experiment_data <- function(angle, type) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", type, angle)
  fpath <- file.path(smoke_dir, fname)

  if (!file.exists(fpath)) stop(paste("Missing:", fpath))

  # Load spin, found status, AND microstate (for sync verification)
  fread(fpath, select = c("spin", "found", "microstate"))
}

cat("--- LOADING DATA ---\n")
dt_a_0   <- load_experiment_data(target_angles[1], "alpha") # 0
dt_a_90  <- load_experiment_data(target_angles[3], "alpha") # 90
dt_b_45  <- load_experiment_data(target_angles[2], "beta")  # 45
dt_b_135 <- load_experiment_data(target_angles[4], "beta")  # 135

# CRITICAL SYNC CHECK
# Ensure all files have exactly the same number of rows
row_counts <- c(nrow(dt_a_0), nrow(dt_a_90), nrow(dt_b_45), nrow(dt_b_135))
if (length(unique(row_counts)) > 1) {
  stop("FATAL: Dataset size mismatch! Synchronization lost. Check C++ generator.")
}
message("✅ Synchronization confirmed: All observers have ", row_counts[1], " microstates.")


# --- 6. CALCULATE CORRELATIONS ---
calc_correlation <- function(label, dt_alice, dt_bob) {
  # 1. Intersection Mask (Both detectors fired)
  valid <- !is.na(dt_alice$spin) & dt_alice$found &
    !is.na(dt_bob$spin)   & dt_bob$found

  n_kept <- sum(valid)
  pct <- n_kept / nrow(dt_alice) * 100

  # 2. Diagnostic Print
  cat(sprintf("  Pair %-10s: %6.2f%% valid (%d dropped)\n", label, pct, nrow(dt_alice) - n_kept))

  if (n_kept == 0) return(NA)

  # 3. Correlation
  # Since rows are synced 1:1 by index, we can multiply directly
  mean(dt_alice$spin[valid] * dt_bob$spin[valid])
}

cat("\n--- PAIRWISE RESULTS ---\n")
E_0_45   <- calc_correlation("0-45",   dt_a_0,  dt_b_45)
E_0_135  <- calc_correlation("0-135",  dt_a_0,  dt_b_135)
E_90_45  <- calc_correlation("90-45",  dt_a_90, dt_b_45)
E_90_135 <- calc_correlation("90-135", dt_a_90, dt_b_135)

cat("\n--- CORRELATION MATRIX ---\n")
cat(sprintf("E(0,  45) : %7.4f  (Theory: -0.707)\n", E_0_45))
cat(sprintf("E(0,  135): %7.4f  (Theory: +0.707)\n", E_0_135))
cat(sprintf("E(90, 45) : %7.4f  (Theory: -0.707)\n", E_90_45))
cat(sprintf("E(90, 135): %7.4f  (Theory: -0.707)\n", E_90_135))

# --- 7. CHSH STATISTIC ---
S_stat <- abs(E_0_45 - E_0_135) + abs(E_90_45 + E_90_135)

cat("\n--- FINAL RESULT ---\n")
cat(sprintf("S_stat = %.4f\n", S_stat))
cat("Classical Limit: 2.0000\n")
cat("Quantum Limit:   2.8284\n")

if (!is.na(S_stat) && S_stat > 2.0) {
  cat("\n🎉 [PASS] VIOLATION CONFIRMED!\n")
} else {
  cat("\n❌ [FAIL] CLASSICAL RESULT.\n")
}

# --- 8. PLOTTING ---
# (Visualization code remains the same as previous)
cat("\n--- GENERATING PLOTS ---\n")
# ... [Insert Plotting Code Here if desired] ...
