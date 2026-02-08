here::i_am("data-raw/17_global_combinatorial_heatmap.R")
library(data.table)
library(ggplot2)

# --- 1. FULL COMBINATORIAL ANALYSIS ---
cat("--- MAPPING THE GLOBAL EXPECTATION SURFACE ---\n")
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"
angles <- seq(0, 90, by = 2) + 1e-5 # 2-degree global grid

global_list <- list()
for (a in angles) {
  dt_a <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_alice_%013.6f.csv.gz", a)), select = c("spin", "found"))
  for (b in angles) {
    dt_b <- fread(file.path(smoke_dir, sprintf("micro_macro_erasures_bob_%013.6f.csv.gz", b)), select = c("spin", "found"))

    v <- dt_a$found & dt_b$found
    # Correlation with Singlet Flip
    corr <- mean(as.numeric(dt_a$spin[v]) * (as.numeric(dt_b$spin[v]) * -1))
    global_list[[paste(a, b)]] <- data.table(Alice = a, Bob = b, E = corr)
  }
}
global_map <- rbindlist(global_list)

# --- 2. RENDER THE SURFACE ---
surface = ggplot(global_map, aes(x = Alice, y = Bob, fill = E)) +
  geom_tile() +
  scale_fill_gradient2(low = "#c0392b", mid = "white", high = "#2980b9", midpoint = 0) +
  labs(title = "Global Expectation Surface E(Alice, Bob)",
       subtitle = "Red: Anti-correlated | Blue: Correlated | Diagonal: The 'Balanced Budget' Zone",
       x = "Alice Absolute Angle", y = "Bob Absolute Angle") +
  theme_minimal()

print(surface)
