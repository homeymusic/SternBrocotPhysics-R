library(data.table)
library(ggplot2)
library(gganimate)
library(parallel)

# --- 1. Configuration ---
base_dir       <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir    <- file.path(base_dir, "02_erasure_distance_densities")
nodes_dir      <- file.path(base_dir, "03_erasure_distance_density_nodes")
animation_path <- file.path(base_dir, "05_erasure_distance_density_animation.mp4")

# File Discovery
density_files <- list.files(density_dir, pattern = "\\.csv\\.gz$", full.names = FALSE)
file_keys     <- gsub("erasure_distance_density_P_|.csv.gz", "", density_files)

files_to_process <- data.table(key_str = file_keys)
files_to_process[, momentum := as.numeric(key_str)]
files_to_process <- files_to_process[momentum >= 0.5 & momentum <= 4.0]

setorder(files_to_process, momentum)

cat(sprintf("Processing: %d frames strictly in order (Raw Mode)...\n", nrow(files_to_process)))

# --- 2. Parallel Processing (The Rmd Logic) ---
num_cores <- parallel::detectCores() - 1
processed_list <- mclapply(seq_len(nrow(files_to_process)), function(i) {
  row_info <- files_to_process[i, ]
  q_val    <- row_info$momentum

  # Read Density
  d_path <- file.path(density_dir, paste0("erasure_distance_density_P_", row_info$key_str, ".csv.gz"))
  h_pts <- tryCatch({ fread(d_path) }, error = function(e) NULL)
  if (is.null(h_pts) || nrow(h_pts) == 0) return(NULL)

  # Trim leading/trailing zeros
  first_nz <- which(h_pts$density_count > 0)[1]
  last_nz  <- rev(which(h_pts$density_count > 0))[1]
  if (is.na(first_nz)) return(NULL)
  dt_active <- h_pts[first_nz:last_nz]

  # Read Nodes (Raw coordinates from 03 files)
  n_path <- file.path(nodes_dir, paste0("erasure_distance_nodes_P_", row_info$key_str, ".csv.gz"))
  n_pts <- tryCatch({ fread(n_path) }, error = function(e) data.table())

  # Extract Metrics
  n_count <- 0
  if (nrow(n_pts) > 0 && "node_count" %in% names(n_pts)) {
    n_count <- as.integer(n_pts$node_count[1])
    n_pts <- n_pts[!is.na(coordinate_q)] # Remove potential NA placeholders
  }

  max_h <- max(dt_active$density_count, na.rm = TRUE)
  q_diff_raw <- if(nrow(dt_active) > 1) median(diff(dt_active$coordinate_q), na.rm=TRUE) else 1.0
  max_q_edge <- max(abs(dt_active$coordinate_q), na.rm = TRUE) + (q_diff_raw / 2)

  # Synced Label Logic
  lbl <- sprintf("Nodes: %02d  |  Momentum: %3.3f  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 n_count, q_val, max_q_edge, format(max_h, big.mark=","))

  dt_active[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q_edge)*100)]
  pct_width <- (q_diff_raw / max_q_edge) * 100

  # LAYER 1: Fill
  dt_fill <- dt_active[, .(pct_q, pct_density)]
  dt_fill[, `:=`(type = "fill", label = lbl, q_width = pct_width, momentum = q_val)]

  # LAYER 2: Step Outline (With zero-padding for clean edges)
  pad_l <- data.table(pct_q = min(dt_active$pct_q) - pct_width, pct_density = 0)
  pad_r <- data.table(pct_q = max(dt_active$pct_q) + pct_width, pct_density = 0)
  dt_step <- rbind(pad_l, dt_active[, .(pct_q, pct_density)], pad_r)
  dt_step[, `:=`(type = "step", label = lbl, q_width = NA, momentum = q_val)]

  # LAYER 3: Raw Node Dots (NO PLATEAU CENTERING)
  if (nrow(n_pts) > 0) {
    n_pts[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q_edge)*100)]
    dt_nodes <- n_pts[, .(pct_q, pct_density, is_ghost = FALSE)]
  } else {
    dt_nodes <- data.table(pct_q = 0, pct_density = 0, is_ghost = TRUE)
  }
  dt_nodes[, `:=`(type = "nodes", label = lbl, q_width = NA, momentum = q_val)]

  return(rbind(dt_fill, dt_step, dt_nodes, fill = TRUE))
}, mc.cores = num_cores)

# --- 3. Stitching & Ordering ---
dt_all <- rbindlist(processed_list, fill = TRUE)
ordered_labels <- unique(dt_all[order(momentum)]$label)
dt_all[, label := factor(label, levels = ordered_labels)]

# --- 4. Animation Design ---
p <- ggplot() +
  # Solid fill (Matches Rmd grey85)
  geom_col(data = dt_all[type == "fill"],
           aes(x = pct_q, y = pct_density, width = q_width, group = label),
           fill = "grey85") +
  # Step outline (Matches Rmd linewidth)
  geom_step(data = dt_all[type == "step"],
            aes(x = pct_q, y = pct_density, group = label),
            color = "black", linewidth = 0.7, direction = "mid") +
  # Raw Hysteresis Nodes
  geom_point(data = dt_all[type == "nodes"],
             aes(x = pct_q, y = pct_density, group = label, alpha = !is_ghost),
             color = "black", size = 3) +
  scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0), guide = "none") +
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
animate(p, nframes = nrow(files_to_process), fps = 24,
        width = 1600, height = 1000, res = 150,
        renderer = av_renderer(animation_path))

cat("Raw-Data Animation Complete:", animation_path, "\n")
