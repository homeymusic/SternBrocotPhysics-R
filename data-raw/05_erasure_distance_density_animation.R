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
animation_path <- file.path(base_dir, "05_erasure_distance_density_5sec_SMOKE.mp4")

# 5-second smoke test (300 frames)
SMOKE_LIMIT <- 300

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
files_to_process <- head(files_to_process, SMOKE_LIMIT)
cat(sprintf("Running TRUE-EDGE SMOKE TEST (%d frames)...\n", nrow(files_to_process)))

# 3. Parallel Processing
num_cores <- parallel::detectCores() - 1
processed_list <- mclapply(seq_len(nrow(files_to_process)), function(i) {
  row_info <- files_to_process[i, ]
  q_val    <- row_info$momentum

  # Read Density
  d_path <- file.path(density_dir, paste0("erasure_distance_density_", row_info$key_str, ".csv.gz"))
  h_pts <- tryCatch({ fread(d_path) }, error = function(e) NULL)
  if (is.null(h_pts) || nrow(h_pts) == 0) return(NULL)

  # Metadata
  meta <- dt_summary[abs(normalized_momentum - q_val) < 1e-8][1]
  n_count <- if(nrow(meta) > 0) meta$node_count else 0

  max_h <- max(h_pts$density_count, na.rm = TRUE)

  # --- 1. ISOLATE ACTIVE DATA ---
  # Remove the trailing zeros that cause the plot to "shrink"
  dt_active <- h_pts[density_count > 0]
  if(nrow(dt_active) == 0) return(NULL)

  # Calculate exact bin width (from the raw file coordinates)
  q_diff <- median(diff(dt_active$coordinate_q), na.rm=TRUE)
  if (is.na(q_diff)) q_diff <- 1.0

  # --- 2. TRUE EDGE NORMALIZATION ---
  # The true physical edge is the center of the last bin + half its width.
  # For Momentum 0.5: max(abs) is 3. Width is 1. True Edge is 3.5.
  max_q_edge <- max(abs(dt_active$coordinate_q)) + (q_diff / 2)

  lbl <- sprintf("Nodes: %02d  |  Momentum: %3.3f  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 n_count, q_val, max_q_edge, format(max_h, big.mark=","))

  # Normalize ONLY the active data to this true edge
  dt_active[, `:=`(pct_density = (density_count/max_h)*100,
                   pct_q = (coordinate_q/max_q_edge)*100)]

  # Convert bin width to percentage terms
  pct_width <- (q_diff / max_q_edge) * 100

  # --- 3. STEP ALIGNMENT ---
  # Pad exactly one bin-width to the left and right at y=0.
  # Because direction="mid" drops halfway between points, this guarantees
  # a perfectly vertical drop at exactly -100 and +100.
  pad_l <- data.table(pct_q = min(dt_active$pct_q) - pct_width, pct_density = 0)
  pad_r <- data.table(pct_q = max(dt_active$pct_q) + pct_width, pct_density = 0)

  dt_step <- rbind(pad_l, dt_active[, .(pct_q, pct_density)], pad_r)
  dt_step[, `:=`(type = "step", frame_id = i, label = lbl, is_ghost = FALSE)]

  # --- 4. NODES ---
  n_path <- file.path(nodes_dir, paste0("erasure_distance_nodes_", row_info$key_str, ".csv.gz"))
  n_pts <- tryCatch({ fread(n_path) }, error = function(e) data.table())

  if (nrow(n_pts) > 0 && "coordinate_q" %in% names(n_pts)) {
    n_pts <- n_pts[!is.na(coordinate_q)]
    # Nodes use the exact same max_q_edge, guaranteeing they are perfectly centered on the plateaus
    n_pts[, `:=`(pct_density = (density_count/max_h)*100,
                 pct_q = (coordinate_q/max_q_edge)*100)]
    dt_nodes <- n_pts[, .(pct_q, pct_density)]
    dt_nodes[, is_ghost := FALSE]
  } else {
    dt_nodes <- data.table(pct_q = 0, pct_density = 0, is_ghost = TRUE)
  }
  dt_nodes[, `:=`(type = "nodes", frame_id = i, label = lbl)]

  return(rbind(dt_step, dt_nodes, fill = TRUE))
}, mc.cores = num_cores)

# 4. Stitching
dt_all <- rbindlist(processed_list, fill = TRUE)
if (nrow(dt_all) == 0) stop("No valid data processed.")

# 5. Animation Construction
p <- ggplot() +
  # STEP LINE
  geom_step(data = dt_all[type == "step"],
            aes(x = pct_q, y = pct_density, group = label),
            color = "black", linewidth = 0.8, direction = "mid") +

  # NODES
  geom_point(data = dt_all[type == "nodes"],
             aes(x = pct_q, y = pct_density, group = label, alpha = !is_ghost),
             color = "black", size = 3) +

  scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0), guide = "none") +
  labs(title = "{current_frame}", x = "Amplitude (%)", y = "Density %") +

  # STRICT BOUNDARIES: Cropping exactly at -100 and 100 hides the pad points
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

cat("True-Edge Smoke Test Complete: ", animation_path, "\n")
