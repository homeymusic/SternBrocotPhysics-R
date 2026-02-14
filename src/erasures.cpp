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

// [[Rcpp::export]]
void erasures(NumericVector momenta, std::string dir, int n_threads = 0) {

  std::vector<double> p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = p_vec.size();

  // Track progress
  std::atomic<int> skip_count(0);
  std::atomic<int> compute_count(0);

  int max_depth_limit = 2000;
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double p = p_vec[i];

    double auto_n = std::ceil(3000.0 * p);
    if (auto_n < 100001.0) auto_n = 100001.0;
    int current_count = (int)auto_n;

    char filename[128];
    // %013.6f ensures 1.01 becomes 000001.010000, matching your previous run
    std::snprintf(filename, sizeof(filename), "erasures_P_%013.6f.csv.gz", p);
    std::string path = dir + "/" + std::string(filename);

    if (check_file_exists(path)) {
      skip_count++;
      return;
    }

    compute_count++;
    double uncertainty = 1.0 / p;
    gzFile file = gzopen(path.c_str(), "wb1");
    if (!file) return;

    gzprintf(file, "momentum,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n");

    for (int j = 0; j < current_count; j++) {
      double mu_source = (current_count > 1) ? -1.0 + (2.0 * j) / (double)(current_count - 1) : 0.0;
      EraseResult res = erase_single_native(mu_source, uncertainty, max_depth_limit);

      gzprintf(file, "%.6f,%s,%.6f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d\n",
               p, fmt_val(res.erasure_distance).c_str(), mu_source,
               fmt_val(res.macrostate).c_str(), fmt_val(res.uncertainty).c_str(),
               fmt_val(res.numerator, "%.0f").c_str(), fmt_val(res.denominator, "%.0f").c_str(),
               res.stern_brocot_path.c_str(), res.minimal_program.c_str(),
               fmt_val(res.program_length).c_str(), fmt_val(res.shannon_entropy).c_str(),
               fmt_val(res.left_count).c_str(), fmt_val(res.right_count).c_str(),
               max_depth_limit, (int)res.found);
    }
    gzclose(file);
  });

  pool.wait();

  // Print summary to R Console
  Rcout << "Simulation Summary:" << std::endl;
  Rcout << "  - Total requested: " << n << std::endl;
  Rcout << "  - Files skipped (already exist): " << skip_count.load() << std::endl;
  Rcout << "  - New files computed: " << compute_count.load() << std::endl;
}
