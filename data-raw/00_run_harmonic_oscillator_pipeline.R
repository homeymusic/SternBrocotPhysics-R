library(here)
library(tictoc)
library(SternBrocotPhysics) # Ensure the package is loaded globally

message("🚀 Starting Full Physics Pipeline: ", Sys.time())
tic("Full Pipeline Execution")

# Clear any existing future plans at the very start
if (!inherits(future::plan(), "sequential")) {
  future::plan(future::sequential)
}

tryCatch({
  # Step 1: C++ Simulation (uses internal RcppThread, no future plan needed)
  message("\n--- Step 1: 01_harmonic_oscillator_erasures.R ---")
  source(here("data-raw", "01_harmonic_oscillator_erasures.R"), local = TRUE)

  # Step 2: Density Generation
  message("\n--- Step 2: 02_harmonic_oscillator_erasure_distance_densities.R ---")
  source(here("data-raw", "02_harmonic_oscillator_erasure_distance_densities.R"), local = TRUE)
  future::plan(future::sequential) # Explicitly close workers after step

  # Step 3: Node Extraction
  message("\n--- Step 3: 03_harmonic_oscillator_erasure_distance_density_nodes.R ---")
  source(here("data-raw", "03_harmonic_oscillator_erasure_distance_density_nodes.R"), local = TRUE)
  future::plan(future::sequential) # Explicitly close workers after step

  # Step 4: Summary
  message("\n--- Step 4: 04_harmonic_oscillator_erasure_distance_summary.R ---")
  source(here("data-raw", "04_harmonic_oscillator_erasure_distance_summary.R"), local = TRUE)

  message("\n✅ Pipeline Finished Successfully.")
}, error = function(e) {
  message("\n❌ PIPELINE FAILED")
  message("Error Message: ", e$message)
})
toc()
