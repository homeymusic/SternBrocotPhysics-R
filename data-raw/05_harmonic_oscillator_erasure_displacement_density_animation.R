library(data.table)
library(ggplot2)
library(gganimate)
library(parallel)
library(av)

# --- 1. Configuration ---
dir_base_data_4TB <- "/Volumes/SanDisk4TB/SternBrocot-data"
dir_02_densities <- file.path(dir_base_data_4TB, "02_harmonic_oscillator_densities")
dir_03_nodes     <- file.path(dir_base_data_4TB, "03_harmonic_oscillator_nodes")

# FINAL PRODUCTION FILENAME
file_animation   <- file.path(dir_base_data_4TB, "05_harmonic_oscillator_erasure_displacement.mp4")

# File Discovery
files_density <- list.files(dir_02_densities, pattern = "^harmonic_oscillator_erasure_displacement_density_stern_brocot_P_.*\\.csv\\.gz$", full.names = FALSE)
keys_momentum <- gsub("harmonic_oscillator_erasure_displacement_density_stern_brocot_P_|\\.csv\\.gz", "", files_density)

dt_files_to_process <- data.table(key_str = keys_momentum)
dt_files_to_process[, momentum := as.numeric(key_str)]
setorder(dt_files_to_process, momentum)

cat(sprintf("FINAL PRODUCTION RENDER: Processing %d frames with 25pt margins...\n", nrow(dt_files_to_process)))

# --- 2. Parallel Processing (Full Dataset) ---
num_cores <- parallel::detectCores() - 1

list_processed_frames <- mclapply(seq_len(nrow(dt_files_to_process)), function(i) {
  current_row <- dt_files_to_process[i, ]
  momentum_val <- current_row$momentum
  momentum_str <- current_row$key_str

  # Calculate Action relative to A_0 (where P=0.5 -> A=0.25)
  action_ratio <- 4 * (momentum_val^2)

  # Density Data
  file_density <- file.path(dir_02_densities, paste0("harmonic_oscillator_erasure_displacement_density_stern_brocot_P_", momentum_str, ".csv.gz"))
  dt_histogram_points <- tryCatch({ fread(file_density) }, error = function(e) NULL)
  if (is.null(dt_histogram_points) || nrow(dt_histogram_points) == 0) return(NULL)

  idx_first_active <- which(dt_histogram_points$density_count > 0)[1]
  idx_last_active  <- rev(which(dt_histogram_points$density_count > 0))[1]
  dt_active_bins   <- dt_histogram_points[idx_first_active:idx_last_active]

  # Nodes Data
  file_nodes <- file.path(dir_03_nodes, paste0("harmonic_oscillator_erasure_displacement_nodes_stern_brocot_P_", momentum_str, ".csv.gz"))
  dt_node_coordinates <- tryCatch({ fread(file_nodes) }, error = function(e) data.table())

  node_count <- 0
  if (nrow(dt_node_coordinates) > 0 && "node_count" %in% names(dt_node_coordinates)) {
    node_count <- as.integer(dt_node_coordinates$node_count[1])
    dt_node_coordinates <- dt_node_coordinates[!is.na(coordinate_q)]
  }

  max_density_height <- max(dt_active_bins$density_count, na.rm = TRUE)
  raw_coordinate_width <- if(nrow(dt_active_bins) > 1) median(diff(dt_active_bins$coordinate_q), na.rm=TRUE) else 1.0
  max_coordinate_edge <- max(abs(dt_active_bins$coordinate_q), na.rm = TRUE) + (raw_coordinate_width / 2)

  # Full Scientific Label explicitly labeled with A_0
  lbl <- sprintf("Nodes: %02d  |  Action: %6.1f A_0  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 node_count, action_ratio, max_coordinate_edge, format(max_density_height, big.mark=","))

  dt_active_bins[, `:=`(pct_density = (density_count/max_density_height)*100, pct_q = (coordinate_q/max_coordinate_edge)*100)]

  # Exact Mathematical Skyline Geometry (No geom_col ghosts)
  half_w <- ((raw_coordinate_width / max_coordinate_edge) * 100) / 2

  poly_x <- c(dt_active_bins$pct_q[1] - half_w,
              rep(dt_active_bins$pct_q, each = 2) + rep(c(-half_w, half_w), nrow(dt_active_bins)),
              dt_active_bins$pct_q[nrow(dt_active_bins)] + half_w)

  poly_y <- c(0, rep(dt_active_bins$pct_density, each = 2), 0)

  dt_layer_skyline <- data.table(pct_q = poly_x, pct_density = poly_y)
  dt_layer_skyline[, `:=`(type = "skyline", label = lbl, momentum = momentum_val)]

  # LAYER: Quantum Nodes
  if (nrow(dt_node_coordinates) > 0) {
    dt_node_coordinates[, `:=`(pct_density = (density_count/max_density_height)*100, pct_q = (coordinate_q/max_coordinate_edge)*100)]
    dt_layer_nodes <- dt_node_coordinates[, .(pct_q, pct_density, is_ghost = FALSE)]
  } else {
    dt_layer_nodes <- data.table(pct_q = 0, pct_density = 0, is_ghost = TRUE)
  }
  dt_layer_nodes[, `:=`(type = "nodes", label = lbl, momentum = momentum_val)]

  return(rbind(dt_layer_skyline, dt_layer_nodes, fill = TRUE))
}, mc.cores = num_cores)

# --- 3. Final Stitching ---
dt_all_frames <- rbindlist(list_processed_frames, fill = TRUE)
ordered_labels <- unique(dt_all_frames[order(momentum)]$label)
dt_all_frames[, label := factor(label, levels = ordered_labels)]

# --- 4. Plot Design ---
p <- ggplot() +
  # Draw the Grey Polygon Fill
  geom_polygon(data = dt_all_frames[type == "skyline"],
               aes(x = pct_q, y = pct_density, group = label),
               fill = "grey85", color = NA) +
  # Draw the Black Staircase Outline over the Polygon
  geom_path(data = dt_all_frames[type == "skyline"],
            aes(x = pct_q, y = pct_density, group = label),
            color = "black", linewidth = 0.7) +
  # Draw the Nodes
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
    panel.grid.minor = element_blank(),
    plot.margin = margin(t = 25, r = 25, b = 25, l = 25),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  transition_manual(label)

# --- 5. Render (The Long Haul) ---
animate(p, nframes = nrow(dt_files_to_process), fps = 24,
        width = 1600, height = 1000, res = 150,
        renderer = av_renderer(file_animation))

cat("Production Render Complete:", file_animation, "\n")
