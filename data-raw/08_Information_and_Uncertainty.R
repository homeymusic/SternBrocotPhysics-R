library(here)
library(data.table)
library(ggplot2)

here::i_am("data-raw/08_Information_and_Uncertainty.R")

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell_curve"

alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 360, by = 2) + 1e-5

# 1. LOAD DATA & CALCULATE STATISTICS
# We need to process both variables simultaneously to create a unified dataset.

stats_list <- list()

cat("--- PROCESSING CONJUGATE VARIABLES ---\n")

# Process Alice (Baseline)
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
path_a <- file.path(data_dir, f_a)
if (!file.exists(path_a)) stop("Data not found!")

dt_a <- fread(path_a, select = c("uncertainty", "program_length", "found"))
dt_a <- dt_a[found == TRUE]

# Alice Stats (Fixed Baseline)
# We store these to draw horizontal reference lines later
alice_u_med <- median(dt_a$uncertainty)
alice_i_med <- median(dt_a$program_length)

# Process Bob (Sweep)
for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  path_b <- file.path(data_dir, f_b)

  if (file.exists(path_b)) {
    dt_b <- fread(path_b, select = c("uncertainty", "program_length", "found"))
    dt_b <- dt_b[found == TRUE]

    if (nrow(dt_b) > 0) {
      phi <- b_ang - alice_fixed

      # --- VARIABLE 1: UNCERTAINTY (The Aperture) ---
      stats_list[[length(stats_list) + 1]] <- data.table(
        phi      = phi,
        type     = "1. Uncertainty (Delta)",
        median   = median(dt_b$uncertainty),
        lower    = quantile(dt_b$uncertainty, 0.25),
        upper    = quantile(dt_b$uncertainty, 0.75),
        baseline = alice_u_med
      )

      # --- VARIABLE 2: INFORMATION (The Cost) ---
      stats_list[[length(stats_list) + 1]] <- data.table(
        phi      = phi,
        type     = "2. Information (Bits)",
        median   = median(dt_b$program_length),
        lower    = quantile(dt_b$program_length, 0.25),
        upper    = quantile(dt_b$program_length, 0.75),
        baseline = alice_i_med
      )
    }
  }
}

plot_dt <- rbindlist(stats_list)

# 2. CREATE THE CONJUGATE PLOT
# We use Faceting to stack the plots. This aligns the X-axis perfectly.

gp <- ggplot(plot_dt, aes(x = phi)) +

  # --- CONJUGATE MARKERS (The "See-Saw" Axis) ---
  # Vertical lines at 90 and 270 degrees to visually connect the Valley to the Peak
  geom_vline(xintercept = c(90, 270), linetype = "dotted", color = "gray50", size = 0.6) +

  # --- ALICE BASELINE (Reference) ---
  geom_hline(aes(yintercept = baseline), color = "#c0392b", linetype = "dashed", alpha = 0.7) +

  # --- BOB RIBBON (Variance) ---
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = type), alpha = 0.3) +

  # --- BOB MEDIAN (Trend) ---
  geom_line(aes(y = median, color = type), size = 1.2) +

  # --- FACETING (The Magic) ---
  # Stack the plots vertically. Allow free Y scales because they have different units.
  facet_grid(type ~ ., scales = "free_y", switch = "y") +

  # --- AESTHETICS ---
  scale_fill_manual(values = c("1. Uncertainty (Delta)" = "#3498db", "2. Information (Bits)" = "#e67e22")) +
  scale_color_manual(values = c("1. Uncertainty (Delta)" = "#2980b9", "2. Information (Bits)" = "#d35400")) +

  # X-Axis Formatting
  scale_x_continuous(breaks = seq(0, 360, by = 90), labels = c("0", "0.5π", "π", "1.5π", "2π")) +

  # Y-Axis Formatting (Crucial for "Compelling" look)
  # Log scale for Uncertainty (to see the valley), Linear for Info (to see the cost)
  # NOTE: We can't apply different transforms inside facet_grid easily,
  # so we rely on the natural data shape. Uncertainty is naturally logarithmic.

  labs(
    title = "The Conjugate Variables of Action Quanta",
    subtitle = "Top: The Geometric Aperture closes (Uncertainty → 0)\nBottom: The Thermodynamic Cost explodes (Information → ∞)",
    x = "Relative Phase phi (Degrees)",
    y = NULL # Y labels are handled by the facet strips
  ) +

  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(face = "italic", hjust = 0.5, color = "grey30"),
    strip.placement = "outside",      # Move labels to the left
    strip.text = element_text(face = "bold", size = 12),
    strip.background = element_rect(fill = "gray95", color = NA),
    legend.position = "none",         # No legend needed, labels are clear
    panel.grid.minor = element_blank()
  )

# 3. PRINT & SAVE
print(gp)

# Optional: Save for manuscript
# ggsave("manuscript_conjugate_variables.pdf", gp, width = 10, height = 8)
