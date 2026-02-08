# --- 19_mean_curve_forensics.R ---
library(data.table)
library(ggplot2)

# --- 1. LOAD THE DATA ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
fpath <- file.path(smoke_dir, "canonical_mean_curve.csv")

if (!file.exists(fpath)) stop("Run script 18 first to generate the mean curve!")
dt <- fread(fpath)

# --- 2. CALCULATE DEVIATIONS ---
# We compare the SB Mean to:
# 1. Classical Linear (Identity): 1 - (phi/45) [for the 0-90 range]
# 2. Quantum Singlet: -cos(phi)
dt[, `:=`(
  Quantum_Target = -cos(Phi * pi / 180),
  Classical_Linear = (Phi / 45) - 1, # Simple V-shape approximation
  Residual_QM = E_mean - (-cos(Phi * pi / 180))
)]

# --- 3. THE "WOLVERINE" RESONANCE TABLE ---
# Finding where the tree is most active
cat("--- TOP MEAN RESONANCE DEVIATIONS ---\n")
peaks <- dt[order(-abs(Residual_QM))][1:10]
print(peaks[, .(Phi, E_mean, Quantum_Target, Residual_QM)])

# --- 4. PLOTTING THE COLLAPSED UNIVERSE ---

# Plot A: The Canonical Mean vs Quantum
gp1 <- ggplot(dt, aes(x = Phi)) +
  geom_line(aes(y = E_mean, color = "Stern-Brocot Mean"), size = 1.2) +
  geom_line(aes(y = Quantum_Target, color = "Quantum -cos(phi)"), linetype = "dashed", size = 1) +
  geom_line(aes(y = Classical_Linear, color = "Classical Linear"), linetype = "dotted") +
  scale_color_manual(values = c(
    "Stern-Brocot Mean" = "#2c3e50",
    "Quantum -cos(phi)" = "#e74c3c",
    "Classical Linear" = "#7f8c8d"
  )) +
  labs(title = "Stern-Brocot Canonical Mean Curve",
       subtitle = "Averaged over 32,761 Alice/Bob Combinations",
       x = "Phase Difference (Phi)", y = "Expectation Value E") +
  theme_minimal()

# Plot B: The Residual (The 'Signal' of the Tree)
gp2 <- ggplot(dt, aes(x = Phi, y = Residual_QM)) +
  geom_area(fill = "#3498db", alpha = 0.3) +
  geom_line(color = "#2980b9") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "QM Residual Map",
       subtitle = "Difference between SB Mean and -cos(phi). Zero = Perfect Quantum Match.",
       x = "Phase Difference (Phi)", y = "Error (E_mean - Quantum)") +
  theme_minimal()

print(gp1)
print(gp2)
