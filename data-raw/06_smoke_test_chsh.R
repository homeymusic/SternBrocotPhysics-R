# 06_smoke_test_chsh.R
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

# --- 2. PREPARE ANGLES ---
granularity <- 1e-5
target_angles <- c(0.0, 45.0, 90.0, 135.0) + granularity

cat("--- GENERATING SMOKE TEST DATA ---\n")
cat("Targets:", paste(target_angles, collapse=", "), "\n")

# --- 3. PREVIEW PHYSICS ---
preview_uncertainty <- function(deg, type) {
  rad <- deg * (pi / 180)
  s <- max(abs(sin(rad)), 1e-15)
  c <- max(abs(cos(rad)), 1e-15)
  if (type == "Alice (Alpha)") return((cos(rad)^2) / s)
  else return((sin(rad)^2) / c)
}

unc_table <- data.table(
  Observer = c("Alice", "Alice", "Bob", "Bob"),
  Angle_Label = c(0, 90, 45, 135),
  Input_Val = c(target_angles[1], target_angles[3], target_angles[2], target_angles[4])
)
unc_table[, Type := ifelse(Observer == "Alice", "Alice (Alpha)", "Bob (Beta)")]
unc_table[, Uncertainty := mapply(preview_uncertainty, Input_Val, Type)]
print(unc_table)

# --- 4. EXECUTE SIMULATION ---
rows_expected <- 1e6 + 1


# HYPOTHESIS TEST: K = 4/pi
# We are testing if this constant "inflates" the square geometry to a circle.
SternBrocotPhysics::micro_macro_erasures_angle(
  angles    = target_angles,
  dir       = normalizePath(smoke_dir, mustWork = TRUE),
  count     = rows_expected,
  K_factor  = 4/pi,    # <--- THE MAGIC NUMBER (approx 1.273)
  n_threads = 4
)

# --- 5. LOADING & DIAGNOSTICS ---
load_experiment_data <- function(angle, type) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", type, angle)
  fpath <- file.path(smoke_dir, fname)
  if (!file.exists(fpath)) stop(paste("Missing:", fpath))

  # Load spin, found, and erasure distance for plotting
  dt <- fread(fpath, select = c("spin", "found", "microstate", "erasure_distance"))
  return(dt)
}

cat("--- LOADING DATA & DIAGNOSTICS ---\n")
dt_a_0   <- load_experiment_data(target_angles[1], "alpha")
dt_a_90  <- load_experiment_data(target_angles[3], "alpha")
dt_b_45  <- load_experiment_data(target_angles[2], "beta")
dt_b_135 <- load_experiment_data(target_angles[4], "beta")

if (nrow(dt_a_0) != rows_expected) stop("FATAL: Dataset size mismatch!")
message("✅ Synchronization confirmed.")

# --- 6. PAIRWISE ANALYSIS TABLE (NEW) ---
cat("\n--- DETAILED PAIRWISE ANALYSIS ---\n")

analyze_pair <- function(name, dt1, dt2) {
  # Filter: Both found, and neither is 0 (valid measurement)
  valid <- dt1$found & dt2$found & (dt1$spin != 0) & (dt2$spin != 0)

  n_total <- length(valid)
  n_valid <- sum(valid)

  if (n_valid == 0) return(data.table(Pair=name, Correlation=NA))

  s1 <- dt1$spin[valid]
  s2 <- dt2$spin[valid]

  # Calculate Agreement Stats
  agree     <- sum(s1 == s2)
  disagree  <- sum(s1 != s2)
  corr      <- mean(s1 * s2)

  return(data.table(
    Pair          = name,
    Valid_Pct     = sprintf("%5.2f%%", (n_valid/n_total)*100),
    Agreement_Pct = sprintf("%5.2f%%", (agree/n_valid)*100),
    Disagree_Pct  = sprintf("%5.2f%%", (disagree/n_valid)*100),
    Correlation   = sprintf("%6.4f", corr)
  ))
}

results_table <- rbind(
  analyze_pair("Alice(0) vs Bob(45)",  dt_a_0,  dt_b_45),
  analyze_pair("Alice(0) vs Bob(135)", dt_a_0,  dt_b_135),
  analyze_pair("Alice(90) vs Bob(45)", dt_a_90, dt_b_45),
  analyze_pair("Alice(90) vs Bob(135)",dt_a_90, dt_b_135)
)

print(results_table)

# --- 7. CHSH STATISTIC ---
# Extract numeric correlations from the table for calculation
get_corr <- function(row_idx) as.numeric(results_table$Correlation[row_idx])

E_0_45   <- get_corr(1)
E_0_135  <- get_corr(2)
E_90_45  <- get_corr(3)
E_90_135 <- get_corr(4)

S_stat <- abs(E_0_45 - E_0_135) + abs(E_90_45 + E_90_135)

cat("\n--- FINAL RESULT ---\n")
cat(sprintf("S_stat = %.4f\n", S_stat))

if (!is.na(S_stat) && S_stat > 2.0) {
  cat("🎉 [PASS] VIOLATION CONFIRMED!\n")
} else {
  cat("❌ [FAIL] CLASSICAL RESULT.\n")
}

# --- 8. PLOTTING ---
cat("\n--- GENERATING PLOTS ---\n")
load_plot_data <- function(dt, label) {
  if (nrow(dt) > 10000) dt <- dt[seq(1, nrow(dt), length.out = 10000)]
  dt[, Label := label]
  return(dt[, .(microstate, erasure_distance, spin, Label)])
}

plot_data <- rbind(
  load_plot_data(dt_a_0, "Alice (0°)"),
  load_plot_data(dt_a_90, "Alice (90°)"),
  load_plot_data(dt_b_45, "Bob (45°)"),
  load_plot_data(dt_b_135, "Bob (135°)")
)

spin_colors <- c("-1" = "#e74c3c", "1" = "#3498db", "0" = "gray50")

gp <- ggplot(plot_data, aes(x = microstate, y = erasure_distance, color = factor(spin))) +
  geom_point(size = 0.5, alpha = 0.6) +
  facet_wrap(~Label, ncol = 2, scales = "free_y") +
  scale_color_manual(values = spin_colors, name = "Spin Result") +
  labs(
    title = "The Geometry of Erasure",
    subtitle = "Mapping Erasure Distance to Spin Outcomes",
    x = "Microstate (mu)",
    y = "Erasure Distance"
  ) +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold", size = 12), legend.position = "bottom")

print(gp)
