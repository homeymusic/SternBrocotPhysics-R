Bell Test: Symplectic Contextual Erasure
================

## Statistical Summary

## Statistical Summary

| Metric                   | Value       |
|:-------------------------|:------------|
| **CHSH S-Value**         | **1.15121** |
| **Classical Limit**      | 2.0         |
| **Quantum Limit**        | 2.828       |
| **Algorithm Found Rate** | **99.98%**  |

------------------------------------------------------------------------

## Alice Fixed at 0°

Correlation $E(0, \theta_B)$ compared against the quantum
$-\cos(\theta)$ baseline (dashed) and the linear classical baseline
(solid).

![](bell_test_files/figure-gfm/plot-alice-0-1.png)<!-- -->

------------------------------------------------------------------------

## Alice Fixed at 90° (π/2)

Correlation plotted against the Phase Difference
$(\theta_B - \theta_A)$.

![](bell_test_files/figure-gfm/plot-alice-90-1.png)<!-- -->

### CHSH Breakdown

``` text
E(0,  pi/4):   0.3688
E(0, 3pi/4):  -0.0431
E(90, pi/4):   0.3698
E(90, 3pi/4):  0.3694
-----------------------
S-Value:       1.1512
```

------------------------------------------------------------------------

## Erasure Transfer Function

This plot visualizes the internal mathematical “warp” of the contextual
erasure. It shows how the continuous local hidden variable (microstate)
is shifted into its final macroscopic physical distance.

![](bell_test_files/figure-gfm/plot-transfer-function-1.png)<!-- -->

------------------------------------------------------------------------

## Erasure Distance vs. Uncertainty

This plot visualizes the relationship between the physical shift
required to snap to a rational macrostate (`erasure_distance`) and the
fundamental uncertainty of that resulting state. It reveals the
precision trade-offs inherent in the contextual erasure process.

![](bell_test_files/figure-gfm/plot-distance-vs-uncertainty-1.png)<!-- -->

------------------------------------------------------------------------

## Algorithmic Complexity of Measurement

This plot reveals the thermodynamic cost of the measurement context. As
the particle’s relative angle changes, the computational effort (program
length) required to map the microstate to a rational Stern-Brocot
macrostate fluctuates in a fractal pattern.

![](bell_test_files/figure-gfm/plot-complexity-1.png)<!-- -->

------------------------------------------------------------------------

## Erasure Success Rate

This plot verifies the percentage of microstates successfully resolved
to a rational macrostate before hitting the maximum search depth limit
(`max_depth = 2000`). For the simulation to be valid, this must remain
at 100%.

![](bell_test_files/figure-gfm/plot-found-rate-1.png)<!-- -->

------------------------------------------------------------------------

## Quantization into Rational Macrostates

This histogram demonstrates how the contextual erasure acts as a fractal
attractor, quantizing the uniform continuous microstates into discrete
rational fractions on the Stern-Brocot tree.

![](bell_test_files/figure-gfm/plot-attractors-1.png)<!-- -->

## Macrostate vs. Initial Microstate

This plot maps the initial continuous hidden variable (microstate)
directly to the resolved Stern-Brocot fraction (macrostate). In a purely
classical model, this forms a rigid “Devil’s Staircase” along a linear
diagonal.

![](bell_test_files/figure-gfm/plot-macro-vs-micro-1.png)<!-- -->
