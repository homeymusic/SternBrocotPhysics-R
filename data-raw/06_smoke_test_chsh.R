here::i_am("data-raw/06_smoke_test_chsh.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
rows_expected <- 1e6 + 1
plot_subsample <- 10000

# --- 1. CLEAN SLATE ---
if (!dir.exists(smoke_dir)) {
  dir.create(smoke_dir, recursive = TRUE)
} else {
  message("🧹 Wiping old smoke test data...")
  unlink(list.files(smoke_dir, full.names = TRUE))
}

# --- 2. PREPARE ANGLES ---
chsh_angles <- c(0.0, 22.5, 45.0, 67.5) + 1e-5
sweep_angles <- seq(0, 90, by = 5) + 1e-5
all_angles <- sort(unique(c(chsh_angles, sweep_angles)))

cat("--- GENERATING ALL SIMULATION DATA ---\n")
SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = all_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = rows_expected,
  n_threads = 6
)

# --- 3. LOADING & LABELING HELPERS ---
load_and_label <- function(angle, observer) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", tolower(observer), angle)
  fpath <- file.path(smoke_dir, fname)
  if (!file.exists(fpath)) stop(paste("Missing:", fpath))

  dt <- fread(fpath, select = c("spin", "found", "microstate"))
  rad <- angle * (pi / 180)
  delta_val <- if (observer == "Alice") cos(rad)^2 else sin(rad)^2

  total <- nrow(dt)
  p_up   <- (sum(dt$spin == 1) / total) * 100
  p_down <- (sum(dt$spin == -1) / total) * 100

  # Correct for zero-delta pole artifacts
  if (delta_val < 1e-10) p_up <- 0.0

  dt[, `:=`(
    Observer = observer,
    Angle = angle,
    Delta = delta_val,
    Label = sprintf("%s (%.1f°)\nDelta=%.4f\n↑:%.1f%% ↓:%.1f%%",
                    observer, angle, delta_val, p_up, p_down)
  )]
  return(dt)
}

# --- 4. CHSH CHECKPOINT ANALYSIS ---
cat("\n--- LOADING CHSH CHECKPOINTS ---\n")
dt_a0   <- load_and_label(chsh_angles[1], "Alice")
dt_a45  <- load_and_label(chsh_angles[3], "Alice")
dt_b22  <- load_and_label(chsh_angles[2], "Bob")
dt_b67  <- load_and_label(chsh_angles[4], "Bob")

analyze_pair <- function(name, dt1, dt2) {
  valid <- dt1$found & dt2$found
  corr <- mean(as.numeric(dt1$spin[valid]) * as.numeric(dt2$spin[valid]))
  data.table(Pair = name, Correlation = sprintf("%.4f", corr))
}

results_table <- rbind(
  analyze_pair("Alice(0) vs Bob(22.5)",  dt_a0,  dt_b22),
  analyze_pair("Alice(0) vs Bob(67.5)",  dt_a0,  dt_b67),
  analyze_pair("Alice(45) vs Bob(22.5)", dt_a45, dt_b22),
  analyze_pair("Alice(45) vs Bob(67.5)", dt_a45, dt_b67)
)
print("--- CHSH CORRELATION TABLE ---")
print(results_table)

# --- 5. CONJUGATE SWEEP & INVARIANT TABLE ---
cat("\n--- GENERATING 5-DEGREE SWEEP SUMMARY ---\n")
sweep_list <- list()
sweep_summary <- data.table()

for (ang in sweep_angles) {
  dt_a_sweep <- load_and_label(ang, "Alice")
  dt_b_sweep <- load_and_label(ang, "Bob")

  up_a <- (sum(dt_a_sweep$spin == 1)/nrow(dt_a_sweep))*100
  up_b <- (sum(dt_b_sweep$spin == 1)/nrow(dt_b_sweep))*100

  sweep_summary <- rbind(sweep_summary, data.table(
    Angle = ang,
    Alice_U = up_a,
    Bob_U   = up_b,
    Coherence_Total = up_a + up_b
  ))

  sweep_list[[as.character(ang)]] <- rbind(
    dt_a_sweep[seq(1, .N, length.out=2000)],
    dt_b_sweep[seq(1, .N, length.out=2000)]
  )
}
print("--- SWEEP SUMMARY: COHERENCE INVARIANCE ---")
print(sweep_summary)

# --- 6. PLOTTING ---

# Plot 1: 4-Facet Checkpoint
checkpoint_data <- rbind(
  dt_a0[seq(1, .N, length.out=plot_subsample)],
  dt_a45[seq(1, .N, length.out=plot_subsample)],
  dt_b22[seq(1, .N, length.out=plot_subsample)],
  dt_b67[seq(1, .N, length.out=plot_subsample)]
)
gp1 <- ggplot(checkpoint_data, aes(x = microstate, y = factor(spin), color = factor(spin))) +
  geom_jitter(height = 0.25, size = 0.6, alpha = 0.5) +
  facet_wrap(~Label, ncol = 2) +
  scale_color_manual(values = c("-1" = "#e74c3c", "1" = "#3498db"), guide="none") +
  labs(title = "The Geometry of Spin: Checkpoints", x = "Microstate (mu)", y = "Spin Outcome") +
  theme_minimal()
print(gp1)

# Plot 2: Sweep Grid
sweep_data <- rbindlist(sweep_list)
sweep_data[, Observer := factor(Observer, levels = c("Alice", "Bob"))]
gp2 <- ggplot(sweep_data, aes(x = microstate, y = factor(spin), color = factor(spin))) +
  geom_jitter(height = 0.2, size = 0.1, alpha = 0.3) +
  facet_grid(Angle ~ Observer) +
  scale_color_manual(values = c("-1" = "#e74c3c", "1" = "#3498db"), guide = "none") +
  labs(title = "Conjugate Sweep Grid", x = "Microstate (mu)", y = "Spin") +
  theme_minimal(base_size = 7) +
  theme(strip.text.y = element_text(angle = 0))
print(gp2)

# Plot 3: Resonance Curve (Total Coherence)
gp3 <- ggplot(sweep_summary, aes(x = Angle, y = Coherence_Total)) +
  geom_line(color = "#2c3e50", size = 1) +
  geom_point(color = "#e67e22", size = 3) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "red") +
  labs(title = "System Resonance Curve", subtitle = "Total Coherence (Alice ↑% + Bob ↑%) vs Angle",
       x = "Angle (Degrees)", y = "Total Coherence Sum (%)") +
  theme_minimal()
print(gp3)

cat("\n✅ Full Analysis Complete. Resonance Curve rendered.\n")
