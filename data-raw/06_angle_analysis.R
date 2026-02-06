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
# --- 1. SETUP & DATA RETRIEVAL ---
cat("Fetching experimental data...\n")

# Assumes fetch_angle() is defined in your environment
A_0  <- fetch_angle(0.0)
A_45 <- fetch_angle(45.0)

B_22 <- fetch_angle(22.5)
B_67 <- fetch_angle(67.5)

# --- 2. CALCULATE CORRELATIONS (E1, E2, E3, E4) ---

# --- E1: Correlation (Alice 0° vs Bob 22.5°) ---
raw_products <- A_0$spin * B_22$spin
valid_products <- raw_products[raw_products != 0]
E_0_22 <- mean(valid_products)
print(paste("Correlation E1 (0, 22.5):", E_0_22))

# --- E2: Correlation (Alice 0° vs Bob 67.5°) ---
raw_products <- A_0$spin * B_67$spin
valid_products <- raw_products[raw_products != 0]
E_0_67 <- mean(valid_products)
print(paste("Correlation E2 (0, 67.5):", E_0_67))

# --- E3: Correlation (Alice 45° vs Bob 22.5°) ---
raw_products <- A_45$spin * B_22$spin
valid_products <- raw_products[raw_products != 0]
E_45_22 <- mean(valid_products)
print(paste("Correlation E3 (45, 22.5):", E_45_22))

# --- E4: Correlation (Alice 45° vs Bob 67.5°) ---
raw_products <- A_45$spin * B_67$spin
valid_products <- raw_products[raw_products != 0]
E_45_67 <- mean(valid_products)
print(paste("Correlation E4 (45, 67.5):", E_45_67))


# --- 3. CALCULATE FINAL CHSH SCORE ---

# Formula: S = |E1 - E2| + |E3 + E4|
# E1 = E(0, 22.5)
# E2 = E(0, 67.5)
# E3 = E(45, 22.5)
# E4 = E(45, 67.5)

S_score <- abs(E_0_22 - E_0_67) + abs(E_45_22 + E_45_67)

print("------------------------------------------------")
print(paste("Final CHSH Score (S):", S_score))
print("------------------------------------------------")
print("Interpretation:")
print("S <= 2.0 : Classical Limit (Local Realism)")
print("S >  2.0 : Quantum Violation (Bell Inequality Broken)")
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


# Create the "Distance" layer (The Analog Wave)
dt_dist <- master_data[, .(microstate, value = erasure_distance, Label, Role, Type = "Distance")]

# Create the "Spin" layer (The Digital Particle)
# This now includes 0, 1, and -1
dt_spin <- master_data[, .(microstate, value = spin, Label, Role, Type = "Spin")]

# Combine them into one long table for ggplot
plot_data <- rbind(dt_dist, dt_spin)

# Define the grouping column for the legend
plot_data[, Category := paste(Role, Type)]

# --- 2. THE STRICT 4-COLOR PALETTE ---
# The color depends ONLY on Role (Alice/Bob) and Type (Distance/Spin)
# It does NOT change based on the value (1, -1, 0)
custom_colors <- c(
  "Alice Distance" = "#ff99cc",  # Light Pink
  "Alice Spin"     = "#c51b7d",  # Dark Pink

  "Bob Distance"   = "#aec7e8",  # Light Blue
  "Bob Spin"       = "#1f77b4"   # Dark Blue
)

# --- 3. GENERATE THE ERASURE PLOT ---
ggplot(plot_data, aes(x = microstate, y = value, color = Category)) +

  # The Zero Line (Reference)
  geom_hline(yintercept = 0, color = "black", alpha = 0.3) +

  # The Points
  # We use very small points.
  # Light points (Distance) show the geometry.
  # Dark points (Spin) show the outcome (at 1, -1, or 0).
  geom_point(size = 0.3, alpha = 0.6) +

  # Facet by Detector Setting to compare the 4 angles
  facet_wrap(~Label, ncol = 2) +

  # Apply the strict color mapping
  scale_color_manual(values = custom_colors) +

  # Zoom in vertically to see the transition (-1.5 to 1.5)
  coord_cartesian(ylim = c(-1.5, 1.5)) +

  labs(
    title = "Quantum Measurement: The Wave vs. The Collapse",
    subtitle = "Light Wave = Erasure Distance | Dark Points = Spin Outcome (+1, -1, or 0)",
    x = "Microstate",
    y = "Value (Distance or Spin)"
  ) +

  theme_minimal() +
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    panel.grid.minor = element_blank()
  ) +

  guides(color = guide_legend(override.aes = list(size = 3, alpha = 1)))



# Create the "Distance" layer (The Analog Wave)
dt_dist <- master_data[, .(microstate, value = macrostate, Label, Role, Type = "Macrostate")]

# Create the "Spin" layer (The Digital Particle)
# This now includes 0, 1, and -1
dt_spin <- master_data[, .(microstate, value = spin, Label, Role, Type = "Spin")]

# Combine them into one long table for ggplot
plot_data <- rbind(dt_dist, dt_spin)

# Define the grouping column for the legend
plot_data[, Category := paste(Role, Type)]

# --- 3. GENERATE THE MACROSTATE PLOT ---
ggplot(plot_data, aes(x = microstate, y = value, color = Category)) +

  # The Zero Line (Reference)
  geom_hline(yintercept = 0, color = "black", alpha = 0.3) +

  # The Points
  # We use very small points.
  # Light points (Distance) show the geometry.
  # Dark points (Spin) show the outcome (at 1, -1, or 0).
  geom_point(size = 0.3, alpha = 0.6) +

  # Facet by Detector Setting to compare the 4 angles
  facet_wrap(~Label, ncol = 2) +

  # Apply the strict color mapping
  scale_color_manual(values = custom_colors) +

  # Zoom in vertically to see the transition (-1.5 to 1.5)
  coord_cartesian(ylim = c(-1.5, 1.5)) +

  labs(
    title = "Quantum Measurement: The Wave vs. The Collapse",
    subtitle = "Light Wave = Erasure Distance | Dark Points = Spin Outcome (+1, -1, or 0)",
    x = "Microstate",
    y = "Value (Macrostate or Spin)"
  ) +

  theme_minimal() +
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    panel.grid.minor = element_blank()
  ) +

  guides(color = guide_legend(override.aes = list(size = 3, alpha = 1)))
