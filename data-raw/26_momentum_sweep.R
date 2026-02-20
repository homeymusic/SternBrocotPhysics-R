library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_base_dir <- "/Volumes/SanDisk4TB/SternBrocot/26_momentum_search_emergent"
if (!dir.exists(data_base_dir)) dir.create(data_base_dir, recursive = TRUE)

# --- SEARCH PARAMETERS ---
target_S <- 2.828427
sim_count <- 5e4
alice_fixed <- 0.0 + 1e-5
bob_sweep <- c(45, 135) + 1e-5
all_angles <- sort(unique(c(alice_fixed, bob_sweep)))

# Helper function to run the C++ simulation and return S-value
run_sweep <- function(m_vals, label) {
  results <- list()
  for (L in m_vals) {
    iter_dir <- file.path(data_base_dir, sprintf("%s_L_%.6f", label, L))
    if (!dir.exists(iter_dir)) dir.create(iter_dir)

    micro_macro_bell_erasure_sweep(
      detector_angles = all_angles,
      dir = normalizePath(iter_dir, mustWork = TRUE),
      count = sim_count,
      angular_momentum = L,
      microstate_particle_angle_start = -pi,
      microstate_particle_angle_end = pi,
      n_threads = 6
    )

    f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
    dt_a <- fread(file.path(iter_dir, f_a), select = c("spin", "found"))

    dt_45 <- fread(file.path(iter_dir, sprintf("erasure_bob_%013.6f.csv.gz", 45 + 1e-5)), select = c("spin", "found"))
    v45   <- dt_a$found & dt_45$found
    e45   <- -mean(as.numeric(dt_a$spin[v45]) * as.numeric(dt_45$spin[v45]))

    dt_135 <- fread(file.path(iter_dir, sprintf("erasure_bob_%013.6f.csv.gz", 135 + 1e-5)), select = c("spin", "found"))
    v135   <- dt_a$found & dt_135$found
    e135   <- -mean(as.numeric(dt_a$spin[v135]) * as.numeric(dt_135$spin[v135]))

    results[[length(results) + 1]] <- data.table(
      angular_momentum = L,
      S_val = abs(3 * e45 - e135)
    )
    unlink(iter_dir, recursive = TRUE)
  }
  return(rbindlist(results))
}

# --- STAGE 1: GLOBAL SWEEP (COARSE) ---
cat("--- STAGE 1: GLOBAL SWEEP ---\n")
momentum_global <- seq(0.1, 2.0, by = 0.1)
global_dt <- run_sweep(momentum_global, "global")
best_global <- global_dt[S_val <= target_S][which.max(S_val)]
global_crossover <- best_global$angular_momentum

# --- STAGE 2: FINE SWEEP (HIGH RES) ---
cat(sprintf("--- STAGE 2: FINE SWEEP AROUND L = %.2f ---\n", global_crossover))
momentum_fine <- seq(global_crossover, global_crossover + 0.1, by = 0.001)
fine_dt <- run_sweep(momentum_fine, "fine")
best_fine <- fine_dt[S_val <= target_S][which.max(S_val)]
fine_crossover <- best_fine$angular_momentum

# --- STAGE 3: EXTREME ZOOM ---
cat(sprintf("--- STAGE 3: EXTREME ZOOM AROUND L = %.4f ---\n", fine_crossover))
momentum_extreme <- seq(fine_crossover - 0.0005, fine_crossover + 0.002, by = 0.00001)
extreme_dt <- run_sweep(momentum_extreme, "extreme")
best_extreme <- extreme_dt[S_val <= target_S][which.max(S_val)]

# --- PLOTTING ---

# 1. Global Plot
p_global <- ggplot(global_dt, aes(x = angular_momentum, y = S_val)) +
  geom_line(color = "grey80") +
  geom_point(size = 1) +
  geom_hline(yintercept = target_S, linetype = "dashed", color = "red") +
  labs(title = sprintf("Global Sweep | L=%.2f | S=%.4f (Target %.4f)",
                       best_global$angular_momentum, best_global$S_val, target_S),
       x = "Angular Momentum (Δ)", y = "S-Value") +
  theme_minimal()

# 2. Fine Plot
p_zoom <- ggplot(fine_dt, aes(x = angular_momentum, y = S_val)) +
  geom_line(color = "blue", alpha = 0.3) +
  geom_point(color = "blue", size = 1.5) +
  geom_hline(yintercept = target_S, linetype = "dashed", color = "red") +
  labs(title = sprintf("Fine Search | L=%.3f | S=%.5f (Target %.5f)",
                       best_fine$angular_momentum, best_fine$S_val, target_S),
       x = "Angular Momentum (Δ)", y = "S-Value") +
  theme_minimal()

# 3. Extreme Zoom Plot
p_extreme <- ggplot(extreme_dt, aes(x = angular_momentum, y = S_val)) +
  geom_line(color = "darkgreen", alpha = 0.3) +
  geom_point(color = "darkgreen", size = 2) +
  geom_hline(yintercept = target_S, linetype = "dashed", color = "red") +
  labs(title = sprintf("Extreme Zoom | L=%.5f | S=%.6f (Target %.6f)",
                       best_extreme$angular_momentum, best_extreme$S_val, target_S),
       x = "Angular Momentum (Δ)", y = "S-Value") +
  theme_minimal()

# Display all plots
print(p_global)
print(p_zoom)
print(p_extreme)

# Final Output
cat("\n--- FINAL DISCOVERY ---\n")
cat(sprintf("Recommended Momentum (Closest below Limit): %.5f\n", best_extreme$angular_momentum))
cat(sprintf("Resulting S-Value: %.6f (Limit: %.6f)\n", best_extreme$S_val, target_S))
