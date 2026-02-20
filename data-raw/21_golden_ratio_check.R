library(data.table)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory     <- file.path(base_data_dir_4TB, "21_golden_ratio_check")
if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 1. CRITICAL CONSTANTS
PHI <- (1 + sqrt(5)) / 2  # The Golden Ratio (~1.618034)
INV_PHI <- 1 / PHI        # The Inverse Phi (~0.618034)

# 2. TEST CANDIDATES
# A: The Golden Ratio Exact
# B: The "Smooth" region projected from your last run (0.75 - 0.78)
delta_p_values <- sort(c(INV_PHI, seq(0.75, 0.78, by=0.005)))

FIXED_KAPPA <- 4 / pi
sim_count   <- 1e5    # High resolution for the final verdict
target_angles <- c(0, 45, 90, 135, 180) + 1e-5

cat("--- THE GOLDEN RATIO TEST ---\n")
cat(sprintf("Testing Golden Ratio Delta: %.6f (1/φ)\n", INV_PHI))
cat(sprintf("Testing Smooth Region:      0.750 -> 0.780\n"))

results_list <- list()

for (d_p in delta_p_values) {

  cat(sprintf("\nRunning Delta = %.6f...", d_p))

  # Run
  micro_macro_bell_erasure_sweep(
    angles = target_angles,
    dir = normalizePath(raw_directory, mustWork = TRUE),
    count = sim_count,
    kappa = FIXED_KAPPA,
    delta_particle = d_p,
    mu_start = -pi,
    mu_end = pi,
    n_threads = 6
  )

  # Load Alice
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", target_angles[1])
  dt_a <- fread(file.path(raw_directory, f_a), select=c("spin", "found"))

  # Get correlations
  get_E <- function(idx) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", target_angles[idx])
    if (file.exists(file.path(raw_directory, f_b))) {
      dt_b <- fread(file.path(raw_directory, f_b), select=c("spin", "found"))
      valid <- dt_a$found & dt_b$found
      if (any(valid)) return(mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid])))
    }
    return(0)
  }

  E_45  <- get_E(2)
  E_135 <- get_E(4)

  S_val <- abs(3 * E_45 - E_135)
  dist  <- abs(S_val - 2.828427)

  results_list[[length(results_list) + 1]] <- data.table(
    Label = if(abs(d_p - INV_PHI) < 1e-5) "GOLDEN_RATIO" else "Smooth_Candidate",
    Delta = d_p,
    S = S_val,
    Dist_to_Tsirelson = dist
  )

  cat(sprintf(" S = %.5f", S_val))
}

final_dt <- rbindlist(results_list)

cat("\n\n--- VERDICT ---\n")
print(final_dt[order(Dist_to_Tsirelson)])
