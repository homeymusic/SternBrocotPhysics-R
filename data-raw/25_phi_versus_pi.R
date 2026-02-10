library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
# We use a temporary directory for the data generation
data_dir <- "data_raw/temp_phi_vs_pi"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# --- CONSTANTS ---
FIXED_KAPPA <- 4 / pi    # 1.2732...

# Define the two candidates
candidates <- list(
  list(name = "Golden Ratio (1/φ)", val = (sqrt(5) - 1) / 2, color = "#DAA520"), # Goldenrod
  list(name = "Circle Constant (2/π)", val = 2 / pi,         color = "firebrick")  # Red
)

# --- SIMULATION PARAMETERS ---
# Full 360 degree sweep
alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 360, by = 2) + 1e-5 # Step by 2 for speed, still smooth
all_angles  <- sort(unique(c(alice_fixed, bob_sweep)))
sim_count   <- 5e4  # Sufficient for visual comparison

cat("--- GENERATING PHI vs PI COMPARISON ---\n")

all_results <- list()

for (cand in candidates) {
  cat(sprintf("Simulating %s: Delta = %.6f...\n", cand$name, cand$val))

  # 1. Run Simulation
  # We use a sub-folder for each candidate to avoid file conflicts
  run_dir <- file.path(data_dir, paste0("run_", gsub("[^a-zA-Z0-9]", "", cand$name)))
  if (!dir.exists(run_dir)) dir.create(run_dir)

  SternBrocotPhysics::micro_macro_bell_erasure_sweep(
    angles = all_angles,
    dir = normalizePath(run_dir, mustWork = TRUE),
    count = sim_count,
    kappa = FIXED_KAPPA,
    delta_particle = cand$val,
    mu_start = -pi,
    mu_end = pi,
    n_threads = 6
  )

  # 2. Process Data
  f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
  dt_a <- fread(file.path(run_dir, f_a), select = c("spin", "found"))

  plot_data <- list()

  for (b_ang in bob_sweep) {
    f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
    if (file.exists(file.path(run_dir, f_b))) {
      dt_b <- fread(file.path(run_dir, f_b), select = c("spin", "found"))
      valid <- dt_a$found & dt_b$found
      if (any(valid)) {
        corr <- mean(as.numeric(dt_a$spin[valid]) * as.numeric(dt_b$spin[valid]))
        plot_data[[length(plot_data) + 1]] <- data.table(
          phi = b_ang - alice_fixed,
          E = corr,
          Candidate = cand$name
        )
      }
    }
  }

  dt_cand <- rbindlist(plot_data)
  all_results[[length(all_results) + 1]] <- dt_cand

  # Cleanup run files
  unlink(run_dir, recursive = TRUE)
}

dt_plot <- rbindlist(all_results)

# 3. PLOT
# Classical Limit Function (Sawtooth)
classical_sawtooth <- function(x) {
  ifelse(x <= 180, -1 + (2*x/180), 3 - (2*x/180))
}

gp <- ggplot(dt_plot, aes(x = phi)) +

  # Classical Limit (Gray Area)
  stat_function(fun = classical_sawtooth,
                color = "grey70", size = 0.8, linetype = "dotted") +

  # Quantum Prediction (Black Dashed)
  stat_function(fun = function(x) -cos(x * pi / 180),
                color = "black", size = 1, linetype = "dashed") +

  # Simulation Lines
  geom_line(aes(y = E, color = Candidate), size = 1.2, alpha = 0.9) +

  scale_color_manual(values = c(
    "Golden Ratio (1/φ)" = "#DAA520",
    "Circle Constant (2/π)" = "firebrick"
  )) +

  scale_x_continuous(breaks = seq(0, 360, by = 90),
                     labels = c("0°", "90°", "180°", "270°", "360°")) +
  ylim(-1.1, 1.1) +

  labs(
    title = "The Physical vs. The Super-Quantum",
    subtitle = "Comparing Erasure Thresholds: Golden Ratio (Physical) vs. Circle Constant (Violates Bound)",
    x = "Relative Phase",
    y = "Correlation E",
    caption = "Dotted: Classical Limit | Dashed: Quantum Prediction"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(face = "italic", hjust = 0.5, size=10, color="grey30"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

print(gp)

# Cleanup
unlink(data_dir, recursive = TRUE)
