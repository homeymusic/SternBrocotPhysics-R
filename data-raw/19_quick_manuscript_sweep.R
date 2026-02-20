library(data.table)
library(SternBrocotPhysics)
library(foreach)
library(doParallel)

# --- QUICK SWEEP CONFIGURATION ---
base_data_dir_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
raw_directory     <- file.path(base_data_dir_4TB, "19_quick_manuscript_sweep")
if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 1. FAST PARAMETERS
FIXED_KAPPA <- 4 / pi  # approx 1.273

# Define the angles EXACTLY once so the writer and reader agree
# We use the epsilon offset to avoid floating point zero issues in C++
target_angles <- c(0, 45, 90, 135, 180) + 1e-5

# Broad Sweep
delta_p_values <- seq(0.1, 4.0, by = 0.1)
sim_count      <- 1e4

# 2. PARALLEL SETUP
# Safely detect cores
num_cores <- parallel::detectCores(logical = FALSE) - 1
cl <- makeCluster(num_cores)
registerDoParallel(cl)

cat("--- LAUNCHING QUICK & DIRTY SWEEP (CORRECTED) ---\n")
cat(sprintf("Kappa: %.4f (4/pi) | Delta Range: 0.1 -> 4.0\n", FIXED_KAPPA))

# 3. EXECUTION
results <- foreach(d_p = delta_p_values, .combine = rbind, .packages = c("data.table", "SternBrocotPhysics")) %dopar% {

  # Temporary directory for this thread
  run_dir <- file.path(raw_directory, sprintf("temp_dp_%.1f", d_p))
  if (!dir.exists(run_dir)) dir.create(run_dir)

  # A. Run Simulation (Using target_angles)
  micro_macro_bell_erasure_sweep(
    angles = target_angles,
    dir = normalizePath(run_dir, mustWork = TRUE),
    count = sim_count,
    kappa = FIXED_KAPPA,
    delta_particle = d_p,
    mu_start = -pi,
    mu_end = pi,
    n_threads = 1
  )

  # B. Construct Filenames based on the EXACT same vector
  # Alice is the first angle (0 + 1e-5)
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", target_angles[1])
  path_a <- file.path(run_dir, f_a)

  res_row <- NULL

  # C. Check if file exists (Safety Check)
  if (file.exists(path_a)) {
    dt_a <- fread(path_a, select = c("spin", "found"))

    # Function to get correlation for a specific Bob angle
    get_corr <- function(angle_val) {
      f_b <- sprintf("erasure_bob_%013.6f.csv.gz", angle_val)
      path_b <- file.path(run_dir, f_b)
      if (file.exists(path_b)) {
        dt_b <- fread(path_b, select = c("spin", "found"))
        valid <- dt_a$found & dt_b$found
        if (any(valid)) {
          return(mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid])))
        }
      }
      return(0)
    }

    # Calculate S = |3*E(45) - E(135)|
    # Index 2 is 45deg, Index 4 is 135deg
    E_45  <- get_corr(target_angles[2])
    E_135 <- get_corr(target_angles[4])

    S_val <- abs(3 * E_45 - E_135)
    res_row <- data.table(Delta = d_p, S = S_val)
  }

  # Cleanup (Optional - keep enabled to save space)
  unlink(run_dir, recursive = TRUE)

  return(res_row)
}

stopCluster(cl)

# 4. RESULTS
if (!is.null(results) && nrow(results) > 0) {
  cat("\n--- QUICK RESULTS (Sorted by Proximity to 2.828) ---\n")
  results[, Dist := abs(S - 2.8284)]
  print(results[order(Dist)][1:10])
} else {
  cat("\nNo results returned. Check if simulation is producing files.\n")
}
