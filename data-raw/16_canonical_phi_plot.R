here::i_am("data-raw/16_canonical_phi_plot.R")
library(data.table)
library(ggplot2)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"

# Anchor Alice at a few different angles to check rotational invariance
alice_anchors <- c(0.0, 22.5, 45.0, 67.5, 90.0) + 1e-5

# --- 1. COMPUTATION ---
cat("--- GENERATING CANONICAL E vs PHI MAP ---\n")
results_list <- list()

for (a_ang in alice_anchors) {
  a_fname <- sprintf("micro_macro_erasures_alice_%013.6f.csv.gz", a_ang)
  if(!file.exists(file.path(smoke_dir, a_fname))) next
  dt_a <- fread(file.path(smoke_dir, a_fname), select = c("spin", "found"))

  # Sweep Bob through all available high-res data (subsampled for speed)
  bob_sweep <- seq(0, 90, by = 1) + 1e-5

  for (b_ang in bob_sweep) {
    b_fname <- sprintf("micro_macro_erasures_bob_%013.6f.csv.gz", b_ang)
    if(!file.exists(file.path(smoke_dir, b_fname))) next
    dt_b <- fread(file.path(smoke_dir, b_fname), select = c("spin", "found"))

    valid <- dt_a$found & dt_b$found
    # Correlation with Singlet Parity (-1 flip)
    corr <- mean(as.numeric(dt_a$spin[valid]) * (as.numeric(dt_b$spin[valid]) * -1))

    results_list[[paste(a_ang, b_ang)]] <- data.table(
      Alice = a_ang,
      Bob = b_ang,
      Phi = a_ang - b_ang,
      E = corr
    )
  }
}

plot_data <- rbindlist(results_list)

# --- 2. PLOTTING ---
gp <- ggplot(plot_data, aes(x = Phi, y = E, color = factor(round(Alice, 1)))) +
  geom_line(size = 1) +
  # The Quantum Target: -cos(phi)
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", linetype = "dashed") +
  labs(
    title = "Canonical Correlation Map: E vs. Phase Difference (phi)",
    subtitle = "Solid lines: SB Model at different Alice settings | Dashed: Quantum -cos(phi)",
    x = "Phase Difference phi = Alice - Bob (Degrees)",
    y = "Correlation E(phi)",
    color = "Alice Angle"
  ) +
  theme_minimal()

print(gp)
