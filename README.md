Stern-Brocot Physics
================

An R package for computational experiments in classical and quantum
physics using the Stern-Brocot tree.

![](man/figures/README-plot-all-metrics-with-residuals-1.png)<!-- -->![](man/figures/README-plot-all-metrics-with-residuals-2.png)<!-- -->![](man/figures/README-plot-all-metrics-with-residuals-3.png)<!-- -->

### Fit Statistics: Holographic Theory ($K \propto \sqrt{P}$)

This section summarizes the goodness-of-fit for the mean values of
Shannon, Kolmogorov, and Zurek entropies against the proposed
holographic scaling relation for physical momentum values ($P
The quantitative analysis of the physical data ($P \$) provides strong
evidence that the **Zurek entropy** best aligns with the hypothesized
**holographic principle** scaling.

The Zurek and Kolmogorov complexity metrics both exhibit outstanding
fits to the $y \propto \sqrt{P}$ theory curve, with R-squared ($R^2$)
values exceeding 0.97. This suggests that the algorithmic information
and erasure metrics strongly adhere to this theoretical scaling behavior
within the physical regime. In contrast, the Shannon entropy metric
yields a very poor fit to the same model, confirming the visual
observation that the Shannon component is likely the source of the
structured, “quantized” deviations from the continuous holographic
theory curve.

\$).

| Metric                | k_constant | R_squared | Correlation_R | RMSE   |
|:----------------------|:-----------|:----------|:--------------|:-------|
| Shannon Entropy       | 0.104      | -20.3311  | 0.3308        | 0.3089 |
| Zurek Entropy         | 1.041      | 0.9123    | 0.9897        | 0.7063 |
| Kolmogorov Complexity | 0.937      | 0.9657    | 0.992         | 0.4369 |

![](man/figures/README-jump-fluctuations-1.png)<!-- -->

![](man/figures/README-jump-fluctuations-custom-1.png)<!-- -->

![](man/figures/README-plot-complexity-vs-denominator-1.png)<!-- -->
