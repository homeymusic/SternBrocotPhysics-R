# 01_micro_macro_erasures.R
here::i_am("data-raw/01_micro_macro_erasures.R")

# 1. Load/Install environment
devtools::install(quick = TRUE, upgrade = "never")
library(future.apply)

# 2. Setup Parallel Plan
future::plan(future::multisession, workers = parallel::detectCores() / 2)

# 3. Setup Directory
raw_directory <- here::here("data-raw", "outputs", "01_micro_macro_erasures")
if (!dir.exists(raw_directory)) dir.create(raw_directory, recursive = TRUE)

# 4. Define High-Resolution Momentum Range
normalized_momentum_step <- 0.001
normalized_momentum_min  <- 0.0 + normalized_momentum_step
normalized_momentum_max  <- 30
normalized_momenta       <- seq(from = normalized_momentum_min,
                                to = normalized_momentum_max,
                                by = normalized_momentum_step)

# --- PRE-RUN AUDIT ---
expected_files <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", round(normalized_momenta, 6))
existing_mask  <- file.exists(file.path(raw_directory, expected_files))

n_total    <- length(normalized_momenta)
n_existing <- sum(existing_mask)
n_new      <- n_total - n_existing

message("==================================================")
message("EXPERIMENT AUDIT")
message("Target Range:   P = ", normalized_momentum_min, " to ", normalized_momentum_max)
message("Step Size:      ", normalized_momentum_step)
message("Total Points:   ", format(n_total, big.mark=","))
message("Existing Files: ", format(n_existing, big.mark=","), " (will be skipped)")
message("New Files:      ", format(n_new, big.mark=","), " (to be processed)")
message("==================================================")

if (n_new == 0) stop("All files already exist. Nothing to do.")

# 5. Experimental Parameters
microstates_count <- 1e6 + 1
microstates <- seq(from = -1, to = 1, length.out = microstates_count)

run_and_save_erasure_experiment <- function(normalized_momentum) {
  p_rounded <- round(normalized_momentum, 6)
  file_name <- sprintf("micro_macro_erasures_P_%013.6f.csv.gz", p_rounded)
  file_path <- file.path(raw_directory, file_name)

  if (file.exists(file_path)) return(NULL)

  uncertainty <- 1 / normalized_momentum
  results <- SternBrocotPhysics::erase_by_uncertainty(microstates, uncertainty)
  experiment_raw_data <- cbind(momentum = normalized_momentum, results)

  data.table::fwrite(experiment_raw_data, file = file_path, compress = "gzip")
  gc()
}

# 6. Execute Experiment
future.apply::future_lapply(
  normalized_momenta,
  run_and_save_erasure_experiment,
  future.seed = TRUE,
  future.packages = c("SternBrocotPhysics", "data.table")
)

# 7. Shutdown
future::plan(future::sequential)
message("Background Job Complete. Target files generated in: ", raw_directory)
