# --- 18_canonical_full_collapse.R ---
library(data.table)
library(ggplot2)

# --- 1. SETUP ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
cat("--- PRE-LOADING ALL ACTION QUANTA VECTORS ---\n")

# Get available angles from filenames
alice_files <- list.files(smoke_dir, pattern = "alice.*csv.gz", full.names = TRUE)
bob_files   <- list.files(smoke_dir, pattern = "bob.*csv.gz", full.names = TRUE)

get_ang <- function(path) as.numeric(gsub(".*_([0-9]+\\.[0-9]+)\\.csv\\.gz", "\\1", path))

# Load data into lists for fast access
alice_data <- list()
bob_data   <- list()

for (f in alice_files) {
  ang <- get_ang(f)
  dt <- fread(f, select = c("spin", "found"))
  alice_data[[as.character(ang)]] <- dt
}

for (f in bob_files) {
  ang <- get_ang(f)
  dt <- fread(f, select = c("spin", "found"))
  # Apply Singlet Parity Flip
  dt[, spin := spin * -1]
  bob_data[[as.character(ang)]] <- dt
}

# --- 2. THE COMBINATORIAL SWEEP ---
cat("--- PERFORMING FULL CANONICAL COLLAPSE (32,761 PAIRS) ---\n")
results <- list()

alice_angles <- names(alice_data)
bob_angles   <- names(bob_data)

for (a_ang in alice_angles) {
  dt_a <- alice_data[[a_ang]]
  for (b_ang in bob_angles) {
    dt_b <- bob_data[[b_ang]]

    phi <- abs(as.numeric(b_ang) - as.numeric(a_ang))

    # Calculate Correlation E = mean(A * B_flipped)
    valid <- dt_a$found & dt_b$found
    corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))

    # We store the result
    results[[paste(a_ang, b_ang)]] <- data.table(Phi = phi, E = corr, Alice = a_ang)
  }
}

full_canonical <- rbindlist(results)

# --- 3. THE FINAL PLOT ---
cat("--- RENDERING CANONICAL COLLAPSE PLOT ---\n")
gp <- ggplot(full_canonical, aes(x = Phi, y = E)) +
  # Using alpha to see the density of the points
  geom_point(alpha = 0.05, size = 0.1, color = "#2980b9") +
  # The Quantum Target
  stat_function(fun = function(x) -cos(x * pi / 180), color = "red", linetype = "dashed", size = 1) +
  labs(
    title = "Canonical Correlation Collapse Test",
    subtitle = "Points: All 32k+ SB Combinations | Red Dashed: Quantum -cos(phi)",
    x = "Phase Difference phi = |Bob - Alice| (Degrees)",
    y = "Expectation Value E(phi)"
  ) +
  theme_minimal()

print(gp)

# Save the mean curve for comparison
mean_curve <- full_canonical[, .(E_mean = mean(E)), by = Phi][order(Phi)]
fwrite(mean_curve, file.path(smoke_dir, "canonical_mean_curve.csv"))
