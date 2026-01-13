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

run_and_save_erasure_experiment <- function(normalized_action) {
  uncertainty <- (pi / 4)  * (1 / sqrt(normalized_action))

  # Run updated C++ function with Fisher, Denom, and De Gosson metrics
  results <- SternBrocotPhysics::erase_by_uncertainty(microstates, uncertainty)

  experiment_raw_data <- cbind(normalized_action = normalized_action, results)

  file_name <- sprintf("micro_macro_erasures_A_%013.6f.csv.gz", round(normalized_action, 6))

  data.table::fwrite(
    experiment_raw_data,
    file = file.path(raw_directory, file_name),
    compress = "gzip"
  )
  gc()
}

# 5. Define Momentum Range (Extended to 100)
normalized_action_step <- 0.01
normalized_action_min  <- 100 + normalized_action_step
normalized_action_max  <- 150
normalized_actions <- seq(from = normalized_action_min, to = normalized_action_max, by = normalized_action_step)

future.apply::future_lapply(
  normalized_actions,
  run_and_save_erasure_experiment,
  future.seed = TRUE,
  future.packages = c("SternBrocotPhysics", "data.table") # Load packages efficiently
)

# 7. Shutdown workers clean
future::plan(future::sequential)

message("Background Job Complete. Files saved to: ", raw_directory)
