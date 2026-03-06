#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

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

    // 1. THE NON-LOCAL CONTEXT (The core of your physics)
    double phi = std::remainder(alpha - beta, 2.0 * M_PI);
    double epsilon = 1e-9;

    // The shared thermodynamic tolerance for this specific detector pairing
    double shared_tolerance = (2.0 * std::pow(std::cos(phi), 2.0)) / (std::abs(std::sin(phi)) + epsilon);

    char f_name[128];
    std::snprintf(f_name, sizeof(f_name), "bell_pair_alpha_%010.6f_beta_%010.6f.csv.gz", alpha, beta);
    gzFile file = gzopen((dir + "/" + f_name).c_str(), "wb1");

    const char* header = "microstate,alice_spin,bob_spin,alice_distance,bob_distance,shared_tolerance\n";
    gzprintf(file, header);

    // 2. THE MICROSTATE SWEEP
    for (int j = 0; j < count; j++) {
      double microstate = microstate_start + (microstate_end - microstate_start) * ((double)j / (double)(count - 1));

      // Alice's local fractional distance from the microstate
      double alice_rel = std::remainder(microstate - alpha, 2.0 * M_PI) / M_PI;
      // Bob's local fractional distance from the microstate (anti-correlated for singlet)
      double bob_rel = std::remainder((microstate + M_PI) - beta, 2.0 * M_PI) / M_PI;

      // Both halt using the non-local shared tolerance
      EraseResult alice_erasure = erase_single_native(alice_rel, shared_tolerance, max_depth);
      EraseResult bob_erasure = erase_single_native(bob_rel, shared_tolerance, max_depth);

      int alice_spin = (alice_erasure.found ? alice_erasure.erasure_distance : alice_rel) >= 0 ? 1 : -1;
      int bob_spin = (bob_erasure.found ? bob_erasure.erasure_distance : bob_rel) >= 0 ? 1 : -1;

      gzprintf(file, "%.6f,%d,%d,%.6f,%.6f,%.6f\n",
               microstate, alice_spin, bob_spin,
               alice_erasure.erasure_distance, bob_erasure.erasure_distance, shared_tolerance);
    }
    gzclose(file);
  });
  pool.wait();
}
