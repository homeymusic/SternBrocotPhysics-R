library(here)
library(tictoc)

message("🚀 Starting Full Physics Pipeline: ", Sys.time())
tic("Full Pipeline Execution")

tryCatch({

  message("\n--- Step 1: 08_pib_erasures.R ---")
  source(here("data-raw", "08_pib_erasures.R"), local = TRUE)

  message("\n--- Step 2: 09_pib_erasure_distance_densities.R ---")
  source(here("data-raw", "09_pib_erasure_distance_densities.R"), local = TRUE)

  message("\n--- Step 3: 10_pib_erasure_distance_density_nodes.R ---")
  source(here("data-raw", "10_pib_erasure_distance_density_nodes.R"), local = TRUE)

  message("\n--- Step 4: 11_pib_erasure_distance_summary.R ---")
  source(here("data-raw", "11_pib_erasure_distance_summary.R"), local = TRUE)

  message("\n✅ Pipeline Finished Successfully.")

}, error = function(e) {
  message("\n❌ PIPELINE FAILED at ", Sys.time())
  message("Error Message: ", e$message)
})

toc()
