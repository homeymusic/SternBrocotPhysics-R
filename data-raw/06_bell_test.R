here::i_am("data-raw/06_bell_test.R")
library(data.table)
library(ggplot2)
library(SternBrocotPhysics)

# --- CONFIGURATION ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_bell_test"
rows_to_sweep <- 1e6
plot_subsample <- 5000

# 1. CLEAN SLATE
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)
unlink(list.files(data_dir, full.names = TRUE))

# 2. THE EXPLICIT PAIRINGS (Alice Angle, Bob Angle)
# We add 1e-5 to avoid exact boundary floating point issues if necessary
angle_pairs <- list(
  c(0.0, 90.0),
  c(22.5, 67.5),
  c(45.0, 45.0),
  c(67.5, 22.5),
  c(90.0, 0.0)
)

# Flatten pairs to get unique angles for the generation step
unique_angles <- unique(unlist(angle_pairs)) + 1e-5

# 3. GENERATE DETERMINISTIC DATA
cat("--- GENERATING DETERMINISTIC THERMAL MANIFOLD ---\n")
SternBrocotPhysics::micro_macro_bell_erasure_sweep(
  angles = unique_angles,
  dir = normalizePath(data_dir, mustWork = TRUE),
  count = rows_to_sweep,
  n_threads = 4
)

# 4. LOAD, AGGREGATE, AND ORDERING
all_data_list <- list()
population_stats <- list()
facet_order <- c() # This will store the labels in the exact order for the plot

cat("\n--- CALCULATING SPIN POPULATIONS ---\n")

for(pair in angle_pairs) {
  # For each pair, we process Alice then Bob to lock them side-by-side
  for(i in 1:2) {
    obs <- if(i == 1) "Alice" else "Bob"
    ang <- pair[i] + 1e-5

    f_name <- sprintf("erasure_%s_%013.6f.csv.gz", tolower(obs), ang)
    dt <- fread(file.path(data_dir, f_name), select = c("mu", "spin", "found"))

    total_found <- sum(dt$found)
    p_up   <- (sum(dt$spin == 1 & dt$found) / total_found) * 100
    p_down <- (sum(dt$spin == -1 & dt$found) / total_found) * 100

    # Create the label
    label <- sprintf("%s (%.1f°)\n↑: %.1f%% | ↓: %.1f%%", obs, ang, p_up, p_down)

    # Store label for factor ordering
    facet_order <- c(facet_order, label)

    # Store stats for the table
    population_stats[[paste0(obs, ang)]] <- data.table(
      Observer = obs,
      Angle = round(ang, 1),
      `Spin_Up_%` = sprintf("%.2f%%", p_up),
      `Spin_Down_%` = sprintf("%.2f%%", p_down)
    )

    # Subsample for plotting
    sub_dt <- dt[seq(1, .N, length.out = plot_subsample)]
    sub_dt[, `:=`(Observer = obs, Angle = ang, FacetLabel = label)]
    all_data_list[[paste0(obs, ang)]] <- sub_dt
  }
}

plot_dt <- rbindlist(all_data_list)
pop_table <- rbindlist(population_stats)

# CRITICAL: Force the FacetLabel into the specific order defined by our loop
plot_dt[, FacetLabel := factor(FacetLabel, levels = facet_order)]

# 5. RENDER THE POPULATION TABLE
print("--- OBSERVER SPIN POPULATION TABLE ---")
print(pop_table)

# 6. RENDER THE PLOT
gp <- ggplot(plot_dt, aes(x = mu, y = factor(spin), color = factor(spin))) +
  geom_jitter(height = 0.2, alpha = 0.4, size = 0.8) +
  # ncol = 2 uses the factor levels to put A on left, B on right
  facet_wrap(~FacetLabel, ncol = 2) +
  scale_color_manual(values = c("-1" = "#e74c3c", "1" = "#3498db"), guide = "none") +
  scale_x_continuous(breaks = c(-pi, 0, pi), labels = c("-π", "0", "π")) +
  labs(
    title = "Macrostate Outcomes vs. Microstate (mu)",
    subtitle = "Paired Angles: Alice (Left) vs. Bob (Right)",
    x = "Action Quanta (Microstate mu)",
    y = "Observable Spin Outcome"
  ) +
  theme_minimal() +
  theme(
    strip.text = element_text(face = "bold"),
    panel.spacing = unit(1, "lines")
  )

print(gp)
