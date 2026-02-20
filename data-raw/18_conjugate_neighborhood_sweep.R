library(data.table)
library(SternBrocotPhysics)
library(foreach)
library(doParallel)

# --- CONFIGURATION ---
# 1. DIRECTORY SETUP (4TB Drive)
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory     <- file.path(base_data_dir_4TB, "18_conjugate_neighborhood_sweep")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 2. PARAMETERS
sim_count   <- 5e4

# THE CONJUGATE SWEEP (Target ~0.846)
# We scan the neighborhood of the conjugate value
conjugate_delta_values <- seq(0.836, 0.856, by = 0.001)

# THE KAPPA SWEEP (Target ~8pi)
# We fine-tune kappa to see if 8pi is exact or if the peak shifts
kappa_pi_coeffs <- seq(7.0, 9.0, by = 0.2)
kappa_values    <- kappa_pi_coeffs * pi

# Angles
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 180, by = 4) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))

# 3. PARALLEL SETUP
num_cores <- parallel::detectCores(logical = FALSE) - 1
cl <- makeCluster(num_cores)
registerDoParallel(cl)

cat(sprintf("--- LAUNCHING CONJUGATE SWEEP ON %d CORES ---\n", num_cores))
cat(sprintf("Scanning Conjugate Delta: %.3f -> %.3f\n", min(conjugate_delta_values), max(conjugate_delta_values)))
cat(sprintf("Scanning Kappa: %.1fπ -> %.1fπ\n", min(kappa_pi_coeffs), max(kappa_pi_coeffs)))

# 4. EXECUTION LOOP
# We use %dopar% to parallelize the outer loop (Conjugate Delta)
final_dt <- foreach(d_prime = conjugate_delta_values, .combine = rbind, .packages = c("data.table", "SternBrocotPhysics")) %:%
  foreach(k = kappa_values, .combine = rbind) %dopar% {

    # CALCULATE THE INVERSE (The value passed to the simulation)
    d_p_sim <- 1 / d_prime

    # Recover the Pi coefficient for labeling
    k_coeff <- k / pi

    # Unique Directory for this specific pair
    run_id  <- sprintf("conj_%.3f_k_%.1fpi", d_prime, k_coeff)
    run_dir <- file.path(raw_directory, run_id)
    if (!dir.exists(run_dir)) dir.create(run_dir)

    # A. Run Simulation
    micro_macro_bell_erasure_sweep(
      angles = all_angles,
      dir = normalizePath(run_dir, mustWork = TRUE),
      count = sim_count,
      kappa = k,
      delta_particle = d_p_sim,   # Passing the INVERSE
      mu_start = -pi,
      mu_end = pi,
      n_threads = 1
    )

    # B. Process Data
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

          # Residual
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

    # C. Compute Metrics
    dt_res <- rbindlist(run_stats)
    result_row <- NULL

    if (nrow(dt_res) > 0) {
      E_45  <- approx(dt_res$phi, dt_res$E, xout = 45)$y
      E_135 <- approx(dt_res$phi, dt_res$E, xout = 135)$y
      S_val <- if(!is.na(E_45) && !is.na(E_135)) abs(3 * E_45 - E_135) else 0
      rmse_val <- sqrt(mean(dt_res$ResSq, na.rm=TRUE))

      result_row <- data.table(
        ConjDelta = d_prime,
        SimDelta = d_p_sim,
        KappaPi = k_coeff,
        S = S_val,
        RMSE = rmse_val
      )
    }

    # Clean up massive CSVs if space is an issue (Optional)
    # unlink(run_dir, recursive = TRUE)

    return(result_row)
  }

stopCluster(cl)

# 5. SAVE SUMMARY
summary_file <- file.path(raw_directory, "00_conjugate_summary.csv")
fwrite(final_dt, summary_file)

# 6. RESULTS
TSIRELSON_BOUND <- 2 * sqrt(2) # ~2.828427

cat("\n--- CONJUGATE SWEEP RESULTS ---\n")
cat("Focus: Neighborhood of 0.846 (1/1.182)\n\n")

# Top Physical Candidates (S <= Bound, Sorted by RMSE)
physical <- final_dt[S <= TSIRELSON_BOUND]
physical <- physical[order(RMSE)]

print(physical[1:20])
