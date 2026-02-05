#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

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

    double sin_t = std::sin(theta_rad);
    double cos_t = std::cos(theta_rad);
    double budget_coupler = sin_t + cos_t;

    // --- PHYSICALLY HONEST MAPPING ---
    double angular_uncertainty = cos_t / budget_coupler;

    char filename_buf[128];
    std::snprintf(filename_buf, sizeof(filename_buf), "micro_macro_erasures_theta_%013.6f.csv.gz", theta_deg);
    std::string full_path = dir + "/" + std::string(filename_buf);

    gzFile file = gzopen(full_path.c_str(), "wb1");
    if (file) {
      // UPDATED HEADER: Aligned with new struct and DataFrame order
      gzprintf(file, "theta,erasure_distance,spin,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n");

      for (int j = 0; j < count; j++) {
        // Shared microstate sweep from -1 to 1
        double mu = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

        // Perform Erasure
        EraseResult res = erase_single_native(mu, angular_uncertainty, max_depth_limit);

        // Calculate Spin based on the returned erasure distance
        // (Spin is just the sign of the error: +1 for rounding up, -1 for rounding down)
        int spin = (res.erasure_distance > tolerance) ? 1 : (res.erasure_distance < -tolerance ? -1 : 0);

        // UPDATED PRINT: Uses new struct member names
        gzprintf(file, "%.6f,%.6f,%d,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
                 theta_deg,
                 res.erasure_distance,          // Pre-calculated in struct
                 spin,                          // Computed locally
                 res.microstate,
                 res.macrostate,
                 res.uncertainty,
                 res.numerator,                 // Was c_num
                 res.denominator,               // Was c_den
                 res.stern_brocot_path.c_str(), // Was path
                 res.minimal_program.c_str(),   // Was b_path
                 res.program_length,            // Was depth
                 res.shannon_entropy,
                 res.left_count,                // Was count_l
                 res.right_count,               // Was count_r
                 max_depth_limit,
                 (int)res.found);
      }
      gzclose(file);
    }
  });

  pool.wait();
}
