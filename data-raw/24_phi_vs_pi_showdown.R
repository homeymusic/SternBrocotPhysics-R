library(data.table)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
raw_directory <- "data_raw/24_phi_vs_pi_showdown"
if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 1. THE CONTENDERS
# Candidate A: The Golden Ratio (Discrete Packing)
VAL_PHI <- (sqrt(5) - 1) / 2  # ~0.618034

# Candidate B: The Circle Constant (Continuous Geometry)
VAL_PI  <- 2 / pi             # ~0.636620

candidates <- c(VAL_PHI, VAL_PI)
names(candidates) <- c("Golden Ratio (1/phi)", "Circle Constant (2/pi)")

# 2. FIXED PARAMETERS
FIXED_KAPPA <- 4 / pi
sim_count   <- 1e5   # High precision
# We need a dense sweep for accurate RMSE (0 to 180 by 4)
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 180, by = 4) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))

cat("--- THE FINAL SHOWDOWN: PHI vs PI ---\n")
cat(sprintf("Target Limit: S <= 2.828427 (Tsirelson Bound)\n"))
cat(sprintf("Target Shape: RMSE -> 0 (Cosine Fit)\n\n"))

results_list <- list()

for (i in seq_along(candidates)) {
  name <- names(candidates)[i]
  val  <- candidates[i]

  cat(sprintf("Testing %s: Delta = %.6f...\n", name, val))

  # Run
  SternBrocotPhysics::micro_macro_bell_erasure_sweep(
    angles = all_angles,
    dir = normalizePath(raw_directory, mustWork = TRUE),
    count = sim_count,
    kappa = FIXED_KAPPA,
    delta_particle = val,
    mu_start = -pi,
    mu_end = pi,
    n_threads = 6
  )

  # Load Data
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
  dt_a <- fread(file.path(raw_directory, f_a), select=c("spin", "found"))

  run_stats <- list()

  # Calculate Curve and S-Value
  for (b_ang in bob_sweep) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    if (file.exists(file.path(raw_directory, f_b))) {
      dt_b <- fread(file.path(raw_directory, f_b), select=c("spin", "found"))
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

  dt_res <- rbindlist(run_stats)

  if (nrow(dt_res) > 0) {
    # Interpolate S-Value
    E_45  <- approx(dt_res$phi, dt_res$E, xout = 45)$y
    E_135 <- approx(dt_res$phi, dt_res$E, xout = 135)$y
    S_val <- abs(3 * E_45 - E_135)

    # Calculate RMSE
    rmse_val <- sqrt(mean(dt_res$ResSq, na.rm=TRUE))

    # Verdict
    # Tolerance of 0.01 for S-value violation
    status <- if (S_val > 2.828427 + 0.01) "VIOLATION" else "VALID"

    cat(sprintf("   -> S = %.5f [%s] | RMSE = %.5f\n", S_val, status, rmse_val))

    results_list[[length(results_list) + 1]] <- data.table(
      Candidate = name,
      Delta = val,
      S = S_val,
      RMSE = rmse_val,
      Verdict = status
    )
  }
}

cat("\n--- FINAL TABLE ---\n")
print(rbindlist(results_list))
