Stern-Brocot Physics
================

An R package for computational experiments in classical and quantum
physics using the Stern-Brocot tree.

``` r
file_path <- here::here("data-raw/outputs/01_micro_macro_erasures/micro_macro_erasures_P_000007.250000.csv.gz")
df <- fread(file_path)
```

``` r
# Subsample for rendering performance if needed, 
# but pch="." handles 2e6 points well on a Mac.
plot(
  x = df$microstate, 
  y = df$macrostate,
  main = expression(paste("Erasure Map: ", x["?"], " " %->% " ", X)),
  xlab = expression(paste("Microstate (", x["?"], ")")),
  ylab = expression(paste("Macrostate (", X, ")")),
  pch = ".", 
  col = rgb(0, 0, 0, 0.05), # Low alpha reveals density of the mapping
  cex = 0.5
)

# Reference line for zero fluctuation
abline(0, 1, col = "red", lty = 2, lwd = 1)

grid(col = "gray80")
```

![](man/figures/README-plot-staircase-1.png)<!-- -->

``` r
# Histogram of the macrostate distribution, representing Omega(X)
hist(
  df$macrostate,
  breaks = seq(-1.0, 1.0, length.out = 200), # High resolution breaks for smooth distribution
  main = expression(paste("Macrostate Degeneracy Distribution (", Omega, "(", X, "))")),
  xlab = expression(paste("Macrostate (", X, ")")),
  ylab = expression(paste("Count of Microstates (", Omega, ")")),
  col = rgb(0.2, 0.6, 0.8, 0.7), # A nice blue color with transparency
  border = "black"
)
grid(col = "gray80", lty = "dotted")
```

![](man/figures/README-plot-degeneracy-histogram-1.png)<!-- -->

``` r
# Histogram of the fluctuation distribution
hist(
  df$fluctuation,
  breaks = 200, # Use 200 bins automatically centered around zero
  main = expression(paste("Overall Fluctuation Distribution (", Omega, "(", delta[x], "))")),
  xlab = expression(paste("Fluctuation (", delta[x], ")")),
  ylab = expression(paste("Count of Microstates (", Omega, ")")),
  col = rgb(0.8, 0.4, 0.2, 0.7), # An orange color
  border = "black"
)

# Add line at zero fluctuation
abline(v = 0, col = "red", lty = 2, lwd = 1)

grid(col = "gray80", lty = "dotted")
```

![](man/figures/README-plot-fluctuation-histogram-1.png)<!-- -->

``` r
plot(
  x = df$microstate,
  y = df$kolmogorov_complexity,
  main = expression(paste("Kolmogorov Complexity (", K, ") vs Microstate (", x["?"], ")")),
  xlab = expression(paste("Microstate (", x["?"], ")")),
  ylab = expression(paste("Kolmogorov Complexity (", K, ")")),
  pch = ".",
  col = rgb(0.5, 0.1, 0.9, 0.1), # A purple color with transparency
  cex = 0.5
)
grid(col = "gray80")
```

![](man/figures/README-plot-kolmogorov-complexity-1.png)<!-- -->

``` r
plot(
  x = df$microstate,
  y = df$shannon_entropy,
  main = expression(paste("Shannon Entropy (", H, ") vs Microstate (", x["?"], ")")),
  xlab = expression(paste("Microstate (", x["?"], ")")),
  ylab = expression(paste("Shannon Entropy (", H, ") [bits]")),
  pch = ".",
  col = rgb(0.1, 0.6, 0.1, 0.1), # A green color with transparency
  cex = 0.5
)
grid(col = "gray80")
```

![](man/figures/README-plot-shannon-entropy-1.png)<!-- -->

``` r
# Calculate total entropy S = H + K (if not already done in a prior chunk)
if (!("total_entropy" %in% names(df))) {
  df$total_entropy <- df$shannon_entropy + df$kolmogorov_complexity
}

plot(
  x = df$kolmogorov_complexity,
  y = df$shannon_entropy,
  main = expression(paste("Shannon Entropy (", H, ") vs Kolmogorov Complexity (", K, ")")),
  xlab = expression(paste("Kolmogorov Complexity (", K, ") [bits]")),
  ylab = expression(paste("Shannon Entropy (", H, ") [bits]")),
  pch = 20, # Use solid, visible points instead of pixels
  col = rgb(0.1, 0.1, 0.1, 0.2), # Black with higher opacity
  cex = 1,
  xlim = range(df$kolmogorov_complexity), # Automatically set X axis limits
  ylim = range(df$shannon_entropy)        # Automatically set Y axis limits
)

abline(h = mean(df$total_entropy, na.rm = TRUE), col = "red", lty = 2, lwd = 2)

grid(col = "gray80")
```

![](man/figures/README-plot-h-vs-k-1.png)<!-- -->

``` r
# Calculate total entropy S = H + K
df$total_entropy <- df$shannon_entropy + df$kolmogorov_complexity

plot(
  x = df$microstate,
  y = df$total_entropy,
  main = expression(paste("Total Physical Entropy (", S, " = ", H, " + ", K, ") vs Microstate")),
  xlab = expression(paste("Microstate (", x["?"], ")")),
  ylab = expression(paste("Total Entropy (", S, ") [bits]")),
  pch = ".",
  col = rgb(0.9, 0.5, 0.1, 0.1), # Orange transparency
  cex = 0.5
)

# Plot average total entropy as a reference line
abline(h = mean(df$total_entropy), col = "red", lty = 2, lwd = 2)

grid(col = "gray80")
```

![](man/figures/README-plot-total-entropy-1.png)<!-- -->

``` r
plot(
  x = df$kolmogorov_complexity,
  y = df$fluctuation,
  main = expression(paste("Fluctuation (", delta[x], ") vs Kolmogorov Complexity (", K, ")")),
  xlab = expression(paste("Kolmogorov Complexity (", K, ") [bits]")),
  ylab = expression(paste("Fluctuation (", delta[x], ")")),
  pch = ".",
  col = rgb(0.1, 0.1, 0.6, 0.1), # Blue transparency
  cex = 0.5,
  xlim = range(df$kolmogorov_complexity, na.rm = TRUE),
  ylim = range(df$fluctuation, na.rm = TRUE)
)

abline(h = 0, col = "red", lty = 2, lwd = 2) # Zero fluctuation line
grid(col = "gray80")
```

![](man/figures/README-plot-fluctuation-vs-K-1.png)<!-- -->

``` r
plot(
  x = df$shannon_entropy,
  y = df$fluctuation,
  main = expression(paste("Fluctuation (", delta[x], ") vs Shannon Entropy (", H, ")")),
  xlab = expression(paste("Shannon Entropy (", H, ") [bits]")),
  ylab = expression(paste("Fluctuation (", delta[x], ")")),
  pch = ".",
  col = rgb(0.1, 0.5, 0.3, 0.1), # Green transparency
  cex = 0.5,
  xlim = range(df$shannon_entropy, na.rm = TRUE),
  ylim = range(df$fluctuation, na.rm = TRUE)
)

abline(h = 0, col = "red", lty = 2, lwd = 2) # Zero fluctuation line
grid(col = "gray80")
```

![](man/figures/README-plot-fluctuation-vs-shannon-1.png)<!-- -->

``` r
# Calculate the Left/Total ratio
df$lr_ratio <- df$l_count / df$kolmogorov_complexity

plot(
  x = df$microstate,
  y = df$lr_ratio,
  main = expression(paste("Path Bias (L/Total Ratio) vs Microstate (", x["?"], ")")),
  xlab = expression(paste("Microstate (", x["?"], ")")),
  ylab = "L Count Ratio",
  pch = ".",
  col = rgb(0.6, 0.1, 0.6, 0.1), # Purple transparency
  cex = 0.5,
  ylim = c(0, 1) # Ratio is always between 0 and 1
)

abline(h = 0.5, col = "red", lty = 2, lwd = 2) # Balanced path line
grid(col = "gray80")
```

![](man/figures/README-plot-lr-ratio-vs-microstate-1.png)<!-- -->
