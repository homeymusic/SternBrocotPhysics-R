Stern-Brocot Physics
================

An R package for computational experiments in classical and quantum
physics using the Stern-Brocot tree.

![](man/figures/README-plot-landauer-squeeze-1.png)<!-- -->

    #> Called from: generate_physics_grid(jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1

![](man/figures/README-jump-fluctuations-1.png)<!-- -->

    #> Called from: generate_physics_grid(subset_jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(subset_jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(subset_jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: node_label <- "NA"
    #> debug: dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(subset_jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(subset_jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: dot_df <- rbind(res_l, res_r)
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> Called from: generate_physics_grid(subset_jumps)
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1
    #> debug: current_p <- jumps_subset[[j]]$p_vals[p]
    #> debug: f_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(current_p, 
    #>     6))
    #> debug: f_path <- here::here("data-raw", "outputs", "01_micro_macro_erasures", 
    #>     f_name)
    #> debug: action <- current_p * current_p
    #> debug: if (file.exists(f_path) && current_p >= 1) {
    #>     raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>         action
    #>     f_range <- range(raw_fluc, na.rm = TRUE)
    #>     panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #>     h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #>     plot_df <- data.frame(x = h$mids, y = h$counts)
    #>     browser()
    #>     res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #>     res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #>     if (is.null(res_r) || is.null(res_l)) {
    #>         node_label <- "NA"
    #>         dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #>     }
    #>     else {
    #>         if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>             inner_l <- res_l[which.max(res_l$x), ]
    #>             inner_r <- res_r[which.min(res_r$x), ]
    #>             y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>             if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>                 center_dot <- data.frame(x = 0, y = y_center)
    #>                 dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                   ], res_r[res_r$x > inner_r$x, ])
    #>             }
    #>             else {
    #>                 dot_df <- rbind(res_l, res_r)
    #>             }
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>         node_label <- as.character(nrow(dot_df))
    #>     }
    #>     dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #>     p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>         ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), 
    #>             fill = "black", alpha = 0.3) + ggplot2::geom_step(direction = "hv", 
    #>         color = "black", linewidth = 0.2) + ggplot2::geom_point(data = dot_df, 
    #>         color = "red", size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>         " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>         x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> } else {
    #>     p_obj <- ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, 
    #>         y = 0.5, label = paste("P =", sprintf("%.2f", current_p), 
    #>             "\n excluded")) + ggplot2::theme_void()
    #> }
    #> debug: raw_fluc <- data.table::fread(f_path, select = "fluctuation")$fluctuation * 
    #>     action
    #> debug: f_range <- range(raw_fluc, na.rm = TRUE)
    #> debug: panel_breaks <- seq(from = f_range[1], to = f_range[2], length.out = 402)
    #> debug: h <- graphics::hist(raw_fluc, breaks = panel_breaks, plot = FALSE)
    #> debug: plot_df <- data.frame(x = h$mids, y = h$counts)
    #> debug: browser()
    #> debug: res_r <- find_nodes_outward(plot_df[plot_df$x >= 0, ], "right")
    #> debug: res_l <- find_nodes_outward(plot_df[plot_df$x < 0, ], "left")
    #> debug: if (is.null(res_r) || is.null(res_l)) {
    #>     node_label <- "NA"
    #>     dot_df <- data.frame(x = numeric(0), y = numeric(0))
    #> } else {
    #>     if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>         inner_l <- res_l[which.max(res_l$x), ]
    #>         inner_r <- res_r[which.min(res_r$x), ]
    #>         y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>         if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>             center_dot <- data.frame(x = 0, y = y_center)
    #>             dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>                 ], res_r[res_r$x > inner_r$x, ])
    #>         }
    #>         else {
    #>             dot_df <- rbind(res_l, res_r)
    #>         }
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #>     node_label <- as.character(nrow(dot_df))
    #> }
    #> debug: if (nrow(res_r) > 0 && nrow(res_l) > 0) {
    #>     inner_l <- res_l[which.max(res_l$x), ]
    #>     inner_r <- res_r[which.min(res_r$x), ]
    #>     y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #>     if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>         center_dot <- data.frame(x = 0, y = y_center)
    #>         dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, 
    #>             ], res_r[res_r$x > inner_r$x, ])
    #>     }
    #>     else {
    #>         dot_df <- rbind(res_l, res_r)
    #>     }
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: inner_l <- res_l[which.max(res_l$x), ]
    #> debug: inner_r <- res_r[which.min(res_r$x), ]
    #> debug: y_center <- plot_df$y[which.min(abs(plot_df$x))]
    #> debug: if (y_center <= inner_l$y && y_center <= inner_r$y) {
    #>     center_dot <- data.frame(x = 0, y = y_center)
    #>     dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], 
    #>         res_r[res_r$x > inner_r$x, ])
    #> } else {
    #>     dot_df <- rbind(res_l, res_r)
    #> }
    #> debug: center_dot <- data.frame(x = 0, y = y_center)
    #> debug: dot_df <- rbind(center_dot, res_l[res_l$x < inner_l$x, ], res_r[res_r$x > 
    #>     inner_r$x, ])
    #> debug: node_label <- as.character(nrow(dot_df))
    #> debug: dot_df <- unique(dot_df[complete.cases(dot_df), ])
    #> debug: p_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = x, y = y)) + 
    #>     ggplot2::geom_ribbon(ggplot2::aes(ymin = 0, ymax = y), fill = "black", 
    #>         alpha = 0.3) + ggplot2::geom_step(direction = "hv", color = "black", 
    #>     linewidth = 0.2) + ggplot2::geom_point(data = dot_df, color = "red", 
    #>     size = 1.2) + ggplot2::labs(title = paste0(jumps_subset[[j]]$n, 
    #>     " (", node_label, ") at P = ", sprintf("%.2f", current_p)), 
    #>     x = "q", y = "") + ggplot2::theme_minimal() + ggplot2::theme(plot.title = ggplot2::element_text(size = 10))
    #> debug: plot_list[[counter]] <- p_obj
    #> debug: counter <- counter + 1

![](man/figures/README-distributions-for-manuscript-1.png)<!-- -->

# Ellipse Parameterization (A = PQ)

This visualization shows two overlapping ellipses centered at (0,0)
where $A = PQ$.

![](man/figures/README-experimental_ellipses-1.png)<!-- -->
