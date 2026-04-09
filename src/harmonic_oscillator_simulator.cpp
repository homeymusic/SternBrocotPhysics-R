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

// --- EXPORTED API ---

//' Run Erasure Simulation
//'
//' @param momenta Vector of momentum values (P) to simulate.
//' @param dir Output directory.
//' @param algorithm String to choose the engine: "stern_brocot", "kdtree", "action_angle", "golden_ratio"
//' @param n_threads Number of threads (0 = auto).
//' @export
// [[Rcpp::export]]
void harmonic_oscillator_erasures(NumericVector momenta, std::string dir, std::string algorithm = "stern_brocot", int n_threads = 0) {

  EraseAlgorithmFunc current_algorithm = nullptr;

  if (algorithm == "stern_brocot") {
    current_algorithm = &stern_brocot_erase_single_native;
  } else if (algorithm == "kdtree") {
    current_algorithm = &kdtree_erase_single_native;
  } else if (algorithm == "action_angle") {
    current_algorithm = &action_angle_erase_single_native;
  } else if (algorithm == "golden_ratio") {
    current_algorithm = &golden_ratio_erase_single_native;
  } else {
    stop("Unknown algorithm specified. Use 'stern_brocot', 'kdtree', 'action_angle', or 'golden_ratio'.");
  }

  std::vector<double> delta_p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = delta_p_vec.size();

  // Track progress
  std::atomic<int> skip_count(0);
  std::atomic<int> compute_count(0);

  int max_sequence_length = 2000;
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double delta_p = delta_p_vec[i];

    int current_count = 100001;

    char filename[256];
    // Include the algorithm name in the file so you don't overwrite different experiments!
    std::snprintf(filename, sizeof(filename), "harmonic_oscillator_erasures_%s_P_%013.6f.csv.gz", algorithm.c_str(), delta_p);
    std::string path = dir + "/" + std::string(filename);

    if (check_file_exists(path)) {
      skip_count++;
      return;
    }

    compute_count++;

    // --- 1. THE PHYSICS ---
    // The physical squeezed boundary of the quantum state.
    // Pure dimensional squeezing (1.0 / delta_p) scaled by the
    // 2D-to-1D average linear projection of a harmonic orbit (2.0 / M_PI).
    double squeezed_boundary = (2.0 / M_PI) * (1.0 / delta_p);

    // --- 2. THE ALGORITHMIC MAPPING ---
    // Because the Stern-Brocot tree strictly evaluates the normalized
    // fractal unit interval [-1.0, 1.0], the physical boundary must be
    // divided by the macroscopic boundary (delta_p) to get the relative fraction.
    double algorithmic_tolerance = squeezed_boundary / delta_p;

    gzFile file = gzopen(path.c_str(), "wb1");
    if (!file) return;

    // Updated CSV header to match manuscript nomenclature
    gzprintf(file, "momentum,erasure_displacement,blob_center,selected_microstate,squeezed_boundary,numerator,denominator,encoded_sequence,sequence_length,shannon_entropy,zero_count,one_count,max_sequence_length,found\n");

    for (int j = 0; j < current_count; j++) {
      // STRICTLY locked to the fundamental fractal unit interval [-1.0, 1.0]
      double blob_center = (current_count > 1) ? -1.0 + (2.0 * j) / (double)(current_count - 1) : 0.0;

      // Execute the algorithmic engine using the mapped RELATIVE tolerance
      EraseResult res = current_algorithm(blob_center, algorithmic_tolerance, max_sequence_length);

      // Write results to gzip stream
      gzprintf(file, "%.6f,%s,%.6f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d\n",
               delta_p,
               fmt_val(res.erasure_displacement).c_str(),
               blob_center,
               fmt_val(res.selected_microstate).c_str(),
               fmt_val(res.squeezed_boundary).c_str(), // Safely captures the algorithmic_tolerance actually used
               fmt_val(res.numerator, "%.0f").c_str(),
               fmt_val(res.denominator, "%.0f").c_str(),
               res.encoded_sequence.c_str(),
               fmt_val(res.sequence_length).c_str(),
               fmt_val(res.shannon_entropy).c_str(),
               fmt_val(res.zero_count).c_str(),
               fmt_val(res.one_count).c_str(),
               max_sequence_length,
               (int)res.found);
    }
    gzclose(file);
  });

  pool.wait();
}
