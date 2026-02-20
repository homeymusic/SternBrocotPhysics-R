library(data.table)
library(SternBrocotPhysics)
library(foreach)
library(doParallel)

# --- CONFIGURATION ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory     <- file.path(base_data_dir_4TB, "20_manuscript_stability_sweep")

if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 1. PARAMETERS
# Manuscript Kappa
FIXED_KAPPA <- 4 / pi

# The Volatile Region: 0.55 to 0.75
# We need high resolution to see the "sawtooth" jumps
delta_p_values <- seq(0.55, 0.75, by = 0.01)

# High Count to rule out statistical noise as the cause of the jumps
sim_count   <- 5e4

# Angles
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 180, by = 4) + 1e-5
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))

# 2. PARALLEL SETUP
num_cores <- parallel::detectCores(logical = FALSE) - 1
cl <- makeCluster(num_cores)
registerDoParallel(cl)

cat("--- LAUNCHING STABILITY SWEEP ---\n")
cat(sprintf("Kappa: 4/pi | Delta: 0.55 -> 0.75 | Checking for Resonance\n"))

# 3. EXECUTION
final_dt <- foreach(d_p = delta_p_values, .combine = rbind, .packages = c("data.table", "SternBrocotPhysics")) %dopar% {

  run_dir <- file.path(raw_directory, sprintf("run_dp_%.2f", d_p))
  if (!dir.exists(run_dir)) dir.create(run_dir)

  # Run
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

  # Process
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
        rads <- (b_ang - alice_fixed) * pi / 180
        resid_sq <- (corr - (-cos(rads)))^2
        run_stats[[length(run_stats) + 1]] <- data.table(phi = b_ang - alice_fixed, E = corr, ResSq = resid_sq)
      }
    }
  }

  dt_res <- rbindlist(run_stats)

  if (nrow(dt_res) > 0) {
    E_45  <- approx(dt_res$phi, dt_res$E, xout = 45)$y
    E_135 <- approx(dt_res$phi, dt_res$E, xout = 135)$y
    S_val <- if(!is.na(E_45) && !is.na(E_135)) abs(3 * E_45 - E_135) else 0
    rmse_val <- sqrt(mean(dt_res$ResSq, na.rm=TRUE))

    # Check if curve is "blocky" (high RMSE) or smooth
    return(data.table(Delta = d_p, S = S_val, RMSE = rmse_val))
  }
}

stopCluster(cl)

# 4. RESULTS
TSIRELSON_BOUND <- 2 * sqrt(2)
cat("\n--- STABILITY RESULTS ---\n")
print(final_dt)

cat("\n--- BEST FIT TO MANUSCRIPT THEORY ---\n")
print(final_dt[order(RMSE)][1:5])
