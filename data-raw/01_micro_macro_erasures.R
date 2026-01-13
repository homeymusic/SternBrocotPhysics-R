# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_erasures.R")

# 1. Load/Install environment
devtools::install(quick = TRUE, upgrade = "never")
# devtools::install(args = "--preclean", upgrade = "never")
library(future.apply)

# 2. Setup Parallel Plan
future::plan(future::multisession, workers = parallel::detectCores() / 2)

# 3. Setup Directory
raw_directory <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}

# 4. Define experimental parameters
microstates_count <- 1e6 + 1
microstates <- seq(from = -1, to = 1, length.out = microstates_count)

run_and_save_erasure_experiment <- function(momentum_factor) {
  uncertainty <- (pi / 4)  * (1 / momentum_factor)

  # Run updated C++ function with Fisher, Denom, and De Gosson metrics
  results <- SternBrocotPhysics::erase_by_uncertainty(microstates, uncertainty)

  experiment_raw_data <- cbind(momentum = momentum_factor, results)

  file_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(momentum_factor, 6))

  data.table::fwrite(
    experiment_raw_data,
    file = file.path(raw_directory, file_name),
    compress = "gzip"
  )
  gc()
}

# 5. Define Momentum Range (Extended to 100)
momenta_factor_step <- 0.01
momenta_factor_min  <- 10 + momenta_factor_step
momenta_factor_max  <- 50
momenta_factors <- seq(from = momenta_factor_min, to = momenta_factor_max, by = momenta_factor_step)

future.apply::future_lapply(
  momenta_factors,
  run_and_save_erasure_experiment,
  future.seed = TRUE,
  future.packages = c("SternBrocotPhysics", "data.table") # Load packages efficiently
)

# 7. Shutdown workers clean
future::plan(future::sequential)

message("Background Job Complete. Files saved to: ", raw_directory)
