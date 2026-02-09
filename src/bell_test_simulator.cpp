#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// Helper to handle NA values for strings/numbers in gzprintf
std::string clean_str(std::string s) { return s.empty() ? "" : s; }

//' @export
// [[Rcpp::export]]
void micro_macro_bell_erasure_sweep(NumericVector angles, std::string dir, int count, double kappa, double mu_start, double mu_end, int n_threads = 0) {
  int max_depth = 2000;
  std::vector<double> angles_cpp = Rcpp::as<std::vector<double>>(angles);
  size_t n = angles_cpp.size();

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);
  pool.parallelFor(0, n, [&](int i) {
    double angle_deg = angles_cpp[i];
    double angle_rad = angle_deg * (M_PI / 180.0);

    char f_a[128], f_b[128];
    std::snprintf(f_a, sizeof(f_a), "erasure_alice_%013.6f.csv.gz", angle_deg);
    std::snprintf(f_b, sizeof(f_b), "erasure_bob_%013.6f.csv.gz", angle_deg);

    gzFile file_a = gzopen((dir + "/" + f_a).c_str(), "wb1");
    gzFile file_b = gzopen((dir + "/" + f_b).c_str(), "wb1");

    // --- SCHEMA COMPLIANCE FIX ---
    const char* header = "angle,spin,found,microstate,uncertainty,erasure_distance,macrostate,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count\n";

    gzprintf(file_a, header);
    gzprintf(file_b, header);

    for (int j = 0; j < count; j++) {
      // DYNAMIC MU RANGE
      // Interpolate mu from start to end based on current step j
      double mu_source = mu_start + (mu_end - mu_start) * ((double)j / (double)(count - 1));

      double mu_a = mu_source;
      double mu_b = -mu_source; // Singlet State (Opposite microstates)

      double phase_a = angle_rad - mu_a;
      double phase_b = angle_rad - mu_b;

      // 1. CALCULATE UNCERTAINTY (MAGNITUDE) with KAPPA
      // delta = kappa * cos^2 / |sin|
      double delta_a = kappa * std::pow(std::cos(phase_a), 2) / (std::abs(std::sin(phase_a)) + 1e-9);
      double delta_b = kappa * std::pow(std::cos(phase_b), 2) / (std::abs(std::sin(phase_b)) + 1e-9);

      EraseResult res_a = erase_single_native(mu_a, delta_a, max_depth);
      EraseResult res_b = erase_single_native(mu_b, delta_b, max_depth);

      // 2. CALCULATE SPIN (THERMODYNAMICS + GEOMETRY)
      // Rotational Invariance: Thermodynamic Bit * Geometric Orientation
      int spin_a = ((res_a.erasure_distance >= 0) ? 1 : -1) * ((std::cos(phase_a) >= 0) ? 1 : -1);
      int spin_b = ((res_b.erasure_distance >= 0) ? 1 : -1) * ((std::cos(phase_b) >= 0) ? 1 : -1);

      // ROW A
      gzprintf(file_a, "%.6f,%d,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d\n",
               angle_deg, spin_a, (int)res_a.found, mu_a, delta_a,
               res_a.erasure_distance, res_a.macrostate, res_a.numerator, res_a.denominator,
               res_a.stern_brocot_path.c_str(), res_a.minimal_program.c_str(),
               res_a.program_length, res_a.shannon_entropy, res_a.left_count, res_a.right_count);

      // ROW B
      gzprintf(file_b, "%.6f,%d,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d\n",
               angle_deg, spin_b, (int)res_b.found, mu_b, delta_b,
               res_b.erasure_distance, res_b.macrostate, res_b.numerator, res_b.denominator,
               res_b.stern_brocot_path.c_str(), res_b.minimal_program.c_str(),
               res_b.program_length, res_b.shannon_entropy, res_b.left_count, res_b.right_count);
    }
    gzclose(file_a);
    gzclose(file_b);
  });
  pool.wait();
}
