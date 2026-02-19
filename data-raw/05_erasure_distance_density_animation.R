library(data.table)
library(ggplot2)
library(gganimate)
library(parallel)

# --- Configuration ---
base_dir       <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir    <- file.path(base_dir, "02_erasure_distance_densities")
nodes_dir      <- file.path(base_dir, "03_erasure_distance_density_nodes")
animation_path <- file.path(base_dir, "05_erasure_distance_density_animation.mp4")

# 1. File Discovery
density_files <- list.files(density_dir, pattern = "\\.csv\\.gz$", full.names = FALSE)
file_keys  <- gsub("erasure_distance_density_P_|.csv.gz", "", density_files)

files_to_process <- data.table(key_str = file_keys)
files_to_process[, momentum := as.numeric(key_str)]
files_to_process <- files_to_process[momentum >= 0.5 & momentum <= 4.0]

# Force exact sorting by momentum
setorder(files_to_process, momentum)

cat(sprintf("Processing: %d frames strictly in order...\n", nrow(files_to_process)))

# 2. Parallel Processing
num_cores <- parallel::detectCores() - 1
processed_list <- mclapply(seq_len(nrow(files_to_process)), function(i) {
  row_info <- files_to_process[i, ]
  q_val    <- row_info$momentum

  # Read Density
  d_path <- file.path(density_dir, paste0("erasure_distance_density_P_", row_info$key_str, ".csv.gz"))
  h_pts <- tryCatch({ fread(d_path) }, error = function(e) NULL)
  if (is.null(h_pts) || nrow(h_pts) == 0) return(NULL)

  # Trim leading/trailing zeros
  dt_active <- h_pts[density_count > 0]
  if(nrow(dt_active) == 0) return(NULL)

  # Read Nodes (This provides BOTH the dots and the exact node count)
  n_path <- file.path(nodes_dir, paste0("erasure_distance_nodes_P_", row_info$key_str, ".csv.gz"))
  n_pts <- tryCatch({ fread(n_path) }, error = function(e) data.table())

  # ABSOLUTE TRUTH LOOKUP: Extract node count directly from the node file!
  n_count <- 0
  if (nrow(n_pts) > 0 && "node_count" %in% names(n_pts)) {
    n_count <- as.integer(n_pts$node_count[1])
  }
  if (is.na(n_count)) n_count <- 0

  max_h <- max(dt_active$density_count, na.rm = TRUE)

  # Edge and width math
  q_diff_raw <- if(nrow(dt_active) > 1) median(diff(dt_active$coordinate_q), na.rm=TRUE) else 1.0
  max_q_edge <- max(abs(dt_active$coordinate_q), na.rm = TRUE) + (q_diff_raw / 2)

  # Format Label (Will be used as title)
  lbl <- sprintf("Nodes: %02d  |  Momentum: %3.3f  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 n_count, q_val, max_q_edge, format(max_h, big.mark=","))

  dt_active[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q_edge)*100)]
  pct_width <- (q_diff_raw / max_q_edge) * 100

  # --- LAYER 1: Fill Data ---
  dt_fill <- dt_active[, .(pct_q, pct_density)]
  # We add the pure numeric 'momentum' here so we can sort the factor later!
  dt_fill[, `:=`(type = "fill", label = lbl, q_width = pct_width, momentum = q_val)]

  # --- LAYER 2: Step Outline Data ---
  pad_l <- data.table(pct_q = min(dt_active$pct_q) - pct_width, pct_density = 0)
  pad_r <- data.table(pct_q = max(dt_active$pct_q) + pct_width, pct_density = 0)
  dt_step <- rbind(pad_l, dt_active[, .(pct_q, pct_density)], pad_r)
  dt_step[, `:=`(type = "step", label = lbl, q_width = NA, momentum = q_val)]

  # --- LAYER 3: Node Dots (with Plateau Centering) ---
  if (nrow(n_pts) > 0 && "coordinate_q" %in% names(n_pts)) {
    n_pts <- n_pts[!is.na(coordinate_q)]
    thresh <- max(max_h * 0.015, 5)
    for (r in seq_len(nrow(n_pts))) {
      idx <- which(dt_active$coordinate_q == n_pts$coordinate_q[r])[1]
      if (!is.na(idx)) {
        dn <- dt_active$density_count[idx]
        l_idx <- idx; while(l_idx > 1 && abs(dt_active$density_count[l_idx-1] - dn) <= thresh) l_idx <- l_idx - 1
        r_idx <- idx; while(r_idx < nrow(dt_active) && abs(dt_active$density_count[r_idx+1] - dn) <= thresh) r_idx <- r_idx + 1
        n_pts$coordinate_q[r] <- mean(dt_active$coordinate_q[l_idx:r_idx])
        n_pts$density_count[r] <- mean(dt_active$density_count[l_idx:r_idx])
      }
    }
    n_pts[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q_edge)*100)]
    dt_nodes <- n_pts[, .(pct_q, pct_density, is_ghost = FALSE)]
  } else {
    dt_nodes <- data.table(pct_q = 0, pct_density = 0, is_ghost = TRUE)
  }
  dt_nodes[, `:=`(type = "nodes", label = lbl, q_width = NA, momentum = q_val)]

  return(rbind(dt_fill, dt_step, dt_nodes, fill = TRUE))
}, mc.cores = num_cores)

# 3. Stitching
dt_all <- rbindlist(processed_list, fill = TRUE)

# --- THE FIX FOR THE ANIMATION JUMPING ---
# We force the 'label' to be an ordered factor, strictly based on the numeric momentum value.
# This guarantees gganimate renders the frames from 0.5 to 4.0 in exact order.
ordered_labels <- unique(dt_all[order(momentum)]$label)
dt_all[, label := factor(label, levels = ordered_labels)]

# 4. Animation
p <- ggplot() +
  geom_col(data = dt_all[type == "fill"], aes(x = pct_q, y = pct_density, width = q_width, group = label), fill = "grey80") +
  geom_step(data = dt_all[type == "step"], aes(x = pct_q, y = pct_density, group = label), color = "black", linewidth = 0.8, direction = "mid") +
  geom_point(data = dt_all[type == "nodes"], aes(x = pct_q, y = pct_density, group = label, alpha = !is_ghost), color = "black", size = 3) +
  scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0), guide = "none") +
  labs(title = "{current_frame}", x = "Amplitude (%)", y = "Density %") +
  coord_cartesian(xlim = c(-100, 100), ylim = c(0, 105), clip = "on") +
  scale_x_continuous(breaks = seq(-100, 100, 50), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme_minimal() +
  theme(plot.title = element_text(family = "mono", face = "bold", size = 12), panel.grid.minor = element_blank()) +
  transition_manual(label) # Because label is now an ordered factor, this will play in perfect sequence!

# 5. Render
animate(p, nframes = nrow(files_to_process), fps = 20, width = 1600, height = 1000, res = 150, renderer = av_renderer(animation_path))

cat("Animation Complete:", animation_path, "\n")
