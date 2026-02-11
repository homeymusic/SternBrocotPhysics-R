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
    NumericVector detector_angles,
    std::string dir,
    int count,
    double angular_momentum,
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
    double detector_angle_deg = detector_angles_cpp[i];
    double detector_angle_rad = detector_angle_deg * (M_PI / 180.0);

    char f_a[128], f_b[128];
    std::snprintf(f_a, sizeof(f_a), "erasure_alice_%013.6f.csv.gz", detector_angle_deg);
    std::snprintf(f_b, sizeof(f_b), "erasure_bob_%013.6f.csv.gz", detector_angle_deg);

    gzFile file_a = gzopen((dir + "/" + f_a).c_str(), "wb1");
    gzFile file_b = gzopen((dir + "/" + f_b).c_str(), "wb1");

    const char* header = "angle,spin,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n";

    gzprintf(file_a, header);
    gzprintf(file_b, header);

    for (int j = 0; j < count; j++) {

      double microstate_particle_angle = microstate_particle_angle_start + (microstate_particle_angle_end - microstate_particle_angle_start) * ((double)j / (double)(count - 1));

      EraseResult erasure = erase_single_native(microstate_particle_angle, 1/angular_momentum, max_depth);

      double particle_angle_alice = erasure.found ? erasure.erasure_distance : microstate_particle_angle;
      double particle_angle_bob   = -particle_angle_alice;

      double phase_alice = detector_angle_rad - particle_angle_alice;
      double phase_bob   = detector_angle_rad - particle_angle_bob;

      int spin_alice = std::cos(phase_alice) >= 0 ? 1 : -1;
      int spin_bob   = std::cos(phase_bob) >= 0   ? 1 : -1;

      // ROW A
      gzprintf(file_a, "%.6f,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
               detector_angle_deg, spin_alice,
               erasure.erasure_distance, particle_angle_alice, erasure.macrostate, erasure.uncertainty,
               erasure.numerator, erasure.denominator,
               erasure.stern_brocot_path.c_str(), erasure.minimal_program.c_str(),
               erasure.program_length, erasure.shannon_entropy, erasure.left_count, erasure.right_count,
               max_depth, (int)erasure.found);

      // ROW B
      gzprintf(file_b, "%.6f,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
               detector_angle_deg, spin_bob,
               erasure.erasure_distance, particle_angle_bob, erasure.macrostate, erasure.uncertainty,
               erasure.numerator, erasure.denominator,
               erasure.stern_brocot_path.c_str(), erasure.minimal_program.c_str(),
               erasure.program_length, erasure.shannon_entropy, erasure.left_count, erasure.right_count,
               max_depth, (int)erasure.found);
    }
    gzclose(file_a);
    gzclose(file_b);
  });
  pool.wait();
}
