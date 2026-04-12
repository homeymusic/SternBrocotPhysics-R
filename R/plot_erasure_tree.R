#' Render the Stern-Brocot Erasure Tree Plot
#'
#' @param max_N Integer, maximum depth of the tree. Defaults to 4.
#' @param q_bin Character, binary string for the target path. Defaults to "110".
#' @param q_num Numeric, numerator of the target fraction. Defaults to 3.
#' @param q_den Numeric, denominator of the target fraction. Defaults to 2.
#' @param q_target Numeric, the actual target value (e.g. Golden Ratio). Defaults to (sqrt(5)+1)/2.
#' @param style String, either "manuscript" or "readme".
#' @param base_font String for the font family (e.g., "CMU Serif").
#' @param mono_font String for the monospaced font family (e.g., "CMU Typewriter Text").
#' @import ggplot2
#' @import ggrepel
#' @import dplyr
#' @export
plot_erasure_tree <- function(max_N = 4,
                              q_bin = "110",
                              q_num = 3,
                              q_den = 2,
                              q_target = (sqrt(5)+1)/2,
                              style = c("manuscript", "readme"),
                              base_font = "",
                              mono_font = "") {

  style <- match.arg(style)
  is_ms <- style == "manuscript"
  q_mu_label <- paste0(q_num, "/", q_den)

  # Fallbacks if fonts aren't provided
  if (base_font == "") base_font <- "sans"
  if (mono_font == "") mono_font <- "mono"

  # --- Helper Functions ---
  generate_tree <- function(max_depth) {
    nodes <- list(list(depth = 0, num = 0, den = 1, l_num = -1, l_den = 0, r_num = 1, r_den = 0,
                       bin = "", parent_x = NA_real_, parent_y = NA_real_))
    all_nodes <- nodes
    for (d in 1:max_depth) {
      new_nodes <- list()
      for (node in nodes) {
        left_node <- list(depth = d, num = node$l_num + node$num, den = node$l_den + node$den,
                          l_num = node$l_num, l_den = node$l_den, r_num = node$num, r_den = node$den,
                          bin = paste0(node$bin, "0"), parent_x = node$num / node$den, parent_y = node$depth)
        right_node <- list(depth = d, num = node$num + node$r_num, den = node$den + node$r_den,
                           l_num = node$num, l_den = node$den, r_num = node$r_num, r_den = node$r_den,
                           bin = paste0(node$bin, "1"), parent_x = node$num / node$den, parent_y = node$depth)
        new_nodes <- append(new_nodes, list(left_node, right_node))
      }
      all_nodes <- append(all_nodes, new_nodes)
      nodes <- new_nodes
    }
    dplyr::bind_rows(all_nodes) %>%
      dplyr::mutate(x = num / den, y = depth,
                    frac_label = paste0(num, "/", den),
                    bin_label = ifelse(bin == "", "Thermal State", bin))
  }

  # Dynamically calculate the theoretical SB path for the actual target value
  get_sb_path <- function(target_val, max_d) {
    l_n <- -1; l_d <- 0
    r_n <- 1;  r_d <- 0
    m_n <- 0;  m_d <- 1
    bin_str <- ""
    for (d in 1:max_d) {
      if (target_val > m_n / m_d) {
        l_n <- m_n; l_d <- m_d
        bin_str <- paste0(bin_str, "1")
      } else {
        r_n <- m_n; r_d <- m_d
        bin_str <- paste0(bin_str, "0")
      }
      m_n <- l_n + r_n
      m_d <- l_d + r_d
    }
    return(bin_str)
  }

  # --- Data Preparation ---
  tree_data <- generate_tree(max_N)
  path_bins <- sapply(0:nchar(q_bin), function(i) substr(q_bin, 1, i))

  # --- Dynamic Tolerance Calculation ---
  target_node <- tree_data %>% dplyr::filter(bin == q_bin)
  if (nrow(target_node) == 1 && !is.na(target_node$parent_x)) {
    # Make it just less than the distance to the parent so the parent is strictly excluded
    margin_width <- abs(q_target - target_node$parent_x) * 0.999
  } else {
    margin_width <- 0 # Fallback
  }

  # --- Prune Tree Data (Points & Labels) ---
  target_depth <- nchar(q_bin)
  full_target_path <- get_sb_path(q_target, max_N)
  true_path_bins <- sapply(0:max_N, function(i) substr(full_target_path, 1, i))

  tree_data_pruned <- tree_data %>%
    # Rule 1: Keep everything up to the target depth. For deeper nodes, keep only if inside margin.
    dplyr::filter(depth <= target_depth | (x >= q_target - margin_width & x <= q_target + margin_width)) %>%
    # Rule 2: For deeper nodes, clear labels if they are NOT on the theoretical sequence path
    dplyr::mutate(
      frac_label = ifelse(depth > target_depth & !(bin %in% true_path_bins), "", frac_label),
      bin_label  = ifelse(depth > target_depth & !(bin %in% true_path_bins), "", bin_label)
    )

  path_data <- tree_data_pruned %>%
    dplyr::filter(bin %in% path_bins) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      mid_x = (x + parent_x) / 2,
      mid_y = (y + parent_y) / 2
    ) %>%
    dplyr::ungroup()

  # --- Build Plot ---
  # Feed the pruned dataset to ggplot
  p <- ggplot(tree_data_pruned, aes(x = x, y = y)) +
    # Resolution Band and Target Line (Placed at the bottom layer)
    geom_rect(aes(xmin = q_target - margin_width, xmax = q_target + margin_width, ymin = -Inf, ymax = Inf),
              fill = "gray15", inherit.aes = FALSE) +
    geom_vline(xintercept = q_target, linetype = "dashed", color = "white", linewidth = 0.6) +

    # Tree Elements (Using pruned data)
    geom_segment(aes(xend = parent_x, yend = parent_y), color = "gray85", linewidth = 0.8, na.rm = TRUE) +
    geom_point(color = "gray75", size = 2) +
    geom_segment(data = path_data, aes(xend = parent_x, yend = parent_y), color = "black", linewidth = 1.2, arrow = arrow(length = unit(0.15, "inches"), type = "closed"), na.rm = TRUE) +
    geom_point(data = path_data, color = "black", size = 3.5) +

    # Fraction Labels (Using geom_text_repel for no backgrounds)
    geom_text_repel(data = dplyr::filter(tree_data_pruned, frac_label != ""), aes(label = frac_label), direction = "x", nudge_y = 0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = base_font, color = "black", vjust = 0, box.padding = 0.1, max.overlaps = Inf) +

    # Root Node Label ("Thermal State" -> Serif Font)
    geom_text_repel(data = dplyr::filter(tree_data_pruned, bin == ""), aes(label = bin_label), direction = "x", nudge_y = -0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = base_font, color = "black", vjust = 1, box.padding = 0.1, max.overlaps = Inf) +

    # Binary Strings (Using geom_text_repel for no backgrounds)
    geom_text_repel(data = dplyr::filter(tree_data_pruned, bin != "" & bin_label != ""), aes(label = bin_label), direction = "x", nudge_y = -0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = mono_font, color = "black", vjust = 1, box.padding = 0.1, max.overlaps = Inf) +

    scale_y_continuous(
      breaks = 0:max_N,
      limits = c(-0.3, max_N + 0.3),
      # Changed from "(" * A[L] * ")" to ", " * A[L]
      name = expression("Landauer Action, " * A[L] ~ "[" * k[B] * T ~ "ln 2" ~ tau * "]")
    ) +
    # Changed from "(q/" * q[0] * ")" to ", " * q/q[0]
    scale_x_continuous(breaks = -4:4, name = expression("Position, " * q/q[0]), expand = expansion(mult = 0.05)) +
    theme_minimal(base_family = base_font) +
    theme(panel.grid.minor = element_blank())

  # --- Title Logic ---
  if (!is_ms) {
    p <- p + labs(
      title = "Erasure Tree",
      subtitle = paste0("Highlighting the thermodynamic erasure sequence for q_mu = ", q_mu_label)
    ) +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
        plot.subtitle = element_text(hjust = 0.5)
      )
  } else {
    # Manuscript-specific axis label overrides for italicized formatting
    p <- p + labs(
      x = expression("Position, " * italic(q)/italic(q)[0]),
      y = expression("Landauer Action, " * italic(A)[L] ~ "[" * italic(k)[B] * italic(T) ~ "ln 2" ~ tau * "]")
    )
  }

  return(p)
}
