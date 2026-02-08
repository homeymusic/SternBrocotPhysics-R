here::i_am("data-raw/12_sliding_coherence_chsh.R")
library(data.table)
library(ggplot2)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
plot_subsample <- 10000

# --- 1. THE SLIDING MICROSTATE HELPER ---
load_and_shift <- function(angle, observer) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", tolower(observer), angle)
  fpath <- file.path(smoke_dir, fname)
  if (!file.exists(fpath)) stop(paste("Missing data at:", fpath))

  dt <- fread(fpath, select = c("spin", "found", "microstate"))

  # PHYSICAL SHIFT: Bob sees a phase-shifted version of the microstate
  # We use a simple linear shift proportional to the angle (normalized)
  if (observer == "Bob") {
    # Applying the Singlet Parity Flip from 07
    dt[, spin := spin * -1]

    # Conceptually, the shift 'slides' Bob's coherence window
    # To properly simulate this with static files, we 're-align' the index
    shift_val <- round((angle / 90) * 100) # Shift by 100 indices per 90 degrees
    dt[, spin := shift(spin, n = shift_val, fill = 0)]
  }

  rad <- angle * (pi / 180)
  delta_val <- if (observer == "Alice") cos(rad)^2 else sin(rad)^2

  dt[, `:=`(
    Observer = observer,
    Angle = angle,
    Delta = delta_val,
    Label = sprintf("%s (%.1f°)\nDelta=%.4f", observer, angle, delta_val)
  )]
  return(dt)
}

# --- 2. CHSH ANALYSIS (SLIDING COHERENCE) ---
cat("--- ANALYZING CHSH WITH MICROSTATE SLIDING ---\n")
chsh_angles <- c(0.0, 22.5, 45.0, 67.5) + 1e-5

dt_a0   <- load_and_shift(chsh_angles[1], "Alice")
dt_a45  <- load_and_shift(chsh_angles[3], "Alice")
dt_b22  <- load_and_shift(chsh_angles[2], "Bob")
dt_b67  <- load_and_shift(chsh_angles[4], "Bob")

analyze_pair <- function(name, dt1, dt2) {
  valid <- dt1$found & dt2$found & (dt1$spin != 0) & (dt2$spin != 0)
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
cat(sprintf("\n--- SLIDING CHSH RESULT: S = %.4f ---\n", S_stat))

# --- 3. CORRELATION MAP SWEEP ---
cat("\n--- GENERATING SLIDING CORRELATION MAP ---\n")
sweep_angles <- seq(0, 90, by = 5) + 1e-5
corr_map <- list()

for (ang in sweep_angles) {
  d_a <- load_and_shift(ang, "Alice")
  d_b <- load_and_shift(ang, "Bob")
  v <- d_a$found & d_b$found & (d_a$spin != 0) & (d_b$spin != 0)
  corr_map[[as.character(ang)]] <- data.table(
    Angle = ang,
    Correlation = mean(as.numeric(d_a$spin[v]) * as.numeric(d_b$spin[v]))
  )
}
corr_data <- rbindlist(corr_map)

# --- 4. THE RESONANCE PLOT ---
resonance_plot = ggplot(corr_data, aes(x = Angle, y = Correlation)) +
  geom_line(color = "#d35400", size = 1) +
  geom_point(color = "#e67e22", size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  stat_function(fun = function(x) -cos(x * pi / 180), color = "black", linetype = "dotted") +
  labs(title = "Sliding Coherence Correlation Map",
       subtitle = "Dotted: Quantum -cos(theta) | Orange: Stern-Brocot with Phase Shift",
       x = "Relative Angle", y = "Correlation E(theta)") +
  theme_minimal()

print(resonance_plot)
