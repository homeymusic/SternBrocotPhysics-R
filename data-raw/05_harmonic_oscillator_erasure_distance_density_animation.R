library(data.table)
library(ggplot2)
library(gganimate)
library(parallel)
library(av)

# --- 1. Configuration ---
dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"

# Updated to point to the new consolidated generic directories
dir_02_densities <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes     <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")
file_animation   <- file.path(dir_base_data_4TB, "05_harmonic_oscillator_erasure_distance_stern_brocot_animation.mp4")

# File Discovery: STRICT regex to only grab erasure_distance and match the specific algorithm
files_density <- list.files(dir_02_densities, pattern = "^harmonic_oscillator_erasure_distance_density_stern_brocot_P_.*\\.csv\\.gz$", full.names = FALSE)

# Safely extract the momentum string
keys_momentum <- gsub("harmonic_oscillator_erasure_distance_density_stern_brocot_P_|\\.csv\\.gz", "", files_density)

dt_files_to_process <- data.table(key_str = keys_momentum)
dt_files_to_process[, momentum := as.numeric(key_str)]

# Optional: You are sweeping to 10.0 now (~10,000 frames).
# Uncomment this if you want to test a shorter animation first!
# dt_files_to_process <- dt_files_to_process[momentum >= 0.1 & momentum <= 4.0]

setorder(dt_files_to_process, momentum)

cat(sprintf("Processing: %d frames strictly in order (Raw Mode)...\n", nrow(dt_files_to_process)))

# --- 2. Parallel Processing (The Rmd Logic) ---
num_cores <- parallel::detectCores() - 1

list_processed_frames <- mclapply(seq_len(nrow(dt_files_to_process)), function(i) {
  current_row <- dt_files_to_process[i, ]
  momentum_val <- current_row$momentum
  momentum_str <- current_row$key_str

  # Read Density (Injecting algorithm string)
  file_density <- file.path(dir_02_densities, paste0("harmonic_oscillator_erasure_distance_density_stern_brocot_P_", momentum_str, ".csv.gz"))
  dt_histogram_points <- tryCatch({ fread(file_density) }, error = function(e) NULL)
  if (is.null(dt_histogram_points) || nrow(dt_histogram_points) == 0) return(NULL)

  # Trim leading/trailing zeros
  idx_first_active <- which(dt_histogram_points$density_count > 0)[1]
  idx_last_active  <- rev(which(dt_histogram_points$density_count > 0))[1]
  if (is.na(idx_first_active)) return(NULL)
  dt_active_bins <- dt_histogram_points[idx_first_active:idx_last_active]

  # Read Nodes (Injecting algorithm string)
  file_nodes <- file.path(dir_03_nodes, paste0("harmonic_oscillator_erasure_distance_nodes_stern_brocot_P_", momentum_str, ".csv.gz"))
  dt_node_coordinates <- tryCatch({ fread(file_nodes) }, error = function(e) data.table())

  # Extract Metrics
  node_count <- 0
  if (nrow(dt_node_coordinates) > 0 && "node_count" %in% names(dt_node_coordinates)) {
    node_count <- as.integer(dt_node_coordinates$node_count[1])
    dt_node_coordinates <- dt_node_coordinates[!is.na(coordinate_q)] # Remove potential NA placeholders
  }

  max_density_height <- max(dt_active_bins$density_count, na.rm = TRUE)
  raw_coordinate_width <- if(nrow(dt_active_bins) > 1) median(diff(dt_active_bins$coordinate_q), na.rm=TRUE) else 1.0
  max_coordinate_edge <- max(abs(dt_active_bins$coordinate_q), na.rm = TRUE) + (raw_coordinate_width / 2)

  # Synced Label Logic
  lbl <- sprintf("Nodes: %02d  |  Momentum: %3.3f  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 node_count, momentum_val, max_coordinate_edge, format(max_density_height, big.mark=","))

  dt_active_bins[, `:=`(pct_density = (density_count/max_density_height)*100, pct_q = (coordinate_q/max_coordinate_edge)*100)]
  pct_bar_width <- (raw_coordinate_width / max_coordinate_edge) * 100

  # LAYER 1: Fill
  dt_layer_fill <- dt_active_bins[, .(pct_q, pct_density)]
  dt_layer_fill[, `:=`(type = "fill", label = lbl, q_width = pct_bar_width, momentum = momentum_val)]

  # LAYER 2: Step Outline (With zero-padding for clean edges)
  pad_left  <- data.table(pct_q = min(dt_active_bins$pct_q) - pct_bar_width, pct_density = 0)
  pad_right <- data.table(pct_q = max(dt_active_bins$pct_q) + pct_bar_width, pct_density = 0)
  dt_layer_step <- rbind(pad_left, dt_active_bins[, .(pct_q, pct_density)], pad_right)

  # FIX: Changed NA_ to NA_real_
  dt_layer_step[, `:=`(type = "step", label = lbl, q_width = NA_real_, momentum = momentum_val)]

  # LAYER 3: Raw Node Dots (NO PLATEAU CENTERING)
  if (nrow(dt_node_coordinates) > 0) {
    dt_node_coordinates[, `:=`(pct_density = (density_count/max_density_height)*100, pct_q = (coordinate_q/max_coordinate_edge)*100)]
    dt_layer_nodes <- dt_node_coordinates[, .(pct_q, pct_density, is_ghost = FALSE)]
  } else {
    dt_layer_nodes <- data.table(pct_q = 0, pct_density = 0, is_ghost = TRUE)
  }

  # FIX: Changed NA_ to NA_real_
  dt_layer_nodes[, `:=`(type = "nodes", label = lbl, q_width = NA_real_, momentum = momentum_val)]

  return(rbind(dt_layer_fill, dt_layer_step, dt_layer_nodes, fill = TRUE))
}, mc.cores = num_cores)

# --- 3. Stitching & Ordering ---
dt_all_frames <- rbindlist(list_processed_frames, fill = TRUE)
ordered_labels <- unique(dt_all_frames[order(momentum)]$label)
dt_all_frames[, label := factor(label, levels = ordered_labels)]

# --- 4. Animation Design ---
p <- ggplot() +
  # Solid fill (Matches Rmd grey85)
  geom_col(data = dt_all_frames[type == "fill"],
           aes(x = pct_q, y = pct_density, width = q_width, group = label),
           fill = "grey85") +
  # Step outline (Matches Rmd linewidth)
  geom_step(data = dt_all_frames[type == "step"],
            aes(x = pct_q, y = pct_density, group = label),
            color = "black", linewidth = 0.7, direction = "mid") +
  # Raw Hysteresis Nodes
  geom_point(data = dt_all_frames[type == "nodes" & is_ghost == FALSE],
             aes(x = pct_q, y = pct_density, group = label),
             color = "black", size = 3) +
  labs(title = "{current_frame}", x = "Amplitude (%)", y = "Density %") +
  coord_cartesian(xlim = c(-100, 100), ylim = c(0, 105), clip = "on") +
  scale_x_continuous(breaks = seq(-100, 100, 50), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme_minimal() +
  theme(
    plot.title = element_text(family = "mono", face = "bold", size = 11),
    panel.grid.minor = element_blank()
  ) +
  transition_manual(label)

# --- 5. Render ---
# Note: Animating ~10,000 frames at 24fps will be a 6+ minute video and take a while to render!
animate(p, nframes = nrow(dt_files_to_process), fps = 24,
        width = 1600, height = 1000, res = 150,
        renderer = av_renderer(file_animation))

cat("Raw-Data Animation Complete:", file_animation, "\n")
