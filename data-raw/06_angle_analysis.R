# 06_angle_analysis.R
here::i_am("data-raw/06_angle_analysis.R")
library(data.table)
library(ggplot2)

# --- 1. EXPERIMENTAL SETUP ---
data_dir <- "/Volumes/SanDisk4TB/SternBrocot/05_micro_macro_angle_erasures"

# Scan the data repository once to build an index
all_files <- list.files(data_dir, pattern = "theta_.*\\.csv\\.gz$", full.names = TRUE)
file_angles <- as.numeric(gsub(".*theta_([0-9.]+)\\.csv\\.gz", "\\1", all_files))

# Function to load the spin measurement vector for a specific device setting
fetch_angle <- function(target_deg) {
  # Find the file with the closest matching angle
  idx <- which.min(abs(file_angles - target_deg))
  path <- all_files[idx]
  found_angle <- file_angles[idx]

  cat(sprintf("Loaded Run: %.2f deg -> %s\n", found_angle, basename(path)))

  # Return just the measurement column (1, -1, or 0)
  return(data.table::fread(path))
}

# --- 2. RETRIEVE DATA RUNS ---
cat("Fetching experimental data...\n")

A_0  <- fetch_angle(0.0)
A_45 <- fetch_angle(45.0)

B_22 <- fetch_angle(22.5)
B_67 <- fetch_angle(67.5)


# --- 1. TAG THE DATA ---
# We use copy() to ensure we don't modify the original objects by reference
# We add identifying columns to every row.

dt_A0  <- copy(A_0)[,  `:=`(Label = "Alice 0°",    Role = "Alice", Setting = "A_0")]
dt_A45 <- copy(A_45)[, `:=`(Label = "Alice 45°",   Role = "Alice", Setting = "A_45")]
dt_B22 <- copy(B_22)[, `:=`(Label = "Bob 22.5°",   Role = "Bob",   Setting = "B_22")]
dt_B67 <- copy(B_67)[, `:=`(Label = "Bob 67.5°",   Role = "Bob",   Setting = "B_67")]

# --- 2. MERGE INTO MASTER TABLE ---
# rbindlist is highly optimized for this.
# This creates one massive table with ~4 million rows (assuming 1M per file)
master_data <- rbindlist(list(dt_A0, dt_A45, dt_B22, dt_B67))

# Set the factor order so they appear logically in the legend/facets
master_data$Label <- factor(master_data$Label,
                            levels = c("Alice 0°", "Alice 45°", "Bob 22.5°", "Bob 67.5°"))

print(colnames(master_data))

# --- 3. PLOT EVERYTHING (FACETED) ---
ggplot(master_data, aes(x = microstate, y = erasure_distance, color = Role)) +

  # Use very small points with transparency
  geom_point(size = 0.2, alpha = 0.5) +

  # Add the 'zero' line (where spin flips or erasure happens)
  geom_hline(yintercept = 0, color = "black", alpha = 0.3) +

  # Split the view into 4 panels
  facet_wrap(~Label, ncol = 2) +

  # Colors: Distinct for Alice and Bob
  scale_color_manual(values = c("Alice" = "#f7b6d2", "Bob" = "#1f77b4")) +

  labs(
    title = "Fractal Erasure Geometry: Alice vs. Bob",
    subtitle = "Comparing the erasure distance landscape across 4 detector settings",
    x = "Microstate (Hidden Variable)",
    y = "Erasure Distance"
  ) +
  theme_minimal() +
  theme(legend.position = "top")
