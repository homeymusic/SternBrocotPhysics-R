#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

inline double planck_sin(double angle, double theta_0) {
  // If the magnitude is less than the planck floor, clamp it to the floor.
  // We preserve the sign of the original angle.
  if (std::abs(angle) < theta_0) {
    return std::sin((angle < 0) ? -theta_0 : theta_0);
  }
  return std::sin(angle);
}

// Returns cos(angle), respecting the same planck limit relative to 90 degrees.
// Physics: Prevents Singularity at 90 degrees (Infinite Information).
inline double planck_cos(double angle, double theta_0) {
  // 1. Check proximity to +/- 90 degrees (The Orthogonal Singularity)
  // Distance from PI/2 (90 deg) or -PI/2 (-90 deg)
  double abs_angle = std::abs(angle);
  double dist_from_90 = std::abs(M_PI_2 - abs_angle);

  if (dist_from_90 < theta_0) {
    // We are within the vacuum wedge of 90 degrees.
    // Clamp the angle to (90 - theta_0) so cosine doesn't vanish.
    // Preserve the sign of the cosine (which flips at 90).
    // Actually, at exactly 90, cos is 0.
    // We want the minimum non-zero value: cos(90 - theta_0).

    // Determine sign of the result based on quadrant
    // Cosine is positive in Q1/Q4, negative in Q2/Q3.
    // Simple trick: use the sign of cos(angle) unless it's exactly 0.
    double native_cos = std::cos(angle);
    double sign = (native_cos >= 0) ? 1.0 : -1.0;

    // Return the minimum vacuum cosine
    return sign * std::cos(M_PI_2 - theta_0);
  }

  // 2. Check near 0 (Consistency, though less critical for cos)
  if (abs_angle < theta_0) {
    return std::cos((angle < 0) ? -theta_0 : theta_0);
  }

  return std::cos(angle);
}

//' @export
// [[Rcpp::export]]
void micro_macro_bell_erasure_sweep(
    NumericVector angles,
    double detector_aperture,  // PHYSICS: The Characteristic Angle (theta_0)
    std::string dir,
    int count,                 // Number of particles to simulate (Loop limit)
    double kappa,              // Detector Geometry Parameter
    double delta_particle,     // Source Physics Parameter
    double mu_start,
    double mu_end,
    int n_threads = 0
) {
  int max_depth = 2000;
  std::vector<double> angles_cpp = Rcpp::as<std::vector<double>>(angles);
  size_t n = angles_cpp.size();

  // --- PHYSICS: CHARACTERISTIC ANGLE (THETA_0) ---
  // The detector aperture defines the fundamental quantum of angle for this apparatus.
  // It represents the ground state width of the phase space wedge.
  double theta_0 = detector_aperture * (M_PI / 180.0);

  // Safety: Ensure we don't divide by zero if user passes 0.0
  if (theta_0 < 1e-15) theta_0 = 1e-15;

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  // Outer loop: Angles (Phase Sweep)
  pool.parallelFor(0, n, [&](int i) {
    double angle_deg = angles_cpp[i];
    double angle_rad = angle_deg * (M_PI / 180.0);

    char f_a[128], f_b[128];
    std::snprintf(f_a, sizeof(f_a), "erasure_alice_%013.6f.csv.gz", angle_deg);
    std::snprintf(f_b, sizeof(f_b), "erasure_bob_%013.6f.csv.gz", angle_deg);

    gzFile file_a = gzopen((dir + "/" + f_a).c_str(), "wb1");
    gzFile file_b = gzopen((dir + "/" + f_b).c_str(), "wb1");

    // Header
    const char* header = "angle,spin,erasure_distance,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n";

    gzprintf(file_a, header);
    gzprintf(file_b, header);

    // Inner loop: Particle Count (Simulation Iterations)
    for (int j = 0; j < count; j++) {

      // --- STEP 1: DETERMINISTIC SOURCE GENERATION ---
      double mu_particle = mu_start + (mu_end - mu_start) * ((double)j / (double)(count - 1));

      // Apply Source Constraint
      EraseResult erasure = erase_single_native(mu_particle, delta_particle, max_depth);

      // Define Particle
      double particle = erasure.found ? erasure.erasure_distance : mu_particle;
      double particle_a = particle;
      double particle_b = -particle;

      // --- STEP 2: MEASUREMENT (Detector Interaction) ---
      double phase_a = angle_rad - particle_a;
      double phase_b = angle_rad - particle_b;

      // --- ALICE ---
      // We use planck_sin/cos to enforce the Planck-scale geometry.
      // This automatically handles the P >= 1 constraint (Projection >= planck Mode).
      double proj_a = std::abs(planck_sin(phase_a, theta_0));
      double cost_a = std::pow(planck_cos(phase_a, theta_0), 2);

      double delta_a = kappa * cost_a / proj_a;

      // --- BOB ---
      double proj_b = std::abs(planck_sin(phase_b, theta_0));
      double cost_b = std::pow(planck_cos(phase_b, theta_0), 2);

      double delta_b = kappa * cost_b / proj_b;

      // Erase
      EraseResult res_a = erase_single_native(particle_a, delta_a, max_depth);
      EraseResult res_b = erase_single_native(particle_b, delta_b, max_depth);

      // --- STEP 3: OBSERVE SPIN ---
      // Determine spin direction using planck geometry for consistency
      int spin_a = ((res_a.erasure_distance >= 0) ? 1 : -1) * ((planck_cos(phase_a, theta_0) >= 0) ? 1 : -1);
      int spin_b = ((res_b.erasure_distance >= 0) ? 1 : -1) * ((planck_cos(phase_b, theta_0) >= 0) ? 1 : -1);

      // ROW A
      gzprintf(file_a, "%.6f,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
               angle_deg, spin_a,
               res_a.erasure_distance, particle_a, res_a.macrostate, delta_a,
               res_a.numerator, res_a.denominator,
               res_a.stern_brocot_path.c_str(), res_a.minimal_program.c_str(),
               res_a.program_length, res_a.shannon_entropy, res_a.left_count, res_a.right_count,
               max_depth, (int)res_a.found);

      // ROW B
      gzprintf(file_b, "%.6f,%d,%.6f,%.6f,%.6f,%.6f,%.0f,%.0f,%s,%s,%d,%.6f,%d,%d,%d,%d\n",
               angle_deg, spin_b,
               res_b.erasure_distance, particle_b, res_b.macrostate, delta_b,
               res_b.numerator, res_b.denominator,
               res_b.stern_brocot_path.c_str(), res_b.minimal_program.c_str(),
               res_b.program_length, res_b.shannon_entropy, res_b.left_count, res_b.right_count,
               max_depth, (int)res_b.found);
    }
    gzclose(file_a);
    gzclose(file_b);
  });
  pool.wait();
}
