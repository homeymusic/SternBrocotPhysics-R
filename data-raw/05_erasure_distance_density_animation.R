library(data.table)
library(ggplot2)
library(gganimate)
library(parallel)

# --- Configuration ---
base_dir       <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir    <- file.path(base_dir, "02_erasure_distance_densities")
nodes_dir      <- file.path(base_dir, "03_erasure_distance_density_nodes")
summary_path   <- file.path(base_dir, "04_erasure_distance_summary.csv.gz")

# Output path
animation_path <- file.path(base_dir, "05_erasure_distance_density_animation.mp4")

# 1. Load summary
dt_summary <- fread(summary_path)

# 2. File Discovery
node_files <- list.files(nodes_dir, pattern = "\\.csv\\.gz$", full.names = FALSE)
file_keys  <- gsub("erasure_distance_nodes_|.csv.gz", "", node_files)

files_to_process <- data.table(key_str = file_keys)
files_to_process[, momentum := as.numeric(gsub("P_", "", key_str))]
files_to_process <- files_to_process[momentum >= 0.5 & momentum <= 4.0]
setorder(files_to_process, momentum)

# SEQUENTIAL SMOKE TEST: First 300 frames
cat(sprintf("Running (%d frames)...\n", nrow(files_to_process)))

# 3. Parallel Processing
num_cores <- parallel::detectCores() - 1
processed_list <- mclapply(seq_len(nrow(files_to_process)), function(i) {
  row_info <- files_to_process[i, ]
  q_val    <- row_info$momentum

  # Read Density
  d_path <- file.path(density_dir, paste0("erasure_distance_density_", row_info$key_str, ".csv.gz"))
  h_pts <- tryCatch({ fread(d_path) }, error = function(e) NULL)
  if (is.null(h_pts) || nrow(h_pts) == 0) return(NULL)

  # STRIP TRAILING ZEROS
  dt_active <- h_pts[density_count > 0]
  if(nrow(dt_active) == 0) return(NULL)

  meta <- dt_summary[abs(normalized_momentum - q_val) < 1e-8][1]
  n_count <- if(nrow(meta) > 0) meta$node_count else 0
  max_h <- max(dt_active$density_count, na.rm = TRUE)

  # True Edge Calculation
  q_diff_raw <- if(nrow(dt_active) > 1) median(diff(dt_active$coordinate_q), na.rm=TRUE) else 1.0
  max_q_edge <- max(abs(dt_active$coordinate_q), na.rm = TRUE) + (q_diff_raw / 2)

  lbl <- sprintf("Nodes: %02d  |  Momentum: %3.3f  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 n_count, q_val, max_q_edge, format(max_h, big.mark=","))

  # Normalize
  dt_active[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q_edge)*100)]
  pct_width <- (q_diff_raw / max_q_edge) * 100

  # --- LAYER 1: FILL (geom_col) ---
  dt_fill <- dt_active[, .(pct_q, pct_density)]
  dt_fill[, `:=`(type = "fill", frame_id = i, label = lbl, is_ghost = FALSE, q_width = pct_width)]

  # --- LAYER 2: STEP OUTLINE (padded) ---
  pad_l <- data.table(pct_q = min(dt_active$pct_q) - pct_width, pct_density = 0)
  pad_r <- data.table(pct_q = max(dt_active$pct_q) + pct_width, pct_density = 0)
  dt_step <- rbind(pad_l, dt_active[, .(pct_q, pct_density)], pad_r)
  dt_step[, `:=`(type = "step", frame_id = i, label = lbl, is_ghost = FALSE, q_width = NA)]

  # --- LAYER 3: NODES (Plateau Centered) ---
  n_path <- file.path(nodes_dir, paste0("erasure_distance_nodes_", row_info$key_str, ".csv.gz"))
  n_pts <- tryCatch({ fread(n_path) }, error = function(e) data.table())

  if (nrow(n_pts) > 0 && "coordinate_q" %in% names(n_pts)) {
    n_pts <- n_pts[!is.na(coordinate_q)]

    # Plateau Detection
    thresh <- max(max_h * 0.015, 5)
    for (r in seq_len(nrow(n_pts))) {
      qn <- n_pts$coordinate_q[r]
      idx <- which(dt_active$coordinate_q == qn)
      if (length(idx) > 0) {
        idx <- idx[1]
        dn <- dt_active$density_count[idx]

        l_idx <- idx
        while(l_idx > 1 && abs(dt_active$density_count[l_idx - 1] - dn) <= thresh) l_idx <- l_idx - 1

        r_idx <- idx
        while(r_idx < nrow(dt_active) && abs(dt_active$density_count[r_idx + 1] - dn) <= thresh) r_idx <- r_idx + 1

        n_pts$coordinate_q[r] <- mean(dt_active$coordinate_q[l_idx:r_idx])
        n_pts$density_count[r] <- mean(dt_active$density_count[l_idx:r_idx])
      }
    }

    n_pts[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q_edge)*100)]
    dt_nodes <- n_pts[, .(pct_q, pct_density)]
    dt_nodes[, is_ghost := FALSE]
  } else {
    dt_nodes <- data.table(pct_q = 0, pct_density = 0, is_ghost = TRUE)
  }
  dt_nodes[, `:=`(type = "nodes", frame_id = i, label = lbl, q_width = NA)]

  return(rbind(dt_fill, dt_step, dt_nodes, fill = TRUE))
}, mc.cores = num_cores)

# 4. Stitching
dt_all <- rbindlist(processed_list, fill = TRUE)
if (nrow(dt_all) == 0) stop("No valid data processed.")

# 5. Animation Construction
p <- ggplot() +

  # SOLID FILL (geom_col creates perfect non-interpolated rectangular steps)
  geom_col(data = dt_all[type == "fill"],
           aes(x = pct_q, y = pct_density, width = q_width, group = label),
           fill = "grey80") +

  # OUTLINE (geom_step traces the outside of the geom_col perfectly)
  geom_step(data = dt_all[type == "step"],
            aes(x = pct_q, y = pct_density, group = label),
            color = "black", linewidth = 0.8, direction = "mid") +

  # NODES (Stabilized against blinking)
  geom_point(data = dt_all[type == "nodes"],
             aes(x = pct_q, y = pct_density, group = label, alpha = !is_ghost),
             color = "black", size = 3) +

  scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0), guide = "none") +
  labs(title = "{current_frame}", x = "Amplitude (%)", y = "Density %") +

  # STRICT BOUNDARIES
  coord_cartesian(xlim = c(-100, 100), ylim = c(0, 105), clip = "on") +
  scale_x_continuous(breaks = seq(-100, 100, 50), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +

  theme_minimal() +
  theme(
    plot.title = element_text(family = "mono", face = "bold", size = 12),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  transition_manual(label)

# 6. Render
animate(p, nframes = length(unique(dt_all$label)), fps = 60, width = 1600, height = 1000, res = 150,
        renderer = av_renderer(animation_path))

cat("Animation Complete: ", animation_path, "\n")
