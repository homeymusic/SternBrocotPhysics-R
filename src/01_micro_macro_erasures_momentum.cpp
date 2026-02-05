#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include "erase.h"

using namespace Rcpp;

//' @export
// [[Rcpp::export]]
void micro_macro_erasures_momentum(NumericVector momenta, std::string dir, int count, int n_threads = 0) {
  int max_depth_limit = 20000;

  // 1. Thread Safety: Copy R memory to a C++ vector immediately.
  std::vector<double> momenta_cpp = Rcpp::as<std::vector<double>>(momenta);
  size_t n_momenta = momenta_cpp.size();

  // 2. Thread Logic: Calculate core count
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  // 3. Parallel Execution
  pool.parallelFor(0, n_momenta, [&](int i) {
    double p = momenta_cpp[i];

    // Heisenberg Uncertainty relation for momentum simulation
    double uncertainty = 1.0 / (2.0 * p);

    char filename_buf[128];
    std::snprintf(filename_buf, sizeof(filename_buf), "micro_macro_erasures_P_%013.6f.csv.gz", p);
    std::string full_path = dir + "/" + std::string(filename_buf);

    gzFile file = gzopen(full_path.c_str(), "wb1");
    if (file) {
      // UPDATED HEADER: Matches new variable names and standard order
      gzprintf(file, "momentum,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n");

      for (int j = 0; j < count; j++) {
        // Shared microstate sweep from -1 to 1
        double target = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

        // Perform Erasure
        EraseResult res = erase_single_native(target, uncertainty, max_depth_limit);

        // UPDATED PRINT: Uses new struct member names
        gzprintf(file, "%.6f,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
                 p,
                 res.erasure_distance,      // Pre-calculated in struct
                 res.microstate,
                 res.macrostate,
                 res.uncertainty,
                 res.numerator,             // Was c_num
                 res.denominator,           // Was c_den
                 res.stern_brocot_path.c_str(), // Was path
                 res.minimal_program.c_str(),   // Was b_path
                 res.program_length,        // Was depth
                 res.shannon_entropy,
                 res.left_count,            // Was count_l
                 res.right_count,           // Was count_r
                 max_depth_limit,
                 (int)res.found);
      }
      gzclose(file);
    }
  });

  pool.wait();
}
