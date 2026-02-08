here::i_am("data-raw/07_canonical_bell_curve.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell"
rows_to_sweep <- 1e6
# 15-degree steps for a full 2pi sweep (0 to 360)
sweep_angles <- seq(0, 360, by = 15) + 1e-5

# 1. CLEAN SLATE
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)
message("🧹 Wiping old simulation data...")
unlink(list.files(data_dir, full.names = TRUE))

# 2. GENERATE DATA
# We generate the full rotational manifold for Alice and Bob
cat("--- GENERATING THE CANONICAL MANIFOLD (0 to 2π) ---\n")
SternBrocotPhysics::micro_macro_bell_erasure_sweep(
  angles = sweep_angles,
  dir = normalizePath(data_dir, mustWork = TRUE),
  count = rows_to_sweep,
  n_threads = 6
)

# 3. CALCULATE CORRELATION MANIFOLD
cat("\n--- PAIRING OBSERVERS & MAPPING CORRELATIONS ---\n")
results <- list()

# We fix Alice at 0 and sweep Bob, OR cross-compare all combinations
# To get the best resolution of phi, we'll cross-compare a subset
for (a_ang in sweep_angles[sweep_angles <= 90]) {
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", a_ang)
  dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

  for (b_ang in sweep_angles) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

    # phi = (alpha - beta)
    phi_deg <- a_ang - b_ang
    phi_rad <- phi_deg * (pi / 180)

    # Correlation E: Only valid for the surviving microstates
    valid <- dt_a$found & dt_b$found
    if (any(valid)) {
      # Match (+1) if spins are same, No-Match (-1) if spins are opposite
      # Standard Expectation Value E = (N_same - N_diff) / N_total
      corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))

      results[[paste(a_ang, b_ang)]] <- data.table(
        phi = phi_deg,
        E = corr,
        Alice_Angle = a_ang
      )
    }
  }
}

manifold_dt <- rbindlist(results)

# 4. RENDER THE CANONICAL BELL CURVE
gp <- ggplot(manifold_dt, aes(x = phi, y = E)) +
  # The Cloud of Shredded Expectations
  geom_point(alpha = 0.5, color = "#2c3e50", size = 1.5) +
  # The Quantum Target (Negative Cosine)
  stat_function(fun = function(x) -cos(x * pi / 180), color = "#e74c3c", size = 1.2, linetype = "dashed") +
  scale_x_continuous(breaks = seq(-360, 360, by = 90), labels = c("-2π", "-π", "0", "π", "2π")) +
  ylim(-1.1, 1.1) +
  labs(
    title = "The Canonical Bell Curve",
    subtitle = "Deterministic Stern-Brocot Erasure vs. Quantum Expectation",
    x = "Relative Phase phi (alpha - beta)",
    y = "Expectation Value E(phi)"
  ) +
  theme_minimal()

print(gp)

# 5. FORENSICS TABLE
cat("\n--- MANIFOLD SUMMARY TABLE ---\n")
print(manifold_dt[order(phi)][seq(1, .N, length.out = 20)])
