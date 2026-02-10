library(here)
library(data.table)
library(ggplot2)

here::i_am("data-raw/08_program_length_ribbon.R")

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell_curve"

alice_fixed <- 0.0 + 1e-5
bob_sweep   <- seq(0, 360, by = 2) + 1e-5

# 1. CALCULATE ALICE STATS (BASELINE)
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
path_a <- file.path(data_dir, f_a)

if (!file.exists(path_a)) stop("Data not found! Please run script 07 first.")

dt_a <- fread(path_a, select = c("program_length", "found"))
dt_a <- dt_a[found == TRUE]

# SWITCH TO ROBUST STATS
alice_stats <- list(
  mean   = mean(dt_a$program_length),
  median = median(dt_a$program_length),
  lower  = quantile(dt_a$program_length, 0.25), # 25th Percentile
  upper  = quantile(dt_a$program_length, 0.75)  # 75th Percentile
)

# 2. CALCULATE BOB STATS (SWEEP)
bob_results <- list()

cat("--- ANALYZING PROGRAM LENGTH STATISTICS (ROBUST) ---\n")
for (b_ang in bob_sweep) {
  f_b <- sprintf("erasure_bob_%013.6f.csv.gz", b_ang)
  path_b <- file.path(data_dir, f_b)

  if (file.exists(path_b)) {
    dt_b <- fread(path_b, select = c("program_length", "found"))
    dt_b <- dt_b[found == TRUE]

    if (nrow(dt_b) > 0) {
      phi <- b_ang - alice_fixed

      bob_results[[length(bob_results) + 1]] <- data.table(
        phi    = phi,
        mean   = mean(dt_b$program_length),
        median = median(dt_b$program_length),
        # Robust Quantiles
        lower_bound = quantile(dt_b$program_length, 0.25),
        upper_bound = quantile(dt_b$program_length, 0.75)
      )
    }
  }
}

bob_dt <- rbindlist(bob_results)

# 3. CONSTRUCT THE PLOT DATA STRUCTURE
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
  annotate("text", x = 10, y = alice_stats$median + 1, label = "Alice (Fixed)",
           color = "#c0392b", hjust = 0, fontface="bold") +

  # --- BOB (BLUE DYNAMIC BAND) ---
  geom_ribbon(aes(ymin = lower_bound, ymax = upper_bound), fill = "#3498db", alpha = 0.3) +

  # We keep the Mean line here because seeing the Mean diverge from the Median
  # is a valuable signal of the heavy tail (the "Explosion" of cost).
  geom_line(aes(y = mean), color = "#2980b9", size = 0.8, alpha = 0.8) +
  geom_line(aes(y = median), color = "#2980b9", size = 1, linetype = "dashed") +

  annotate("text", x = 150, y = max(bob_dt$upper_bound, na.rm=TRUE), label = "Bob (Sweeping)",
           color = "#2980b9", hjust = 0.5, fontface="bold") +

  # --- SCALES & LABELS ---
  scale_x_continuous(breaks = seq(0, 360, by = 90), labels = c("0", "0.5π", "π", "1.5π", "2π")) +

  # Optional: Log scale helps if the spikes are massive,
  # but linear scale usually tells the "Cost Explosion" story better.
  # scale_y_log10() +

  labs(
    title = "Thermodynamic Cost of Erasure: Program Length vs. Phase",
    subtitle = "Solid: Mean | Dashed: Median | Ribbon: IQR (25th-75th Percentile)",
    x = "Relative Phase phi (Degrees)",
    y = "Stern-Brocot Program Length (Bits)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none"
  )

print(gp)
