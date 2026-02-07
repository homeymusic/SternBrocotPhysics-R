#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// --- 1. SHARED HELPERS (Safe Formatting) ---

// Helper: Format Doubles safely (Handling NA and NaN)
std::string fmt_val(double val, const char* format = "%.6f") {
  if (std::isnan(val) || R_IsNA(val)) return "NA";
  char buf[64];
  std::snprintf(buf, sizeof(buf), format, val);
  return std::string(buf);
}

// Helper: Format Integers safely
std::string fmt_val(int val) {
  if (val == R_NaInt) return "NA";
  return std::to_string(val);
}

// --- 2. CORE SIMULATION WRITER (The "DRY" Logic) ---
// This handles file I/O, looping, rotation, and safe writing for ALL experiment types.
void write_erasure_simulation(
    std::string filepath,
    std::string param_name, // e.g., "angle" or "momentum"
    double param_value,     // The actual angle or momentum value
    double uncertainty,
    double phase_shift,     // 0.0 for momentum, (angle/90) for spin
    int count,
    int max_depth_limit,
    double tolerance = 1e-10
) {
  gzFile file = gzopen(filepath.c_str(), "wb1");
  if (!file) return;

  // Dynamic Header: First column matches the experiment type
  gzprintf(file, "%s,erasure_distance,spin,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n",
           param_name.c_str());

  for (int j = 0; j < count; j++) {
    // 1. Global Microstate Sweep (-1.0 to 1.0)
    double mu_global = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

    // 2. Apply Phase Shift (Coordinate Rotation) & Wrap
    double mu_local = mu_global - phase_shift;
    while (mu_local < -1.0) mu_local += 2.0;
    while (mu_local > 1.0)  mu_local -= 2.0;

    // 3. Perform Measurement
    EraseResult res = erase_single_native(mu_local, uncertainty, max_depth_limit);

    // 4. Calculate Spin (Standardized for both types)
    std::string spin_str;
    if (std::isnan(res.erasure_distance) || R_IsNA(res.erasure_distance)) {
      spin_str = "NA";
    } else {
      int s = (res.erasure_distance > tolerance) ? 1 : (res.erasure_distance < -tolerance ? -1 : 0);
      spin_str = std::to_string(s);
    }

    // 5. Write Row (Using Safe Formatters)
    gzprintf(file, "%.6f,%s,%s,%.6f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d\n",
             param_value,
             fmt_val(res.erasure_distance).c_str(),
             spin_str.c_str(),
             mu_global,
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
}

// --- 3. EXPORTED FUNCTIONS ---

//' @export
// [[Rcpp::export]]
void micro_macro_erasures_momentum(NumericVector momenta, std::string dir, int count, int n_threads = 0) {
  int max_depth_limit = 20000;

  std::vector<double> p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = p_vec.size();

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double p = p_vec[i];

    // Logic: Uncertainty = 1/p.
    // If p=0, Uncertainty is Inf (erase_single_native handles Inf safely).
    double uncertainty = (p == 0.0) ? R_PosInf : (1.0 / p);

    char filename[128];
    std::snprintf(filename, sizeof(filename), "micro_macro_erasures_P_%013.6f.csv.gz", p);
    std::string path = dir + "/" + std::string(filename);

    // Call Shared Writer (Phase Shift = 0.0 for momentum)
    write_erasure_simulation(path, "momentum", p, uncertainty, 0.0, count, max_depth_limit);
  });

  pool.wait();
}

//' @export
// [[Rcpp::export]]
void micro_macro_erasures_angle(NumericVector angles, std::string dir, int count, int n_threads = 0) {
  int max_depth_limit = 20000;

  std::vector<double> angles_cpp = Rcpp::as<std::vector<double>>(angles);
  size_t n = angles_cpp.size();

  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);

  pool.parallelFor(0, n, [&](int i) {
    double angle_deg = angles_cpp[i];
    double angle_rad = angle_deg * (M_PI / 180.0);

    // Logic: Rotational Phase Shift
    double phase_shift = angle_deg / 90.0;

    double abs_sin = std::abs(std::sin(angle_rad));
    double abs_cos = std::abs(std::cos(angle_rad));

    // Logic: Trigonometric Uncertainties
    double delta_alpha = (abs_sin < 1e-12) ? 2e9 : (std::pow(std::cos(angle_rad), 2)) / abs_sin;
    double delta_beta  = (abs_cos < 1e-12) ? 2e9 : (std::pow(std::sin(angle_rad), 2)) / abs_cos;

    // Alpha Write
    char f_alpha[128];
    std::snprintf(f_alpha, sizeof(f_alpha), "micro_macro_erasures_alpha_%013.6f.csv.gz", angle_deg);
    write_erasure_simulation(dir + "/" + f_alpha, "angle", angle_deg, delta_alpha, phase_shift, count, max_depth_limit);

    // Beta Write
    char f_beta[128];
    std::snprintf(f_beta, sizeof(f_beta), "micro_macro_erasures_beta_%013.6f.csv.gz", angle_deg);
    write_erasure_simulation(dir + "/" + f_beta, "angle", angle_deg, delta_beta, phase_shift, count, max_depth_limit);
  });

  pool.wait();
}
