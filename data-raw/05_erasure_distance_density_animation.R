library(data.table)
library(ggplot2)
library(gganimate)
library(parallel)

# --- Configuration: Direct to External Drive ---
base_dir       <- "/Volumes/SanDisk4TB/SternBrocot-data"
density_dir    <- file.path(base_dir, "02_erasure_distance_densities")
nodes_dir      <- file.path(base_dir, "03_erasure_distance_density_nodes")
summary_path   <- file.path(base_dir, "04_erasure_distance_summary.csv.gz")

# Output path on the external drive - Updated for final production
animation_path <- file.path(base_dir, "05_erasure_distance_density_animation.mp4")

# Set to FALSE to run the full thousand-frame sequence
SMOKE_TEST <- FALSE

# 1. Load summary metadata
dt_summary <- fread(summary_path)

# 2. File Discovery (Directory-Driven)
node_files <- list.files(nodes_dir, pattern = "\\.csv\\.gz$", full.names = FALSE)
file_keys  <- gsub("erasure_distance_nodes_", "", node_files)
file_keys  <- gsub("\\.csv\\.gz$", "", file_keys)

# 3. Build Process Driver
files_to_process <- data.table(key_str = file_keys)
files_to_process[, momentum := as.numeric(gsub("P_", "", key_str))]
files_to_process <- files_to_process[momentum >= 0.5 & momentum <= 4.0]

files_to_process[, d_path := file.path(density_dir, paste0("erasure_distance_density_", key_str, ".csv.gz"))]
files_to_process[, n_path := file.path(nodes_dir,   paste0("erasure_distance_nodes_",   key_str, ".csv.gz"))]

setorder(files_to_process, momentum)

# Number of frames logic: Process everything in production
if (SMOKE_TEST) {
  files_to_process <- head(files_to_process, 120)
  cat("Running 2-second SMOKE TEST (120 frames)...\n")
} else {
  cat(sprintf("Starting FULL PRODUCTION run: %d frames total...\n", nrow(files_to_process)))
}

# 4. Parallel Processing with Ghost Point Logic
num_cores <- parallel::detectCores() - 1
processed_list <- mclapply(seq_len(nrow(files_to_process)), function(i) {
  row_info    <- files_to_process[i, ]
  current_key <- row_info$key_str
  q_val       <- row_info$momentum

  h_pts <- tryCatch({ fread(row_info$d_path) }, error = function(e) NULL)
  if (is.null(h_pts) || nrow(h_pts) == 0) return(NULL)

  meta <- dt_summary[abs(normalized_momentum - q_val) < 1e-8][1]
  n_count <- if(nrow(meta) > 0) meta$node_count else 0

  max_h <- max(h_pts$density_count, na.rm = TRUE)
  max_q <- max(abs(h_pts$coordinate_q), na.rm = TRUE)

  # Title Label: Matches README exactly
  lbl <- sprintf("Nodes: %02d  |  Momentum: %3.3f  | Max Amplitude: %4.1f  |  Max Density: %6s",
                 n_count, q_val, max_q, format(max_h, big.mark=","))

  h_pts[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q)*100, frame_id = i, label = lbl)]

  q_diff <- if(nrow(h_pts) > 1) diff(h_pts$pct_q)[1] else 1.0
  pad_l  <- data.table(pct_q = min(h_pts$pct_q) - q_diff, pct_density = 0, frame_id = i, label = lbl)
  pad_r  <- data.table(pct_q = max(h_pts$pct_q) + q_diff, pct_density = 0, frame_id = i, label = lbl)
  h_final <- rbind(pad_l, h_pts[, .(pct_q, pct_density, frame_id, label)], pad_r, fill = TRUE)

  # Node Points + Ghost Point to prevent gganimate mapping errors
  n_pts <- tryCatch({ fread(row_info$n_path) }, error = function(e) data.table())
  if (nrow(n_pts) > 0 && "coordinate_q" %in% names(n_pts)) n_pts <- n_pts[!is.na(coordinate_q)]

  if (nrow(n_pts) == 0) {
    n_final <- data.table(pct_q = 0, pct_density = 0, frame_id = i, label = lbl, is_ghost = TRUE)
  } else {
    n_pts[, `:=`(pct_density = (density_count/max_h)*100, pct_q = (coordinate_q/max_q)*100, frame_id = i, label = lbl, is_ghost = FALSE)]
    n_final <- n_pts[, .(pct_q, pct_density, frame_id, label, is_ghost)]
  }

  return(list(h = h_final, n = n_final, q_diff = q_diff))
}, mc.cores = num_cores)

# 5. Final Stitching
valid <- Filter(Negate(is.null), processed_list)
dt_hist_final <- rbindlist(lapply(valid, `[[`, "h"), fill = TRUE)
dt_node_final <- rbindlist(lapply(valid, `[[`, "n"), fill = TRUE)
global_q_diff <- valid[[1]]$q_diff

# 6. Animation
p <- ggplot() +
  geom_col(data = dt_hist_final[pct_density > 0],
           aes(x = pct_q, y = pct_density, group = label),
           width = global_q_diff, fill = "grey30", alpha = 0.3) +
  geom_step(data = dt_hist_final,
            aes(x = pct_q, y = pct_density, group = label),
            color = "black", linewidth = 0.7, direction = "mid") +
  geom_point(data = dt_node_final,
             aes(x = pct_q, y = pct_density, group = label, alpha = !is_ghost),
             color = "black", size = 3) +
  scale_alpha_manual(values = c("TRUE" = 1, "FALSE" = 0), guide = "none") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey70", linewidth = 0.5) +
  labs(title = "{current_frame}", x = "Amplitude (%)", y = "Density %") +
  coord_cartesian(xlim = c(-105, 105), ylim = c(0, 105)) +
  scale_x_continuous(breaks = seq(-100, 100, 50)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme_minimal() +
  theme(
    plot.title = element_text(family = "mono", face = "bold", size = 12),
    panel.grid.minor = element_blank()
  ) +
  transition_manual(label)

# 7. Render Animation to SanDisk
animate(p, nframes = length(valid), fps = 60, width = 1200, height = 800,
        renderer = av_renderer(animation_path))

cat("Production animation complete: ", animation_path, "\n")
