Stern-Brocot Physics
================

An R package for computational experiments in classical and quantum
physics using the Stern-Brocot tree.
![](man/figures/README-jump-fluctuations-1.png)<!-- -->

![](man/figures/README-plot-all-measures-1.png)<!-- -->![](man/figures/README-plot-all-measures-2.png)<!-- -->![](man/figures/README-plot-all-measures-3.png)<!-- -->![](man/figures/README-plot-all-measures-4.png)<!-- -->![](man/figures/README-plot-all-measures-5.png)<!-- -->![](man/figures/README-plot-all-measures-6.png)<!-- -->

![](man/figures/README-plot-complexity-vs-denominator-1.png)<!-- -->

![](man/figures/README-plot-all-metrics-with-residuals-1.png)<!-- -->![](man/figures/README-plot-all-metrics-with-residuals-2.png)<!-- -->![](man/figures/README-plot-all-metrics-with-residuals-3.png)<!-- -->
\### Fit Statistics: Holographic Theory ($y \propto \sqrt{P}$)

This section summarizes the goodness-of-fit for the mean values of
Shannon, Kolmogorov, and Zurek entropies against the proposed
holographic scaling relation for physical momentum values ($P \ge 1.0$).

| Metric                | k_constant | R_squared | Correlation_R | RMSE   |
|:----------------------|:-----------|:----------|:--------------|:-------|
| Shannon Entropy       | 0.162      | -2.803    | 0.5658        | 0.2233 |
| Zurek Entropy         | 1.138      | 0.9827    | 0.9919        | 0.2318 |
| Kolmogorov Complexity | 0.977      | 0.982     | 0.9964        | 0.227  |

### Summary and Conclusion

The quantitative analysis of the physical data ($P \ge 1.0$) provides
strong evidence that the **Zurek entropy** best aligns with the
hypothesized **holographic principle** scaling.

The Zurek and Kolmogorov complexity metrics both exhibit outstanding
fits to the $y \propto \sqrt{P}$ theory curve, with R-squared ($R^2$)
values of **0.9827** and **0.9820**, respectively. This suggests that
the algorithmic information and erasure metrics strongly adhere to this
theoretical scaling behavior within the physical regime.

In contrast, the Shannon entropy metric yields a highly negative $R^2$
value of **-2.803**, indicating a poor fit to the same model. This
confirms the visual observation that the Shannon component is likely the
source of the structured, “quantized” deviations from the continuous
holographic theory curve.
