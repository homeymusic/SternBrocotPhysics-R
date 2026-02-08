here::i_am("data-raw/08_correlation_resonance_map.R")
library(data.table)
library(ggplot2)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
sweep_angles <- seq(0, 90, by = 5) + 1e-5

# --- 1. COMPUTE SWEEP CORRELATIONS ---
cat("--- MAPPING PHASE-ALIGNED CORRELATION ---\n")
corr_list <- list()

for (ang in sweep_angles) {
  dt_a <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_alice_%013.6f.csv.gz", ang)), select = c("spin", "found"))
  dt_b <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_bob_%013.6f.csv.gz", ang)), select = c("spin", "found"))

  valid <- dt_a$found & dt_b$found
  # Applying the Singlet Parity Flip (-1) to Bob
  corr <- mean(as.numeric(dt_a$spin[valid]) * (as.numeric(dt_b$spin[valid]) * -1))

  corr_list[[as.character(ang)]] <- data.table(Angle = ang, Correlation = corr)
}

corr_data <- rbindlist(corr_list)

# --- 2. PLOT WITH PHASE-SHIFTED QUANTUM TARGET ---
gp_corr <- ggplot(corr_data, aes(x = Angle, y = Correlation)) +
  geom_line(color = "#c0392b", size = 1) +
  geom_point(color = "#2980b9", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  # PHASE SHIFT: Moving the Quantum -cos curve so its trough sits at 45 degrees
  stat_function(fun = function(x) -cos((x - 45) * (pi / 180) * 2),
                color = "black", linetype = "dotted") +
  labs(
    title = "Phase-Aligned Correlation Map",
    subtitle = "Dotted line shifted 45° to align Quantum Trough with Stern-Brocot Trough",
    x = "Relative Angle (Degrees)",
    y = "Correlation E(theta)"
  ) +
  theme_minimal()

print(gp_corr)
