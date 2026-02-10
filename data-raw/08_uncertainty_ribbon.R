library(here)
library(data.table)
library(ggplot2)

here::i_am("data-raw/08_uncertainty_ribbon.R")

# --- CONFIGURATION ---
# We use the same data directory as the previous step
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell_curve"

alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 360, by = 2) + 1e-5

# 1. CALCULATE ALICE STATS (BASELINE)
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
path_a <- file.path(data_dir, f_a)

if (!file.exists(path_a)) stop("Data not found! Please run step 07 first.")

# Load 'uncertainty' instead of 'program_length'
dt_a <- fread(path_a, select = c("uncertainty", "found"))
dt_a <- dt_a[found == TRUE]

# Use ROBUST Statistics (Median + Quantiles) instead of Mean/SD
alice_stats <- list(
  mean   = mean(dt_a$uncertainty),
  median = median(dt_a$uncertainty),
  lower  = quantile(dt_a$uncertainty, 0.25), # 25th Percentile
  upper  = quantile(dt_a$uncertainty, 0.75)  # 75th Percentile
)

# 2. CALCULATE BOB STATS (SWEEP)
bob_results <- list()

cat("--- ANALYZING UNCERTAINTY STATISTICS (ROBUST) ---\n")

for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  path_b <- file.path(data_dir, f_b)

  if (file.exists(path_b)) {
    dt_b <- fread(path_b, select = c("uncertainty", "found"))
    dt_b <- dt_b[found == TRUE]

    if (nrow(dt_b) > 0) {
      phi <- b_ang - alice_fixed

      # Store robust statistics for this angle
      bob_results[[length(bob_results) + 1]] <- data.table(
        phi    = phi,
        mean   = mean(dt_b$uncertainty),
        median = median(dt_b$uncertainty),
        # The IQR (Interquartile Range) is safer for heavy tails
        lower_bound = quantile(dt_b$uncertainty, 0.25),
        upper_bound = quantile(dt_b$uncertainty, 0.75)
      )
    }
  }
}

bob_dt <- rbindlist(bob_results)

# 3. CONSTRUCT PLOT DATA
bob_dt[, `:=`(
  alice_median = alice_stats$median,
  alice_upper  = alice_stats$upper,
  alice_lower  = alice_stats$lower
)]

# 4. RENDER THE RIBBON PLOT
gp <- ggplot(bob_dt, aes(x = phi)) +

  # --- ALICE (RED/PINK CONSTANT BAND) ---
  geom_ribbon(aes(ymin = alice_lower, ymax = alice_upper), fill = "#e74c3c", alpha = 0.2) +
  geom_hline(yintercept = alice_stats$median, color = "#c0392b", linetype = "dashed", size = 0.8) +
  annotate("text", x = 10, y = alice_stats$median, label = "Alice (Fixed)",
           color = "#c0392b", hjust = 0, vjust = -1, fontface="bold") +

  # --- BOB (BLUE DYNAMIC BAND) ---
  # Ribbon now represents the middle 50% of the data (IQR)
  geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound), fill = "#3498db", alpha = 0.4) +

  # We plot Median (dashed) as the primary trend line because Mean explodes
  geom_line(aes(y = median), color = "#2980b9", size = 1, linetype = "solid") +

  annotate("text", x = 180, y = max(bob_dt$upper_bound, na.rm=TRUE), label = "Bob (Sweeping)",
           color = "#2980b9", hjust = 0.5, vjust = -1, fontface="bold") +

  # --- SCALES & LABELS ---
  scale_x_continuous(breaks = seq(0, 360, by = 90),
                     labels = c("0", "0.5π", "π", "1.5π", "2π")) +

  # A Log Scale is HIGHLY recommended for Uncertainty to visualize both
  # the tiny singularity (1e-9) and the massive aperture (1e9)
  scale_y_log10() +

  labs(
    title = "Detector Uncertainty (Delta) vs. Phase",
    subtitle = "Solid Line: Median | Ribbon: Interquartile Range (25th-75th Percentile)",
    x = "Relative Phase phi (Degrees)",
    y = "Uncertainty Delta (Log Scale)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none"
  )

print(gp)
