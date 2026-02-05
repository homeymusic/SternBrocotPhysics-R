# 06_chsh_analysis.R
here::i_am("data-raw/06_chsh_analysis.R")
library(data.table)

# --- 1. EXPERIMENTAL SETUP ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/05_micro_macro_angle_erasures"

# Scan the data repository once to build an index
all_files <- list.files(data_dir, pattern = "theta_.*\\.csv\\.gz$", full.names = TRUE)
file_angles <- as.numeric(gsub(".*theta_([0-9.]+)\\.csv\\.gz", "\\1", all_files))

# Function to load the spin measurement vector for a specific device setting
fetch_spins <- function(target_deg) {
  # Find the file with the closest matching angle
  idx <- which.min(abs(file_angles - target_deg))
  path <- all_files[idx]
  found_angle <- file_angles[idx]

  cat(sprintf("Loaded Run: %.2f deg -> %s\n", found_angle, basename(path)))

  # Return just the measurement column (1, -1, or 0)
  return(data.table::fread(path, select = "spin")$spin)
}

# --- 2. RETRIEVE DATA RUNS ---
cat("Fetching experimental data...\n")

# Load the four specific configurations required for the CHSH test
# Alice's Settings: 0.0 and 45.0 degrees
spins_A_0  <- fetch_spins(0.0)
spins_A_45 <- fetch_spins(45.0)

# Bob's Settings: 22.5 and 67.5 degrees
spins_B_22 <- fetch_spins(22.5)
spins_B_67 <- fetch_spins(67.5)

# --- 3. COINCIDENCE ANALYSIS ---
analyze_pair <- function(run_a, run_b, label) {

  # 1. INTERACTION PRODUCT
  # Calculate the raw product of the two measurement vectors.
  #  1 * 1 =  1 (Correlated Signal)
  #  1 * -1 = -1 (Anti-correlated Signal)
  #  X * 0 =  0 (Signal Lost / No Coincidence)
  interactions <- run_a * run_b

  # 2. FILTER INVALID EVENTS
  # We extract only the non-zero interactions (coincident detections).
  # This mathematically applies the coincidence filter.
  valid_signals <- interactions[interactions != 0]

  if(length(valid_signals) == 0) return(list(Pair=label, E=0, Eff=0))

  return(list(
    Pair = label,
    # The Correlation is the mean of the valid signals
    E = mean(valid_signals),
    # Efficiency is the ratio of valid signals to total attempts
    Efficiency = length(valid_signals) / length(run_a)
  ))
}

cat("\n--- PAIRWISE CORRELATIONS ---\n")

# Compute the four terms of the CHSH inequality
r1 <- analyze_pair(spins_A_0,  spins_B_22, "0 vs 22.5")
r2 <- analyze_pair(spins_A_0,  spins_B_67, "0 vs 67.5")
r3 <- analyze_pair(spins_A_45, spins_B_22, "45 vs 22.5")
r4 <- analyze_pair(spins_A_45, spins_B_67, "45 vs 67.5")

# Display Results
results <- rbind(as.data.frame(r1), as.data.frame(r2), as.data.frame(r3), as.data.frame(r4))
print(results)

# --- 4. CHSH STATISTIC ---
# S = |E1 - E2| + |E3 + E4|
# Note: E(0, 67.5) corresponds to the largest angular difference (135 lab / 67.5 sim)
# It is typically the term that changes sign or reduces magnitude.
S_stat <- abs(r1$E - r2$E) + abs(r3$E + r4$E)

cat("\n--- FINAL RESULT ---\n")
cat(sprintf("S Statistic:   %.5f\n", S_stat))
cat("Classical Limit: 2.0\n")
cat("Quantum Target:  2.82\n")
