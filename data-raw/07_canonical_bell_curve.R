here::i_am("data-raw/07_canonical_bell_curve.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell"
rows_to_sweep <- 1e6
alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 360, by = 2) + 1e-5 # 2-degree resolution
all_angles <- sort(unique(c(alice_fixed, bob_sweep)))

# 1. CLEAN SLATE
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)
message("🧹 Wiping old simulation data...")
unlink(list.files(data_dir, full.names = TRUE))

# 2. GENERATE DATA
cat("--- GENERATING CANONICAL DATA (0 to 2π Sweep) ---\n")
SternBrocotPhysics::micro_macro_bell_erasure_sweep(
  angles = all_angles,
  dir = normalizePath(data_dir, mustWork = TRUE),
  count = rows_to_sweep,
  n_threads = 6
)

# 3. CALCULATE CORRELATION
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
dt_a <- fread(file.path(data_dir, f_a), select = c("spin", "found"))

results <- list()
for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  dt_b <- fread(file.path(data_dir, f_b), select = c("spin", "found"))

  # POSITIVE PHASE: phi = (Bob - Alice)
  phi_deg <- b_ang - alice_fixed

  valid <- dt_a$found & dt_b$found
  if (any(valid)) {
    corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
    results[[as.character(b_ang)]] <- data.table(phi = phi_deg, E = corr)
  }
}

manifold_dt <- rbindlist(results)

# 4. RENDER THE CANONICAL BELL CURVE
gp <- ggplot(manifold_dt, aes(x = phi, y = E)) +
  # The Quantum Target (Negative Cosine)
  stat_function(fun = function(x) -cos(x * pi / 180), color = "#e74c3c", size = 1, linetype = "dashed") +
  # The Stern-Brocot "Sawtooth" Results
  geom_line(color = "#2c3e50", size = 0.8) +
  geom_point(color = "#3498db", size = 1.2, alpha = 0.6) +
  scale_x_continuous(breaks = seq(0, 360, by = 90), labels = c("0", "0.5π", "π", "1.5π", "2π")) +
  ylim(-1.1, 1.1) +
  labs(
    title = "The Canonical Bell Curve (0 to 2π)",
    subtitle = "Relative Phase Sweep | Bob - Alice",
    x = "Relative Phase phi (Degrees)",
    y = "Expectation Value E(phi)"
  ) +
  theme_minimal()

print(gp)
