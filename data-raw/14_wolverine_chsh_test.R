here::i_am("data-raw/14_wolverine_chsh_test.R")
library(data.table)

# --- CONFIGURATION ---
smoke_dir <- "/Volumes/SanDisk4TB/SternBrocot/06_smoke_test_chsh"

# --- 1. DEFINE WOLVERINE CHECKPOINTS ---
# We use the peaks identified in script 13
wolverine_angles <- c(0.0, 35.0, 45.0, 55.0) + 1e-5

# --- 2. LOAD WITH SINGLET PARITY ---
load_wolverine <- function(angle, observer) {
  fname <- sprintf("micro_macro_erasures_%s_%013.6f.csv.gz", tolower(observer), angle)
  dt <- fread(file.path(smoke_dir, fname), select = c("spin", "found"))

  # Apply Singlet Flip to Bob
  if (observer == "Bob") dt[, spin := spin * -1]
  return(dt)
}

cat("--- ANALYZING CHSH AT RATIONAL RESONANCE PEAKS (35/55) ---\n")
dt_a0   <- load_wolverine(wolverine_angles[1], "Alice")
dt_a45  <- load_wolverine(wolverine_angles[3], "Alice")
dt_b35  <- load_wolverine(wolverine_angles[2], "Bob")
dt_b55  <- load_wolverine(wolverine_angles[4], "Bob")

# --- 3. CORRELATION CALCULATIONS ---
analyze_pair <- function(name, dt1, dt2) {
  valid <- dt1$found & dt2$found
  corr <- mean(as.numeric(dt1$spin[valid]) * as.numeric(dt2$spin[valid]))
  data.table(Pair = name, Correlation = corr)
}

results <- rbind(
  analyze_pair("Alice(0)  vs Bob(35)", dt_a0,  dt_b35),
  analyze_pair("Alice(0)  vs Bob(55)", dt_a0,  dt_b55),
  analyze_pair("Alice(45) vs Bob(35)", dt_a45, dt_b35),
  analyze_pair("Alice(45) vs Bob(55)", dt_a45, dt_b55)
)

# --- 4. S-STATISTIC ---
E1 <- results$Correlation[1]
E2 <- results$Correlation[2]
E3 <- results$Correlation[3]
E4 <- results$Correlation[4]

S_stat <- abs(E1 - E2) + abs(E3 + E4)

print(results)
cat(sprintf("\n--- WOLVERINE CHSH RESULT: S = %.4f ---\n", S_stat))
