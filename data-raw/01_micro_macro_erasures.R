# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_erasures.R")

# Load required libraries
devtools::install(quick = TRUE, upgrade = "never")
library(SternBrocotPhysics)
library(data.table)
library(future.apply)

# Setup Parallel Plan
# Background jobs are already isolated; detectCores() - 1 is safe.
future::plan(future::multisession, workers = parallel::detectCores() - 1)

# Setup Directory
raw_directory <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}

# Define experimental parameters
microstates_count <- 1e6 + 1
microstates <- seq(from = -1, to = 1, length.out = microstates_count)

run_and_save_erasure_experiment <- function(momentum_factor) {
  # 1. Physical Parameter
  uncertainty <- 1 / momentum_factor

  # 2. Run C++ function (returns a full DataFrame)
  # This now contains x, numerator, denominator, path, etc.
  results <- SternBrocotPhysics::erase_by_uncertainty(microstates, uncertainty)

  # 3. Inject Physics Metadata
  # This adds 'momentum' as the FIRST column for better readability
  experiment_raw_data <- cbind(momentum = momentum_factor, results)

  # 4. Write to compressed CSV
  file_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(momentum_factor, 6))

  data.table::fwrite(
    experiment_raw_data,
    file = file.path(raw_directory, file_name),
    compress = "gzip"
  )
}

# Define Momentum Range
momenta_factor_step <- 0.01
momenta_factor_max <- 25
momenta_factors <- seq(from = momenta_factor_step, to = momenta_factor_max, by = momenta_factor_step)

# Execute Parallel Loop
# future.seed = TRUE is mandatory for physics/randomness consistency
future.apply::future_lapply(
  momenta_factors,
  run_and_save_erasure_experiment,
  future.seed = TRUE
)

# Shutdown workers clean
future::plan(future::sequential)

message("Background Job Complete. Files saved to: ", raw_directory)


################################################################################
# 01_micro_macro_erasures.R
#
# Core computation: Landauer erasure of microstates to macrostates.
# For each dimensionless momentum 𝒫, samples microstate positions 𝒳_? and
# computes the erasure map ℰ(𝒳_?) → 𝒳, generating degeneracy structure.
################################################################################

# ==============================================================================
# PARAMETERS AND SETUP
# ==============================================================================

# ------------------------------------------------------------------------------
# Phase space parameters
#
# 𝒫: Dimensionless momentum scale, where p = p_0 × 𝒫
#    Range: 1 to 50, step d𝒫 = 0.1
#    Samples different energy/momentum scales across phase space
#
# 𝒳_?: Dimensionless microstate position, where x_? = x_0 × 𝒳_?
#      Range: -1 to +1, step d𝒳_? = 1e-6
#      Fine-grained sampling of microstates within Heisenberg cell
#
# Total erasures per 𝒫 value: 2×10⁶
# Total momentum values: 491 (from 1 to 50 by 0.1)
# Grand total erasures: ~982×10⁶
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Physical constants and scales
#
# x_0: Position scale (fundamental length scale)
# p_0: Momentum scale (fundamental momentum scale)
# ℏ: Reduced Planck constant (quantum of action)
# Heisenberg cell volume: Δx × Δp ≈ ℏ
# ------------------------------------------------------------------------------

# ==============================================================================
# ERASURE COMPUTATION
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: compute_erasure(𝒫, 𝒳_?)
#
# Implements the Landauer erasure map ℰ: 𝒳_? → 𝒳
#
# Input:
#   𝒫    - Dimensionless momentum value
#   𝒳_?  - Dimensionless microstate position
#
# Output:
#   𝒳    - Dimensionless macrostate position (erased/coarse-grained)
#   Δ𝒳   - Erasure displacement: 𝒳_? - 𝒳
#   S_Shannon    - Shannon entropy (observer uncertainty)
#   K_entropy    - Kolmogorov entropy (algorithmic/computational cost)
#
# Physical interpretation:
#   Takes unknown microstate 𝒳_? and maps it to known macrostate 𝒳
#   through thermodynamically irreversible coarse-graining.
#   Dissipates Landauer energy: E = k_B T ln(2) per bit erased.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: compute_shannon_entropy(𝒳_?, 𝒳)
#
# Calculates Shannon entropy: S = -Σ p_i ln(p_i)
#
# Measures observer's uncertainty/knowledge about state:
#   - High S before erasure (many possible microstates, uniform distribution)
#   - Low S after erasure (definite macrostate known)
#
# Change ΔS represents information gain through measurement/erasure.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: compute_kolmogorov_entropy(erasure_operation)
#
# Estimates Kolmogorov (algorithmic) complexity: K(x)
#
# Measures computational resources required for erasure:
#   - Low K before erasure (haven't computed anything yet)
#   - High K after erasure (paid computational cost)
#
# Represents the minimal program length to generate macrostate from microstate.
# Proxy: can use description length, compression ratio, or operation count.
# ------------------------------------------------------------------------------

# ==============================================================================
# MAIN COMPUTATION LOOP
# ==============================================================================

# ------------------------------------------------------------------------------
# Outer loop: Iterate over momentum values
# for 𝒫 in seq(1, 50, by = 0.1)
#
# Each momentum value represents a different "slice" through phase space.
# Higher 𝒫 corresponds to higher energy states (e.g., QHO energy levels).
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Inner loop: Iterate over microstate positions
# for 𝒳_? in seq(-1, 1, by = 1e-6)
#
# Densely samples microstates within the Heisenberg cell.
# Fine resolution (1e-6) ensures we capture degeneracy structure.
# Total of 2×10⁶ microstates sampled per momentum value.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Per-erasure computation
#
# For each (𝒫, 𝒳_?) pair:
#   1. Apply erasure map: ℰ(𝒳_?) → 𝒳
#   2. Compute displacement: Δ𝒳 = 𝒳_? - 𝒳
#   3. Calculate S_Shannon before and after
#   4. Calculate K_entropy for the operation
#   5. Store results: (𝒫, 𝒳_?, 𝒳, Δ𝒳, S_Shannon, K_entropy)
#
# Creates complete record of microstate-macrostate correspondence.
# ------------------------------------------------------------------------------

# ==============================================================================
# DATA STRUCTURE
# ==============================================================================

# ------------------------------------------------------------------------------
# Output data frame: erasure_results
#
# Columns:
#   P          - Dimensionless momentum 𝒫
#   X_micro    - Dimensionless microstate position 𝒳_?
#   X_macro    - Dimensionless macrostate position 𝒳
#   Delta_X    - Erasure displacement 𝒳_? - 𝒳
#   S_Shannon  - Shannon entropy (information uncertainty)
#   K_entropy  - Kolmogorov entropy (computational cost)
#
# Each row represents one erasure operation.
# Total rows: ~982×10⁶ (491 momentum values × 2×10⁶ microstates each)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Data export
#
# Save to: data/erasure_results.rds (or .csv if smaller dataset)
#
# This forms the foundation for all downstream analyses:
#   - 02_micro_macro_distributions.R reads this to compute Ω(𝒳)
#   - 03_micro_macro_correspondences.R reads this to plot 𝒳_? vs 𝒳
#   - 04_micro_macro_entropies.R reads this to analyze entropy structure
# ------------------------------------------------------------------------------

# ==============================================================================
# COMPUTATIONAL CONSIDERATIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# Parallelization strategy
#
# Outer loop (over 𝒫) is embarrassingly parallel.
# Can use parallel::mclapply() or future::future_map() to distribute
# across cores. Each 𝒫 value is independent.
#
# Memory: ~982M rows × 6 columns × 8 bytes ≈ 47 GB if held in memory.
# Consider chunking by 𝒫 and writing incrementally to disk.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Progress tracking
#
# Use progress::progress_bar() to monitor computation.
# Each 𝒫 value takes ~seconds to minutes depending on erasure complexity.
# Total runtime estimate: hours to days depending on hardware and parallelization.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Validation checks
#
# During computation, verify:
#   1. Erasure is deterministic: same 𝒳_? always gives same 𝒳
#   2. Shannon entropy decreases: S_after < S_before
#   3. Kolmogorov entropy increases: K_after > K_before
#   4. Total information conserved: ΔS + ΔK ≈ 0 (within numerical precision)
#   5. Landauer bound satisfied: K × k_B T ≥ ΔS
#
# Flag any violations for investigation.
# ------------------------------------------------------------------------------

################################################################################
# PHYSICAL INTERPRETATION
#
# This script implements the fundamental thesis:
#   Quantum discretization emerges from information-theoretic coarse-graining
#
# The erasure map ℰ represents:
#   - Thermodynamically: irreversible information erasure (Landauer)
#   - Statistically: coarse-graining from micro to macro (Boltzmann)
#   - Geometrically: foliation of phase space into Heisenberg cells
#   - Quantum mechanically: "collapse" as deterministic discretization
#
# Output reveals:
#   - Degeneracy structure Ω(𝒳) → quantized energy levels
#   - Entropy trade-offs → thermodynamic arrow of time
#   - Phase space partition → emergence of quantum observables
################################################################################
