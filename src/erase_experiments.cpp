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
void run_erasure_simulation(NumericVector momenta, std::string dir, int count, int n_threads = 0) {
  int max_depth_limit = 20000;

  // 1. Thread Safety: Copy R memory to a C++ vector immediately.
  // This prevents R's Garbage Collector from causing crashes during parallel access.
  std::vector<double> momenta_cpp = Rcpp::as<std::vector<double>>(momenta);
  size_t n_momenta = momenta_cpp.size();

  // 2. Thread Logic: Calculate core count
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  // 3. Parallel Execution: Using the thread-safe C++ vector
  pool.parallelFor(0, n_momenta, [&](int i) {
    // Note: RcppThread::checkUserInterrupt() is handled safely within the pool
    // context by the RcppThread library's internal logic.

    double p = momenta_cpp[i];
    double uncertainty = 1.0 / (2.0 * p);

    char filename_buf[128];
    std::snprintf(filename_buf, sizeof(filename_buf), "micro_macro_erasures_P_%013.6f.csv.gz", p);
    std::string full_path = dir + "/" + std::string(filename_buf);

    // wb1 provides faster compression (lower level) to reduce I/O bottlenecks
    gzFile file = gzopen(full_path.c_str(), "wb1");
    if (file) {
      gzprintf(file, "momentum,microstate,macrostate,erasure_distance,numerator,denominator,minimal_program,program_length,shannon_entropy,stern_brocot_path,uncertainty,l_count,r_count,max_search_depth,found\n");

      for (int j = 0; j < count; j++) {
        // Handle edge case for count = 1 to avoid division by zero
        double target = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

        EraseResult res = erase_single_native(target, uncertainty, max_depth_limit);

        gzprintf(file, "%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%d,%.6f,%s,%.6f,%d,%d,%d,%d\n",
                 p, res.microstate, res.macro_val, res.macro_val - res.microstate,
                 res.c_num, res.c_den, res.b_path.c_str(), res.depth, res.shannon,
                 res.path.c_str(), res.uncertainty, res.count_l, res.count_r, max_depth_limit, (int)res.found);
      }
      gzclose(file);
    }
  });

  // pool.wait() is called automatically by the RcppThread destructor,
  // but explicit call is fine for clarity.
  pool.wait();
}
