#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include <sys/stat.h>
#include <algorithm>
#include <atomic>
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

//' Run Stern-Brocot Particle in a Box Simulation
//'
//' @param momenta Vector of momentum values (P) to simulate.
//' @param dir Output directory.
//' @param n_threads Number of threads (0 = auto).
//' @export
// [[Rcpp::export]]
void pib_erasures(NumericVector momenta, std::string dir, int n_threads = 0) {

  std::vector<double> p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = p_vec.size();

  std::atomic<int> skip_count(0);
  std::atomic<int> compute_count(0);

  int max_depth_limit = 2000;
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double p = p_vec[i];

    // High-resolution grid for smooth density computation
    int current_count = 100001;

    char filename[128];
    std::snprintf(filename, sizeof(filename), "pib_erasures_P_%013.6f.csv.gz", p);
    std::string path = dir + "/" + std::string(filename);

    if (check_file_exists(path)) {
      skip_count++;
      return;
    }

    compute_count++;

    // Physics: HUP Scaling
    double uncertainty = 1.0 / (2.0 * M_PI * p);

    gzFile file = gzopen(path.c_str(), "wb1");
    if (!file) return;

    // Header matches test-api stability requirements
    gzprintf(file, "momentum,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n");

    for (int j = 0; j < current_count; j++) {
      double step_size = 2.0 / (double)current_count;
      double mu_source = -1.0 + (step_size / 2.0) + (j * step_size);

      // Call core with PIB boundaries
      EraseResult res = erase_single_native(
        mu_source,
        uncertainty,
        max_depth_limit,
        -1.0, // lower_bound
        1.0  // upper_bound
      );

      gzprintf(file, "%.6f,%s,%.6f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d\n",
               p,
               fmt_val(res.erasure_distance).c_str(),
               mu_source,
               fmt_val(res.macrostate).c_str(),
               fmt_val(res.uncertainty).c_str(),
               fmt_val(res.numerator, "%.0f").c_str(),
               fmt_val(res.denominator, "%.0f").c_str(),
               res.stern_brocot_path.c_str(),
               res.minimal_program.c_str(),
               fmt_val((double)res.program_length, "%.0f").c_str(),
               fmt_val(res.shannon_entropy).c_str(),
               fmt_val((double)res.left_count, "%.0f").c_str(),
               fmt_val((double)res.right_count, "%.0f").c_str(),
               max_depth_limit,
               (int)res.found);
    }
    gzclose(file);
  });

  pool.wait();
  Rcout << "Simulation complete. Computed: " << compute_count << ", Skipped: " << skip_count << std::endl;
}
