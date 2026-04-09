#' Render the Stern-Brocot Erasure Tree Plot
#'
#' @param max_k Integer, maximum depth of the tree. Defaults to 4.
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
plot_erasure_tree <- function(max_k = 4,
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

  invert_bit <- function(s) {
    chars <- unlist(strsplit(s, ""))
    paste(ifelse(chars == "1", "0", "1"), collapse = "")
  }

  reverse_string <- function(s) {
    paste(rev(unlist(strsplit(s, ""))), collapse = "")
  }

  # --- Data Preparation ---
  tree_data <- generate_tree(max_k)
  s_star_full <- invert_bit(reverse_string(q_bin))
  path_bins <- sapply(0:nchar(q_bin), function(i) substr(q_bin, 1, i))

  # --- Dynamic Tolerance Calculation ---
  target_node <- tree_data %>% dplyr::filter(bin == q_bin)
  if (nrow(target_node) == 1 && !is.na(target_node$parent_x)) {
    # Make it just less than the distance to the parent so the parent is strictly excluded
    margin_width <- abs(q_target - target_node$parent_x) * 0.999
  } else {
    margin_width <- 0 # Fallback
  }

  path_data <- tree_data %>%
    dplyr::filter(bin %in% path_bins) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      bits_popped = nchar(q_bin) - nchar(bin),
      erase_str = ifelse(!is.na(parent_x), substr(s_star_full, bits_popped + 1, nchar(s_star_full)), ""),
      erase_label = ifelse(erase_str != "", paste0("s*=", erase_str), ""),
      mid_x = (x + parent_x) / 2,
      mid_y = (y + parent_y) / 2
    ) %>%
    dplyr::ungroup()

  # --- Build Plot ---
  p <- ggplot(tree_data, aes(x = x, y = y)) +
    # Resolution Band and Target Line (Placed at the bottom layer)
    geom_rect(aes(xmin = q_target - margin_width, xmax = q_target + margin_width, ymin = -Inf, ymax = Inf),
              fill = "gray90", alpha = 0.5, inherit.aes = FALSE) +
    geom_vline(xintercept = q_target, linetype = "dashed", color = "gray60", linewidth = 0.6) +
    # Tree Elements
    geom_segment(aes(xend = parent_x, yend = parent_y), color = "gray85", linewidth = 0.8, na.rm = TRUE) +
    geom_point(color = "gray75", size = 2) +
    geom_segment(data = path_data, aes(xend = parent_x, yend = parent_y), color = "black", linewidth = 1.2, arrow = arrow(length = unit(0.15, "inches"), type = "closed"), na.rm = TRUE) +
    geom_point(data = path_data, color = "black", size = 3.5) +
    # Highlighted path labels (Action Strings -> Typewriter Font)
    geom_label(data = dplyr::filter(path_data, erase_label != ""), aes(x = mid_x, y = mid_y, label = erase_label), family = mono_font, fontface = "bold", size = 3.5, color = "white", fill = "black", label.size = NA, label.padding = unit(0.2, "lines")) +
    # Fraction Labels (e.g. 3/2 -> Serif Font)
    geom_label_repel(aes(label = frac_label), direction = "x", nudge_y = 0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = base_font, color = "black", fill = "white", label.size = NA, label.padding = unit(0.15, "lines"), vjust = 0, box.padding = 0.1, max.overlaps = Inf) +
    # Root Node Label ("Thermal State" -> Serif Font)
    geom_label_repel(data = dplyr::filter(tree_data, bin == ""), aes(label = bin_label), direction = "x", nudge_y = -0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = base_font, color = "black", fill = "white", label.size = NA, label.padding = unit(0.15, "lines"), vjust = 1, box.padding = 0.1, max.overlaps = Inf) +
    # Binary Strings (e.g. 0110 -> Typewriter Font)
    geom_label_repel(data = dplyr::filter(tree_data, bin != ""), aes(label = bin_label), direction = "x", nudge_y = -0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = mono_font, color = "black", fill = "white", label.size = NA, label.padding = unit(0.15, "lines"), vjust = 1, box.padding = 0.1, max.overlaps = Inf) +

    scale_y_continuous(breaks = 0:max_k, limits = c(-0.3, max_k + 0.3), name = expression("Landauer Action (" * A[L] * ") [" * E[L] * tau * "]")) +
    scale_x_continuous(breaks = -4:4, name = expression("Position (q/" * q[0] * ")"), expand = expansion(mult = 0.05)) +
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
      y = expression("Landauer Action, " * italic(A)[L] ~ "[" ~ italic(E)[L] * tau * "]")
    )
  }

  return(p)
}
