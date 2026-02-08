here::i_am("data-raw/11_mirrored_symmetry_test.R")
library(data.table)
library(ggplot2)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
sweep_angles <- seq(0, 90, by = 5) + 1e-5

# --- 1. COMPUTE SWEEP WITH MIRRORED SYMMETRY ---
cat("--- TESTING MIRRORED SYMMETRY (90 - theta) ---\n")
corr_list <- list()

for (ang in sweep_angles) {
  # Alice stays standard
  dt_a <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_alice_%013.6f.csv.gz", ang)), select = c("spin", "found"))

  # MIRROR LOGIC: We pair Alice(ang) with Bob(90 - ang)
  # This tests if the uncertainty budgets are simply 'swapped' in the logic
  mirrored_ang <- 90 - ang + 2e-5 # Slight offset to match file naming
  fname_b <- sprintf("micro_macro_erasures_bob_%013.6f.csv.gz", mirrored_ang)
  fpath_b <- file.path(smoke_dir, fname_b)

  if (file.exists(fpath_b)) {
    dt_b <- fread(fpath_b, select = c("spin", "found"))
    valid <- dt_a$found & dt_b$found

    # We use raw correlation to see if the Photon-style peak emerges
    corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
    corr_list[[as.character(ang)]] <- data.table(Angle = ang, Correlation = corr)
  }
}

corr_data <- rbindlist(corr_list)

# --- 2. PLOT THE MIRRORED RESULTS ---
gp_mirrored <- ggplot(corr_data, aes(x = Angle, y = Correlation)) +
  geom_line(color = "#2980b9", size = 1) +
  geom_point(color = "#3498db", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +

  # Quantum Photon Prediction for comparison
  stat_function(fun = function(x) cos(x * (pi / 180) * 2),
                color = "#e67e22", linetype = "dashed") +

  labs(
    title = "Mirrored Symmetry Test (Bob at 90 - theta)",
    subtitle = "Blue: Mirrored Stern-Brocot Model | Orange: Photon cos(2theta)",
    x = "Alice Relative Angle (Degrees)",
    y = "Correlation E(theta)"
  ) +
  theme_minimal()

print(gp_mirrored)
