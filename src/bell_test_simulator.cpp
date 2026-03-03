#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

//' @export
// [[Rcpp::export]]
void micro_macro_bell_erasure_sweep(
    std::string persona,
    NumericVector detector_angles,
    std::string dir,
    int count,
    double microstate_particle_angle_start,
    double microstate_particle_angle_end,
    int n_threads = 0
) {
  int max_depth = 2000;
  std::vector<double> detector_angles_cpp = Rcpp::as<std::vector<double>>(detector_angles);
  size_t n = detector_angles_cpp.size();

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {

    double detector_angle_rad = detector_angles_cpp[i];

    char f_name[128];

    std::snprintf(f_name, sizeof(f_name), "erasure_%s_%013.6f.csv.gz", persona.c_str(), detector_angle_rad);

    gzFile file = gzopen((dir + "/" + f_name).c_str(), "wb1");

    const char* header = "angle,spin,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n";
    gzprintf(file, header);

    for (int j = 0; j < count; j++) {
      // Linear interpolation of microstate range
      double microstate = microstate_particle_angle_start +
        (microstate_particle_angle_end - microstate_particle_angle_start) * ((double)j / (double)(count - 1));

      // 1. Contextual Alignment
      detector_angle_rad = std::remainder(detector_angle_rad, 2.0 * M_PI);
      microstate = std::remainder(microstate, 2.0 * M_PI);
      double alpha = std::remainder(microstate - detector_angle_rad, 2.0 * M_PI) / M_PI;

      // 2. Dynamic Erasure Window
      // double delta_phi = ((1.0 / std::abs(std::cos(alpha))) - 1.0);
      // double delta_phi = 1.0 * std::abs(std::cos(alpha));

      double delta_phi = 1.0;

      // double delta_phi = (sqrt(5.0) + 1.0) / 2.0;
      // double delta_phi = 300.0;
      // double delta_phi = 0.1;
      // 3. Execute Native Erasure
      EraseResult erasure = erase_single_native(alpha, delta_phi, max_depth);

      // 4. Map to Macrostates
      double erasure_distance = erasure.found ? erasure.erasure_distance : 0.0;
      double particle_angle = detector_angle_rad + erasure_distance;
      int spin = std::cos(particle_angle) >= 0 ? 1 : -1;

      // Write Row (using %f for radians instead of degrees)
      gzprintf(file, "%.6f,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
               detector_angle_rad, spin,
               erasure.erasure_distance, particle_angle, erasure.macrostate, erasure.uncertainty,
               erasure.numerator, erasure.denominator,
               erasure.stern_brocot_path.c_str(), erasure.minimal_program.c_str(),
               erasure.program_length, erasure.shannon_entropy, erasure.left_count, erasure.right_count,
               max_depth, (int)erasure.found);
    }
    gzclose(file);
  });
  pool.wait();
}
