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
void non_local_bell_sweep(
    double alice_angle_rad,
    NumericVector bob_angles_rad,
    std::string dir,
    int count,
    double microstate_start,
    double microstate_end,
    int n_threads = 0
) {
  int max_depth = 2000;
  std::vector<double> bob_angles_cpp = Rcpp::as<std::vector<double>>(bob_angles_rad);
  size_t n = bob_angles_cpp.size();

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double beta = std::remainder(bob_angles_cpp[i], 2.0 * M_PI);
    double alpha = std::remainder(alice_angle_rad, 2.0 * M_PI);

    // 1. THE NON-LOCAL BOUNDARY (The shared potential action quantum δ_θ)
    // Derived from the minor axis of the potential action (A_pot + A_kin = pi * hbar)
    double phi = std::remainder(alpha - beta, 2.0 * M_PI);

    // The scaling factor relates to hbar. Using standard normalized scale where max tolerance is 1.0 (or scaled down by pi)
    // Here we use the direct sine projection of the minor axis.
    double delta_theta = std::abs(std::sin(phi));

    char f_name[128];
    std::snprintf(f_name, sizeof(f_name), "bell_pair_alpha_%010.6f_beta_%010.6f.csv.gz", alpha, beta);
    gzFile file = gzopen((dir + "/" + f_name).c_str(), "wb1");

    // 100% Strict API Fidelity + Self-Contained Macroscopic Angles (30 Columns)
    const char* header = "microstate,alice_angle,bob_angle,delta_theta,alice_spin,bob_spin,"
    "alice_microstate,bob_microstate,"
    "alice_erasure_distance,bob_erasure_distance,alice_macrostate,bob_macrostate,"
    "alice_numerator,bob_numerator,alice_denominator,bob_denominator,"
    "alice_stern_brocot_path,bob_stern_brocot_path,alice_minimal_program,bob_minimal_program,"
    "alice_program_length,bob_program_length,alice_shannon_entropy,bob_shannon_entropy,"
    "alice_left_count,bob_left_count,alice_right_count,bob_right_count,"
    "alice_found,bob_found\n";
    gzprintf(file, header);

    // 2. THE MICROSTATE SWEEP (Rotational/Rational Invariance)
    for (int j = 0; j < count; j++) {
      double microstate = microstate_start + (microstate_end - microstate_start) * ((double)j / (double)(count - 1));

      // The Erasure Inputs: Function of microstate angle and local measurement angle
      // Singlet state applies a PI phase shift to Bob's particle
      double alice_local_phase = std::remainder(microstate - alpha, 2.0 * M_PI);
      double bob_local_phase = std::remainder((microstate + M_PI) - beta, 2.0 * M_PI);

      // Dimensionless fractional inputs for the Stern-Brocot tree mapped to [-1, 1]
      double alice_rel = alice_local_phase / M_PI;
      double bob_rel = bob_local_phase / M_PI;

      // Both particles evaluate their local rotational geometry against the shared non-local delta_theta
      EraseResult alice_erasure = erase_single_native(alice_rel, delta_theta, max_depth);
      EraseResult bob_erasure = erase_single_native(bob_rel, delta_theta, max_depth);

      // Spin projection based on the unerased quantum density
      int alice_spin = (alice_erasure.found ? alice_erasure.erasure_distance : alice_rel) >= 0 ? 1 : -1;
      int bob_spin = (bob_erasure.found ? bob_erasure.erasure_distance : bob_rel) >= 0 ? 1 : -1;

      // Write Row
      gzprintf(file, "%.6f,%.6f,%.6f,%.6f,%d,%d,"
                 "%.6f,%.6f,"
                 "%.6f,%.6f,%.6f,%.6f,"
                 "%.0f,%.0f,%.0f,%.0f,"
                 "%s,%s,%s,%s,"
                 "%d,%d,%.6f,%.6f,"
                 "%d,%d,%d,%d,"
                 "%d,%d\n",
                 microstate, alpha, beta, delta_theta, alice_spin, bob_spin,
                 alice_erasure.microstate, bob_erasure.microstate,
                 alice_erasure.erasure_distance, bob_erasure.erasure_distance,
                 alice_erasure.macrostate, bob_erasure.macrostate,
                 alice_erasure.numerator, bob_erasure.numerator,
                 alice_erasure.denominator, bob_erasure.denominator,
                 alice_erasure.stern_brocot_path.c_str(), bob_erasure.stern_brocot_path.c_str(),
                 alice_erasure.minimal_program.c_str(), bob_erasure.minimal_program.c_str(),
                 (int)alice_erasure.program_length, (int)bob_erasure.program_length,
                 alice_erasure.shannon_entropy, bob_erasure.shannon_entropy,
                 alice_erasure.left_count, bob_erasure.left_count,
                 alice_erasure.right_count, bob_erasure.right_count,
                 (int)alice_erasure.found, (int)bob_erasure.found);
    }
    gzclose(file);
  });
  pool.wait();
}
