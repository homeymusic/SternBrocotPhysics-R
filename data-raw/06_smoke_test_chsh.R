here::i_am("data-raw/06_smoke_test_chsh.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"

# --- 1. CLEAN SLATE PROTOCOL ---
if (dir.exists(smoke_dir)) {
  message("🧹 Wiping old smoke test data...")
  old_files <- list.files(smoke_dir, full.names = TRUE)
  if (length(old_files) > 0) unlink(old_files)
} else {
  dir.create(smoke_dir, recursive = TRUE)
}

# --- 2. PREPARE ANGLES (All < 90° for First Quadrant Baseline) ---
granularity <- 1e-5
# Standard CHSH-style angles within the first quadrant
target_angles <- c(0.0, 22.5, 45.0, 67.5) + granularity

cat("--- GENERATING SMOKE TEST DATA ---\n")
cat("Targets:", paste(target_angles, collapse=", "), "\n")

# --- 3. PREVIEW PHYSICS (K=1.0 logic) ---
preview_uncertainty <- function(deg, observer) {
  rad <- deg * (pi / 180)
  if (observer == "Alice") return(cos(rad)^2)
  else return(sin(rad)^2)
}

unc_table <- data.table(
  Observer = c("Alice", "Alice", "Bob", "Bob"),
  Angle_Label = c(0, 45, 22.5, 67.5),
  Input_Val = c(target_angles[1], target_angles[3], target_angles[2], target_angles[4])
)
unc_table[, Uncertainty := mapply(preview_uncertainty, Input_Val, Observer)]
print("--- PHYSICAL UNCERTAINTY RADII (Conjugate Perspectives) ---")
print(unc_table)

# --- 4. EXECUTE SIMULATION ---
rows_expected <- 1e6 + 1

SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = target_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = rows_expected,
  n_threads = 4
)

# --- 5. LOADING HELPER ---
load_experiment_data <- function(angle, type) {
  # Matching the Alice/Bob labels in the C++ snprintf
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", type, angle)
  fpath <- file.path(smoke_dir, fname)
  if (!file.exists(fpath)) stop(paste("Missing:", fpath))

  # Only loading what we need for the spin plots/analysis
  dt <- fread(fpath, select = c("spin", "found", "microstate"))
  return(dt)
}

cat("--- LOADING DATA & DIAGNOSTICS ---\n")
dt_a_0    <- load_experiment_data(target_angles[1], "alice")
dt_a_45   <- load_experiment_data(target_angles[3], "alice")
dt_b_22.5 <- load_experiment_data(target_angles[2], "bob")
dt_b_67.5 <- load_experiment_data(target_angles[4], "bob")

message("✅ Synchronization confirmed.")

# --- 6. PAIRWISE ANALYSIS ---
analyze_pair <- function(name, dt1, dt2) {
  # Filtering for valid Stern-Brocot convergence
  valid <- dt1$found & dt2$found
  if (sum(valid) == 0) return(data.table(Pair=name, Correlation=NA))

  s1 <- as.numeric(dt1$spin[valid])
  s2 <- as.numeric(dt2$spin[valid])
  corr <- mean(s1 * s2)

  return(data.table(
    Pair = name,
    Valid_Pct = sprintf("%5.2f%%", (sum(valid)/length(valid))*100),
    Correlation = sprintf("%6.4f", corr)
  ))
}

results_table <- rbind(
  analyze_pair("Alice(0) vs Bob(22.5)",  dt_a_0,    dt_b_22.5),
  analyze_pair("Alice(0) vs Bob(67.5)",  dt_a_0,    dt_b_67.5),
  analyze_pair("Alice(45) vs Bob(22.5)", dt_a_45,   dt_b_22.5),
  analyze_pair("Alice(45) vs Bob(67.5)", dt_a_45,   dt_b_67.5)
)
print(results_table)

# --- 7. CHSH STATISTIC ---
get_corr <- function(idx) as.numeric(results_table$Correlation[idx])
S_stat <- abs(get_corr(1) - get_corr(2)) + abs(get_corr(3) + get_corr(4))

cat(sprintf("\n--- FINAL RESULT: S_stat = %.4f ---\n", S_stat))

# --- 8. SPIN PLOTS (Discrete Visibility with Percentage Labels) ---
cat("--- GENERATING SPIN PLOTS ---\n")

get_plot_label <- function(dt, angle, observer) {
  rad <- angle * (pi / 180)
  delta_val <- if (observer == "Alice") cos(rad)^2 else sin(rad)^2

  # Calculate Percentages
  total <- nrow(dt)
  p_up   <- (sum(dt$spin == 1) / total) * 100
  p_down <- (sum(dt$spin == -1) / total) * 100

  return(sprintf("%s (%.1f°)\nDelta = %.4f\n↑: %.1f%%  ↓: %.1f%%",
                 observer, angle, delta_val, p_up, p_down))
}

# Apply labels using the full loaded datasets for accurate percentages
label_a0   <- get_plot_label(dt_a_0,    target_angles[1], "Alice")
label_a45  <- get_plot_label(dt_a_45,   target_angles[3], "Alice")
label_b22  <- get_plot_label(dt_b_22.5, target_angles[2], "Bob")
label_b67  <- get_plot_label(dt_b_67.5, target_angles[4], "Bob")

plot_data <- rbind(
  dt_a_0[seq(1, .N, length.out = plot_subsample)][, Label := label_a0],
  dt_a_45[seq(1, .N, length.out = plot_subsample)][, Label := label_a45],
  dt_b_22.5[seq(1, .N, length.out = plot_subsample)][, Label := label_b22],
  dt_b_67.5[seq(1, .N, length.out = plot_subsample)][, Label := label_b67]
)

gp <- ggplot(plot_data, aes(x = microstate, y = factor(spin), color = factor(spin))) +
  geom_jitter(height = 0.25, size = 0.6, alpha = 0.5) +
  facet_wrap(~Label, ncol = 2) +
  scale_color_manual(values = c("-1" = "#e74c3c", "1" = "#3498db"), name = "Spin Outcome") +
  labs(
    title = "The Geometry of Spin: Gaussian to Saddle Transitions",
    subtitle = "Arrows show the percentage of Microstates captured by the Uncertainty Window",
    x = "Microstate (mu)",
    y = "Spin Outcome (+1/-1)"
  ) +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold", size = 10))

# Print to screen
print(gp)

cat(sprintf("✅ PDF with Percentages Saved to: %s\n", desktop_path))
