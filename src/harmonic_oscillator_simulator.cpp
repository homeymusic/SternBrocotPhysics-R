#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include <sys/stat.h>
#include <algorithm>
#include <atomic> // Added for thread-safe counting
#include "erase.h"

using namespace Rcpp;

static std::string fmt_val(double val, const char* format = "%.6f") {
  if (std::isnan(val) || R_IsNA(val)) return "NA";
  char buf[64];
  std::snprintf(buf, sizeof(buf), format, val);
  return std::string(buf);
}

inline bool check_file_exists(const std::string& name) {
  struct stat buffer;
  return (stat(name.c_str(), &buffer) == 0);
}

// --- Define a Function Pointer Type for our Erasure Algorithms ---
typedef EraseResult (*EraseAlgorithmFunc)(double, double, int);

// --- 2. EXPORTED API ---

//' Run Erasure Simulation
//'
//' @param momenta Vector of momentum values (P) to simulate.
//' @param dir Output directory.
//' @param algorithm String to choose the engine: "stern_brocot" or "kdtree"
//' @param n_threads Number of threads (0 = auto).
//' @export
// [[Rcpp::export]]
void harmonic_oscillator_erasures(NumericVector momenta, std::string dir, std::string algorithm = "stern_brocot", int n_threads = 0) {

  // 1. Dispatcher: Select the correct algorithm based on the R string
  EraseAlgorithmFunc current_algorithm = nullptr;

  if (algorithm == "stern_brocot") {
    current_algorithm = &stern_brocot_erase_single_native;
  } else if (algorithm == "kdtree") {
    current_algorithm = &kdtree_erase_single_native;
  } else {
    stop("Unknown algorithm specified. Use 'stern_brocot' or 'kdtree'.");
  }

  std::vector<double> p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = p_vec.size();

  // Track progress
  std::atomic<int> skip_count(0);
  std::atomic<int> compute_count(0);

  int max_program_length = 2000;
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double p = p_vec[i];

    int current_count = 100001;

    char filename[256];
    // Include the algorithm name in the file so you don't overwrite different experiments!
    std::snprintf(filename, sizeof(filename), "harmonic_oscillator_erasures_%s_P_%013.6f.csv.gz", algorithm.c_str(), p);
    std::string path = dir + "/" + std::string(filename);

    if (check_file_exists(path)) {
      skip_count++;
      return;
    }

    compute_count++;
    double max_erasure_radius = 1.0 / (2.0 * M_PI * p);
    gzFile file = gzopen(path.c_str(), "wb1");
    if (!file) return;

    // Updated CSV header (removed path, changed left/right to zero/one)
    gzprintf(file, "momentum,erasure_distance,microstate,minimal_action_state,max_erasure_radius,numerator,denominator,minimal_program,minimal_program_length,shannon_entropy,zero_count,one_count,max_program_length,found\n");

    for (int j = 0; j < current_count; j++) {
      double mu_source = (current_count > 1) ? -1.0 + (2.0 * j) / (double)(current_count - 1) : 0.0;

      // 2. Execute whichever algorithm pointer was selected above
      EraseResult res = current_algorithm(mu_source, max_erasure_radius, max_program_length);

      // Updated gzprintf format string (14 columns instead of 15)
      gzprintf(file, "%.6f,%s,%.6f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d\n",
               p,
               fmt_val(res.erasure_distance).c_str(),
               mu_source,
               fmt_val(res.minimal_action_state).c_str(),
               fmt_val(res.max_erasure_radius).c_str(),
               fmt_val(res.numerator, "%.0f").c_str(),
               fmt_val(res.denominator, "%.0f").c_str(),
               res.minimal_program.c_str(),
               fmt_val(res.minimal_program_length).c_str(),
               fmt_val(res.shannon_entropy).c_str(),
               fmt_val(res.zero_count).c_str(),
               fmt_val(res.one_count).c_str(),
               max_program_length,
               (int)res.found);
    }
    gzclose(file);
  });

  pool.wait();
}
