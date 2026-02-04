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

   int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
   if (threads < 1) threads = 1;

   RcppThread::ThreadPool pool(threads);

   pool.parallelFor(0, n_angles, [&](int i) {
     double theta_deg = angles_cpp[i];
     double theta_rad = theta_deg * (M_PI / 180.0);

     // --- THE RIGID ROTOR MAPPING ---
     // The Stern-Brocot uncertainty is driven by the sin^2 projection
     // of the phase-space angle.
     double angular_uncertainty = std::pow(std::sin(theta_rad), 2.0);

     char filename_buf[128];
     std::snprintf(filename_buf, sizeof(filename_buf), "micro_macro_erasures_theta_%013.6f.csv.gz", theta_deg);
     std::string full_path = dir + "/" + std::string(filename_buf);

     gzFile file = gzopen(full_path.c_str(), "wb1");
     if (file) {
       // HONEST & COMPLETE HEADER
       // 'theta' is the independent variable.
       // 'spin' is the new outcome for Bell/CHSH analysis.
       // All other columns match the Landauer schema of the 01 dataset.
       gzprintf(file, "theta,microstate,macrostate,erasure_distance,spin,numerator,denominator,minimal_program,program_length,shannon_entropy,stern_brocot_path,uncertainty,l_count,r_count,max_search_depth,found\n");

       for (int j = 0; j < count; j++) {
         // Uniform sweep of the microstate space mu
         double target = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

         EraseResult res = erase_single_native(target, angular_uncertainty, max_depth_limit);

         double dist = res.macro_val - res.microstate;
         // The robust spin logic for experimentalist binning
         int spin = (dist > tolerance) ? 1 : (dist < -tolerance ? -1 : 0);

         gzprintf(file, "%.6f,%.6f,%.6f,%.6f,%d,%.0f,%.0f,%s,%d,%.6f,%s,%.6f,%d,%d,%d,%d\n",
                  theta_deg, res.microstate, res.macro_val, dist, spin,
                  res.c_num, res.c_den, res.b_path.c_str(), res.depth, res.shannon,
                  res.path.c_str(), res.uncertainty, res.count_l, res.count_r, max_depth_limit, (int)res.found);
       }
       gzclose(file);
     }
   });

   pool.wait();
 }
