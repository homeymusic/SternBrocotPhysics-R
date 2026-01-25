# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_erasures.R")

# 1. Load/Install environment
devtools::install(quick = TRUE, upgrade = "never")
library(future.apply)

# 2. Setup Parallel Plan
future::plan(future::multisession, workers = parallel::detectCores() / 2)

# 3. Setup Directory (Using the Symlink via 'here')
raw_directory <- here::here("data-raw", "outputs", "01_micro_macro_erasures")

if (!dir.exists(raw_directory)) {
  dir.create(raw_directory, recursive = TRUE)
}

# 4. Define experimental parameters
microstates_count <- 1e6 + 1
microstates <- seq(from = -1, to = 1, length.out = microstates_count)

run_and_save_erasure_experiment <- function(normalized_momentum) {
  # Generate file name first to check for existence
  p_rounded <- round(normalized_momentum, 6)
  file_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", p_rounded)
  file_path <- file.path(raw_directory, file_name)

  # SKIP logic: If the file already exists, do not re-run
  # if (file.exists(file_path)) {
  #   return(NULL)
  # }

  uncertainty <- 1 / normalized_momentum

  # Run updated C++ function
  results <- SternBrocotPhysics::erase_by_uncertainty(microstates, uncertainty)

  experiment_raw_data <- cbind(momentum = normalized_momentum, results)

  data.table::setDTthreads(1)

  data.table::fwrite(
    experiment_raw_data,
    file = file_path,
    compress = "gzip"
  )
  gc()
}

normalized_momentum_step <- 0.1
normalized_momentum_min  <- 0.0 + normalized_momentum_step
normalized_momentum_max  <- 301
normalized_momenta       <- seq(from = normalized_momentum_min,
                                to = normalized_momentum_max,
                                by = normalized_momentum_step)


# 6. Execute Experiment
future.apply::future_lapply(
  normalized_momenta,
  run_and_save_erasure_experiment,
  future.seed = TRUE,
  future.packages = c("SternBrocotPhysics", "data.table")
)

# 7. Shutdown workers clean
future::plan(future::sequential)

message("Background Job Complete. Files saved to: ", raw_directory)
