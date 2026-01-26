#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include "erase.h"

using namespace Rcpp;

//' @export
 // [[Rcpp::export]]
 void run_erasure_simulation(NumericVector momenta, std::string dir, int count, int n_threads = 0) {
   int max_depth_limit = 20000;

   // If n_threads is 0, use total cores minus 2 for responsiveness
   int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
   if (threads < 1) threads = 1;

   // Create a pool to prevent the "hang"
   RcppThread::ThreadPool pool(threads);

   pool.parallelFor(0, momenta.size(), [&](int i) {
     // Check for "Stop" button every iteration
     RcppThread::checkUserInterrupt();

     double p = momenta[i];
     double uncertainty = 1.0 / p;

     char filename_buf[128];
     std::snprintf(filename_buf, sizeof(filename_buf), "micro_macro_erasures_P_%013.6f.csv.gz", p);
     std::string full_path = dir + "/" + std::string(filename_buf);

     gzFile file = gzopen(full_path.c_str(), "wb1");
     if (file) {
       gzprintf(file, "momentum,microstate,macrostate,fluctuation,numerator,denominator,minimal_program,program_length,shannon_entropy,stern_brocot_path,uncertainty,l_count,r_count,max_search_depth,found\n");

       for (int j = 0; j < count; j++) {
         double target = -1.0 + (2.0 * j) / (double)(count - 1);
         EraseResult res = erase_single_native(target, uncertainty, max_depth_limit);

         gzprintf(file, "%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%d,%.6f,%s,%.6f,%d,%d,%d,%d\n",
                  p, res.microstate, res.macro_val, res.macro_val - res.microstate,
                  res.c_num, res.c_den, res.b_path.c_str(), res.depth, res.shannon,
                  res.path.c_str(), res.uncertainty, res.count_l, res.count_r, max_depth_limit, (int)res.found);
       }
       gzclose(file);
     }
   });

   pool.wait(); // Ensure all threads finish before returning to R
 }
