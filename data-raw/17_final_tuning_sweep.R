library(data.table)
library(SternBrocotPhysics)
library(foreach)
library(doParallel)

# --- CONFIGURATION ---
# 1. DIRECTORY SETUP (4TB External Drive)
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory     <- file.path(base_data_dir_4TB, "17_final_tuning_sweep")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 2. FIXED PARAMETERS
FIXED_KAPPA <- 8 * pi
sim_count   <- 5e4

# 3. THE FINE GRAIN SWEEP
# Range: 1.101 to 1.201 in steps of 0.001
delta_p_values <- seq(1.101, 1.201, by = 0.001)

# Angles
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 180, by = 4) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))

# 4. PARALLEL SETUP
num_cores <- parallel::detectCores(logical = FALSE) - 1
cl <- makeCluster(num_cores)
registerDoParallel(cl)

cat(sprintf("--- LAUNCHING PARALLEL SWEEP ON %d CORES ---\n", num_cores))
cat(sprintf("Saving Raw Data to: %s\n", raw_directory))

# 5. EXECUTION LOOP
final_dt <- foreach(d_p = delta_p_values, .combine = rbind, .packages = c("data.table", "SternBrocotPhysics")) %dopar% {

  # A. Create Unique Directory for this Thread
  run_dir <- file.path(raw_directory, sprintf("run_dp_%.3f", d_p))
  if (!dir.exists(run_dir)) dir.create(run_dir)

  # B. Run Simulation
  # Note: n_threads=1 because we are parallelizing at the R level
  micro_macro_bell_erasure_sweep(
    angles = all_angles,
    dir = normalizePath(run_dir, mustWork = TRUE),
    count = sim_count,
    kappa = FIXED_KAPPA,
    delta_particle = d_p,
    mu_start = -pi,
    mu_end = pi,
    n_threads = 1
  )

  # C. Process Data
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
  dt_a <- fread(file.path(run_dir, f_a), select = c("spin", "found"))

  run_stats <- list()

  for (b_ang in bob_sweep) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    if (file.exists(file.path(run_dir, f_b))) {
      dt_b <- fread(file.path(run_dir, f_b), select = c("spin", "found"))

      valid <- dt_a$found & dt_b$found
      if (any(valid)) {
        corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))

        # Residual from Quantum Cosine
        rads <- (b_ang - alice_fixed) * pi / 180
        resid_sq <- (corr - (-cos(rads)))^2

        run_stats[[length(run_stats) + 1]] <- data.table(
          phi = b_ang - alice_fixed,
          E = corr,
          ResSq = resid_sq
        )
      }
    }
  }

  # D. Compute Metrics & Return Row
  dt_res <- rbindlist(run_stats)

  if (nrow(dt_res) > 0) {
    E_45  <- approx(dt_res$phi, dt_res$E, xout = 45)$y
    E_135 <- approx(dt_res$phi, dt_res$E, xout = 135)$y
    S_val <- if(!is.na(E_45) && !is.na(E_135)) abs(3 * E_45 - E_135) else 0
    rmse_val <- sqrt(mean(dt_res$ResSq, na.rm=TRUE))

    # Return the metrics for this Delta
    return(data.table(Delta = d_p, S = S_val, RMSE = rmse_val))
  } else {
    return(NULL)
  }
}

stopCluster(cl)

# 6. SAVE MASTER SUMMARY FILE
summary_file <- file.path(raw_directory, "00_tuning_metrics_summary.csv")
fwrite(final_dt, summary_file)
cat(sprintf("\n\nSuccess! Master Summary Saved to: %s\n", summary_file))

# 7. IDENTIFY THE PEAK (THE "PHYSICAL UNIVERSE")
# Criteria:
# 1. Must satisfy Tsirelson's Bound (S <= 2.828427)
# 2. Minimize RMSE (Best fit to cosine)

TSIRELSON_BOUND <- 2 * sqrt(2)

physical_candidates <- final_dt[S <= TSIRELSON_BOUND]
best_candidate <- physical_candidates[order(RMSE)][1]

cat("\n======================================================\n")
cat("            THE PEAK OF THE SIMULATION                \n")
cat("======================================================\n")
if (!is.na(best_candidate$Delta)) {
  cat(sprintf("WINNING CONFIGURATION:\n"))
  cat(sprintf("   Source Delta (Δ):  %.3f\n", best_candidate$Delta))
  cat(sprintf("   Detector Kappa (κ): %.4f (8π)\n", FIXED_KAPPA))
  cat(sprintf("   S-Value:            %.5f  (Limit: 2.82843)\n", best_candidate$S))
  cat(sprintf("   RMSE (Cos Fit):     %.5f\n", best_candidate$RMSE))
} else {
  cat("Note: All runs exceeded the strict bound. Showing closest match.\n")
  print(final_dt[order(abs(S - TSIRELSON_BOUND))][1])
}
cat("======================================================\n")

# Print top 10 candidates for context
cat("\n--- Top 10 Physical Candidates (Sorted by Cosine Fit) ---\n")
print(physical_candidates[order(RMSE)][1:10])
