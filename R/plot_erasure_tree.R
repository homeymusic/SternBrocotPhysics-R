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
                    # Wrap the binary string in literal quotes (makes "" for root, "10" for children)
                    bin_label = paste0('"', bin, '"'))
  }

  # --- Data Preparation ---
  # Generate the full tree up to max_N
  tree_data <- generate_tree(max_N)

  # --- Dynamic Tolerance Calculation (Blob Boundaries) ---
  target_node <- tree_data %>% dplyr::filter(bin == q_bin)
  if (nrow(target_node) == 1 && !is.na(target_node$parent_x)) {
    # Make it just less than the distance to the parent so the parent is strictly excluded
    margin_width <- abs(q_target - target_node$parent_x) * 0.999
  } else {
    margin_width <- 0 # Fallback
  }

  # --- Build Plot ---
  p <- ggplot(tree_data, aes(x = x, y = y)) +

    # Blob Boundaries (Dashed Lines)
    geom_vline(xintercept = q_target - margin_width, linetype = "dashed", color = "gray50", linewidth = 0.6) +
    geom_vline(xintercept = q_target + margin_width, linetype = "dashed", color = "gray50", linewidth = 0.6) +

    # Full Tree Elements (Uniform background branches)
    geom_segment(aes(xend = parent_x, yend = parent_y), color = "gray75", linewidth = 0.8, na.rm = TRUE) +
    geom_point(color = "black", size = 2.5) +

    # Fraction Labels (Placed above the nodes)
    geom_text_repel(data = dplyr::filter(tree_data, frac_label != ""), aes(label = frac_label), direction = "x", nudge_y = 0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = base_font, color = "black", vjust = 0, box.padding = 0.1, max.overlaps = Inf) +

    # Quoted Binary String Labels (Placed below ALL nodes, including root)
    geom_text_repel(data = tree_data, aes(label = bin_label), direction = "x", nudge_y = -0.15, segment.color = "gray85", segment.size = 0.2, size = 3.5, family = mono_font, color = "black", vjust = 1, box.padding = 0.1, max.overlaps = Inf) +

    # Axes
    scale_y_continuous(
      breaks = 0:max_N,
      limits = c(-0.3, max_N + 0.3),
      name = expression("Landauer Action, " * A[L] ~ "[" * k[B] * T ~ "ln 2" ~ tau * "]")
    ) +
    scale_x_continuous(breaks = -4:4, name = expression("Position, " * q/q[0]), expand = expansion(mult = 0.05)) +
    theme_minimal(base_family = base_font) +
    theme(panel.grid.minor = element_blank())

  # --- Title Logic ---
  if (!is_ms) {
    p <- p + labs(
      title = "Full Erasure Tree",
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
