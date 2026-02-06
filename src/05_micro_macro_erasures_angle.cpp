#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// Helper to write a specific simulation file
// Now strictly implementing the Normalized Bell's Theorem logic:
// Spin = sgn(epsilon), where epsilon = microstate - macrostate
void write_simulation_file(std::string filepath, double theta_deg, double uncertainty, int count, int max_depth_limit, double tolerance) {
  gzFile file = gzopen(filepath.c_str(), "wb1");
  if (!file) return;

  // Header includes 'erasure_distance' (epsilon) and 'spin' (sgn epsilon)
  gzprintf(file, "theta,erasure_distance,spin,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n");

  for (int j = 0; j < count; j++) {
    // Shared microstate sweep from -1 to 1
    double mu = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

    // Perform Erasure using the calculated Symplectic Capacity (delta)
    // EraseResult must contain 'erasure_distance' (the difference between mu and the found rational)
    EraseResult res = erase_single_native(mu, uncertainty, max_depth_limit);

    // --- THE HARDWARE LIMIT ---
    // spin = sgn(epsilon)
    // epsilon > 0 -> +1
    // epsilon < 0 -> -1
    // epsilon ~ 0 ->  0 (erased/undefined)
    int spin = (res.erasure_distance > tolerance) ? 1 : (res.erasure_distance < -tolerance ? -1 : 0);

    gzprintf(file, "%.6f,%.6f,%d,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
             theta_deg,
             res.erasure_distance,          // epsilon
             spin,                          // sgn(epsilon)
             res.microstate,                // theta_?
             res.macrostate,                // Theta*
             res.uncertainty,               // delta
             res.numerator,
             res.denominator,
             res.stern_brocot_path.c_str(),
             res.minimal_program.c_str(),
             res.program_length,
             res.shannon_entropy,
             res.left_count,
             res.right_count,
             max_depth_limit,
             (int)res.found);
  }
  gzclose(file);
}

//' @export
// [[Rcpp::export]]
void micro_macro_erasures_angle(NumericVector angles, std::string dir, int count, int n_threads = 0) {
  int max_depth_limit = 20000;
  const double tolerance = 1e-10;

  std::vector<double> angles_cpp = Rcpp::as<std::vector<double>>(angles);
  size_t n_angles = angles_cpp.size();

  // Thread Logic
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n_angles, [&](int i) {
    double theta_deg = angles_cpp[i];
    double theta_rad = theta_deg * (M_PI / 180.0);

    // --- NORMALIZED BELL THEOREM CAPACITIES ---
    double abs_sin = std::abs(std::sin(theta_rad));
    double abs_cos = std::abs(std::cos(theta_rad));

    // Geometric divergence protection:
    // If sin(alpha) -> 0, Capacity -> Infinity (Total Erasure)
    double delta_alpha = (abs_sin < 1e-12) ? 1e9 : (4.0 * std::pow(std::cos(theta_rad), 2)) / (M_PI * abs_sin);
    double delta_beta  = (abs_cos < 1e-12) ? 1e9 : (4.0 * std::pow(std::sin(theta_rad), 2)) / (M_PI * abs_cos);

    // --- WRITE ALPHA FILE ---
    char filename_alpha[128];
    std::snprintf(filename_alpha, sizeof(filename_alpha), "micro_macro_erasures_alpha_%013.6f.csv.gz", theta_deg);
    std::string path_alpha = dir + "/" + std::string(filename_alpha);
    write_simulation_file(path_alpha, theta_deg, delta_alpha, count, max_depth_limit, tolerance);

    // --- WRITE BETA FILE ---
    char filename_beta[128];
    std::snprintf(filename_beta, sizeof(filename_beta), "micro_macro_erasures_beta_%013.6f.csv.gz", theta_deg);
    std::string path_beta = dir + "/" + std::string(filename_beta);
    write_simulation_file(path_beta, theta_deg, delta_beta, count, max_depth_limit, tolerance);
  });

  pool.wait();
}
