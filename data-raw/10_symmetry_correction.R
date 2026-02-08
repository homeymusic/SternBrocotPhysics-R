here::i_am("data-raw/10_symmetry_correction.R")
library(data.table)
library(ggplot2)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
sweep_angles <- seq(0, 90, by = 5) + 1e-5

# --- 1. COMPUTE SWEEP WITH DUAL TARGETS ---
cat("--- TESTING PHOTON VS ELECTRON SYMMETRY ---\n")
corr_list <- list()

for (ang in sweep_angles) {
  dt_a <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_alice_%013.6f.csv.gz", ang)), select = c("spin", "found"))
  dt_b <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_bob_%013.6f.csv.gz", ang)), select = c("spin", "found"))

  valid <- dt_a$found & dt_b$found

  # RAW CORRELATION (No Flip - Photon/Parallel Style)
  # This tests if the inversion you saw was due to the manual -1 flip
  corr_raw <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))

  corr_list[[as.character(ang)]] <- data.table(Angle = ang, Correlation = corr_raw)
}

corr_data <- rbindlist(corr_list)

# --- 2. PLOT WITH DUAL QUANTUM PREDICTIONS ---
gp_sym <- ggplot(corr_data, aes(x = Angle, y = Correlation)) +
  geom_line(color = "#16a085", size = 1) +
  geom_point(color = "#1abc9c", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +

  # TARGET 1: Electron Singlet (Shifted -cos curve we used before)
  stat_function(fun = function(x) -cos((x - 45) * (pi / 180) * 2),
                aes(color = "Electron Singlet (-cos)"), linetype = "dotted") +

  # TARGET 2: Photon Polarization (cos(2*theta) style)
  # Photons correlate at 0 degrees and return to correlation at 90
  stat_function(fun = function(x) cos(x * (pi / 180) * 2),
                aes(color = "Photon (cos 2theta)"), linetype = "dashed") +

  scale_color_manual(name = "Predictions",
                     values = c("Electron Singlet (-cos)" = "black",
                                "Photon (cos 2theta)" = "#e67e22")) +
  labs(
    title = "Symmetry Correction Test: Photon vs. Electron",
    subtitle = "Testing if removing the Bob flip and using Photon periodicity fixes the 'Inversion'",
    x = "Relative Angle (Degrees)",
    y = "Correlation E(theta)"
  ) +
  theme_minimal()

print(gp_sym)
