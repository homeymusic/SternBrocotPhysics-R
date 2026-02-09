here::i_am("data-raw/08_program_length_ribbon.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/07_canonical_bell_curve"
# Note: We reuse the data from step 07 to save time.
# If you haven't run 07, uncomment the generation block below.

alice_fixed <- 0.0 + 1e-5
bob_sweep <- seq(0, 360, by = 2) + 1e-5

# --- (OPTIONAL) GENERATE DATA IF MISSING ---
# if (!dir.exists(data_dir)) {
#   dir.create(data_dir, recursive = TRUE)
#   all_angles <- sort(unique(c(alice_fixed, bob_sweep)))
#   SternBrocotPhysics::micro_macro_bell_erasure_sweep(all_angles, data_dir, 1e5, 6)
# }

# 1. CALCULATE ALICE STATS (BASELINE)
# Alice is fixed at 0 degrees, so her stats are constant across the plot
f_a <- sprintf("erasure_alice_%013.6f.csv.gz", alice_fixed)
path_a <- file.path(data_dir, f_a)

if (!file.exists(path_a)) stop("Data not found! Please run script 07 first.")

dt_a <- fread(path_a, select = c("program_length", "found"))
dt_a <- dt_a[found == TRUE] # Only analyze successful erasures

alice_stats <- list(
  mean   = mean(dt_a$program_length),
  median = median(dt_a$program_length),
  sd     = sd(dt_a$program_length)
)

# 2. CALCULATE BOB STATS (SWEEP)
bob_results <- list()

cat("--- ANALYZING PROGRAM LENGTH STATISTICS ---\n")
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
        sd     = sd(dt_b$program_length)
      )
    }
  }
}

bob_dt <- rbindlist(bob_results)

# 3. CONSTRUCT THE PLOT DATA STRUCTURE
# We add Alice's constant stats as columns to Bob's table for easy plotting
bob_dt[, `:=`(
  alice_mean = alice_stats$mean,
  alice_upper = alice_stats$mean + alice_stats$sd,
  alice_lower = alice_stats$mean - alice_stats$sd,
  bob_upper = mean + sd,
  bob_lower = mean - sd
)]

# 4. RENDER THE RIBBON PLOT
gp <- ggplot(bob_dt, aes(x = phi)) +

  # --- ALICE (RED/PINK CONSTANT BAND) ---
  geom_ribbon(aes(ymin = alice_lower, ymax = alice_upper), fill = "#e74c3c", alpha = 0.2) +
  geom_hline(yintercept = alice_stats$mean, color = "#c0392b", linetype = "solid", size = 0.8) +
  geom_hline(yintercept = alice_stats$median, color = "#c0392b", linetype = "dashed", size = 0.8) +
  annotate("text", x = 10, y = alice_stats$mean + 1, label = "Alice (Fixed)", color = "#c0392b", hjust = 0, fontface="bold") +

  # --- BOB (BLUE DYNAMIC BAND) ---
  geom_ribbon(aes(ymin = bob_lower, ymax = bob_upper), fill = "#3498db", alpha = 0.3) +
  geom_line(aes(y = mean), color = "#2980b9", size = 1) +
  geom_line(aes(y = median), color = "#2980b9", size = 1, linetype = "dashed") +
  annotate("text", x = 150, y = max(bob_dt$bob_upper), label = "Bob (Sweeping)", color = "#2980b9", hjust = 0.5, fontface="bold") +

  # --- SCALES & LABELS ---
  scale_x_continuous(breaks = seq(0, 360, by = 90), labels = c("0", "0.5π", "π", "1.5π", "2π")) +
  labs(
    title = "Thermodynamic Cost of Erasure: Program Length vs. Phase",
    subtitle = "Solid Line: Mean | Dashed Line: Median | Ribbon: Mean ± 1 SD",
    x = "Relative Phase phi (Degrees)",
    y = "Stern-Brocot Program Length (Bits)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none"
  )

print(gp)
