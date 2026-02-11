#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// --- 1. HELPERS ---
static std::string fmt_val(double val, const char* format = "%.6f") {
  if (std::isnan(val) || R_IsNA(val)) return "NA";
  char buf[64];
  std::snprintf(buf, sizeof(buf), format, val);
  return std::string(buf);
}

// --- 2. EXPORTED API ---

//' @export
// [[Rcpp::export]]
void micro_macro_erasures_momentum(NumericVector momenta, std::string dir, int count, int n_threads = 0) {
  int max_depth_limit = 2000;
  std::vector<double> p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = p_vec.size();

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double p = p_vec[i];
    double uncertainty = 1.0 / p;

    char filename[128];
    std::snprintf(filename, sizeof(filename), "micro_macro_erasures_P_%013.6f.csv.gz", p);
    std::string path = dir + "/" + std::string(filename);

    gzFile file = gzopen(path.c_str(), "wb1");
    if (!file) return;

    // Header: Spin column removed
    gzprintf(file, "momentum,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n");

    for (int j = 0; j < count; j++) {
      double mu_source = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

      // Core Computation
      EraseResult res = erase_single_native(mu_source, uncertainty, max_depth_limit);

      // Row output: Spin argument and format specifier removed
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
               fmt_val(res.program_length).c_str(),
               fmt_val(res.shannon_entropy).c_str(),
               fmt_val(res.left_count).c_str(),
               fmt_val(res.right_count).c_str(),
               max_depth_limit,
               (int)res.found);
    }
    gzclose(file);
  });

  pool.wait();
}
