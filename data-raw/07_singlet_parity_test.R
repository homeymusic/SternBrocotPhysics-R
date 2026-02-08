here::i_am("data-raw/07_singlet_parity_test.R")
library(data.table)
library(ggplot2)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
plot_subsample <- 10000

# --- 1. LOADING & PARITY FLIP HELPER ---
load_with_parity <- function(angle, observer) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", tolower(observer), angle)
  fpath <- file.path(smoke_dir, fname)
  if (!file.exists(fpath)) stop(paste("Run 06 script first to generate data at:", fpath))

  dt <- fread(fpath, select = c("spin", "found", "microstate"))

  # APPLY THE SINGLET FLIP FOR BOB
  if (observer == "Bob") {
    dt[, spin := spin * -1]
  }

  rad <- angle * (pi / 180)
  delta_val <- if (observer == "Alice") cos(rad)^2 else sin(rad)^2
  p_up <- (sum(dt$spin == 1) / nrow(dt)) * 100
  p_down <- (sum(dt$spin == -1) / nrow(dt)) * 100

  dt[, `:=`(
    Observer = observer,
    Angle = angle,
    Delta = delta_val,
    Label = sprintf("%s (%.1f°)\nDelta=%.4f\n↑:%.1f%% ↓:%.1f%%",
                    observer, angle, delta_val, p_up, p_down)
  )]
  return(dt)
}

# --- 2. CHSH ANALYSIS WITH FLIPPED PARITY ---
cat("--- ANALYZING CHSH WITH SINGLET PARITY FLIP ---\n")
chsh_angles <- c(0.0, 22.5, 45.0, 67.5) + 1e-5

dt_a0   <- load_with_parity(chsh_angles[1], "Alice")
dt_a45  <- load_with_parity(chsh_angles[3], "Alice")
dt_b22  <- load_with_parity(chsh_angles[2], "Bob")
dt_b67  <- load_with_parity(chsh_angles[4], "Bob")

analyze_pair <- function(name, dt1, dt2) {
  valid <- dt1$found & dt2$found
  # Now s2 is already flipped in load_with_parity
  corr <- mean(as.numeric(dt1$spin[valid]) * as.numeric(dt2$spin[valid]))
  data.table(Pair = name, Correlation = sprintf("%.4f", corr))
}

results_table <- rbind(
  analyze_pair("Alice(0) vs Bob(22.5)",  dt_a0,  dt_b22),
  analyze_pair("Alice(0) vs Bob(67.5)",  dt_a0,  dt_b67),
  analyze_pair("Alice(45) vs Bob(22.5)", dt_a45, dt_b22),
  analyze_pair("Alice(45) vs Bob(67.5)", dt_a45, dt_b67)
)
print(results_table)

get_corr <- function(idx) as.numeric(results_table$Correlation[idx])
S_stat <- abs(get_corr(1) - get_corr(2)) + abs(get_corr(3) + get_corr(4))
cat(sprintf("\n--- FLIPPED CHSH RESULT: S = %.4f ---\n", S_stat))

# --- 3. PLOT 1: FLIPPED CHECKPOINTS ---
cat("\n--- RENDERING FLIPPED CHECKPOINT PLOT ---\n")
checkpoint_data <- rbind(
  dt_a0[seq(1, .N, length.out=plot_subsample)],
  dt_a45[seq(1, .N, length.out=plot_subsample)],
  dt_b22[seq(1, .N, length.out=plot_subsample)],
  dt_b67[seq(1, .N, length.out=plot_subsample)]
)

gp1 <- ggplot(checkpoint_data, aes(x = microstate, y = factor(spin), color = factor(spin))) +
  geom_jitter(height = 0.25, size = 0.6, alpha = 0.5) +
  facet_wrap(~Label, ncol = 2) +
  scale_color_manual(values = c("-1" = "#e74c3c", "1" = "#3498db"), name = "Flipped Spin") +
  labs(title = "Singlet Parity Checkpoints",
       subtitle = "Bob's spin is negated (-1x) to test anti-parallel correlation",
       x = "Microstate (mu)", y = "Spin Outcome (Flipped)") +
  theme_minimal()
print(gp1)

# --- 4. PLOT 2: THE SYNCED SWEEP GRID ---
cat("\n--- RENDERING SYNCED SWEEP GRID ---\n")
sweep_angles <- seq(0, 90, by = 5) + 1e-5
sweep_list <- list()

for (ang in sweep_angles) {
  sweep_list[[as.character(ang)]] <- rbind(
    load_with_parity(ang, "Alice")[seq(1, .N, length.out=2000)],
    load_with_parity(ang, "Bob")[seq(1, .N, length.out=2000)]
  )
}
sweep_data <- rbindlist(sweep_list)
sweep_data[, Observer := factor(Observer, levels = c("Alice", "Bob"))]

gp2 <- ggplot(sweep_data, aes(x = microstate, y = factor(spin), color = factor(spin))) +
  geom_jitter(height = 0.2, size = 0.1, alpha = 0.3) +
  facet_grid(Angle ~ Observer) +
  scale_color_manual(values = c("-1" = "#e74c3c", "1" = "#3498db"), guide = "none") +
  labs(title = "Synced Conjugate Sweep (Bob Flipped)",
       subtitle = "Blue islands should now align where correlations are strongest",
       x = "Microstate (mu)", y = "Spin Outcome") +
  theme_minimal(base_size = 7) +
  theme(strip.text.y = element_text(angle = 0, size = 6))
print(gp2)
