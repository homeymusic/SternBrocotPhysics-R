#include <Rcpp.h>
#include <RcppThread.h>
#include <zlib.h>
#include <string>
#include <cstdio>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// --- 1. SHARED HELPERS ---
std::string fmt_val(double val, const char* format = "%.6f") {
  if (std::isnan(val) || R_IsNA(val)) return "NA";
  char buf[64];
  std::snprintf(buf, sizeof(buf), format, val);
  return std::string(buf);
}

std::string fmt_val(int val) {
  if (val == R_NaInt) return "NA";
  return std::to_string(val);
}

// --- 2. CORE SIMULATION WRITER ---
void write_erasure_simulation(
    std::string filepath,
    std::string param_name,
    double param_value,
    double angle_deg,
    double uncertainty,
    int count,
    int max_depth_limit,
    bool is_bob,             // Singlet State Logic
    double tolerance = 1e-10
) {
  gzFile file = gzopen(filepath.c_str(), "wb1");
  if (!file) return;

  // 1. GEOMETRY: Detector Polarity
  double angle_rad = angle_deg * (M_PI / 180.0);
  int polarity = (std::cos(angle_rad) < -1e-9) ? -1 : 1;

  gzprintf(file, "%s,erasure_distance,spin,microstate,macrostate,uncertainty,numerator,denominator,stern_brocot_path,minimal_program,program_length,shannon_entropy,left_count,right_count,max_search_depth,found\n",
           param_name.c_str());

  for (int j = 0; j < count; j++) {
    // 2. Global Microstate (The Source)
    double mu_source = (count > 1) ? -1.0 + (2.0 * j) / (double)(count - 1) : 0.0;

    // 3. SINGLET STATE LOGIC
    // Alice measures the particle "as is".
    // Bob measures the "anti-particle" (-mu).
    double mu_local = is_bob ? -mu_source : mu_source;

    // 4. EFFECTIVE INPUT (Deep Polarity Fix)
    // Apply geometric polarity of the detector (flip input if detector is inverted)
    double mu_effective = mu_local * polarity;

    // 5. MEASUREMENT
    EraseResult res = erase_single_native(mu_effective, uncertainty, max_depth_limit);

    // 6. CALCULATE SPIN
    std::string spin_str;
    if (std::isnan(res.erasure_distance) || R_IsNA(res.erasure_distance)) {
      spin_str = "NA";
    } else {
      int s = 0;
      if (res.erasure_distance > tolerance) s = 1;
      else if (res.erasure_distance < -tolerance) s = -1;
      else {
        if (res.macrostate > 0) s = 1;
        else if (res.macrostate < 0) s = -1;
        else s = 0;
      }
      spin_str = std::to_string(s);
    }

    gzprintf(file, "%.6f,%s,%s,%.6f,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d\n",
             param_value,
             fmt_val(res.erasure_distance).c_str(),
             spin_str.c_str(),
             mu_source, // Log the SOURCE microstate
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
  // Momentum logic remains unchanged (Single observer context)
  int max_depth_limit = 2000;
  std::vector<double> p_vec = Rcpp::as<std::vector<double>>(momenta);
  size_t n = p_vec.size();
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;
  RcppThread::ThreadPool pool(threads);
  pool.parallelFor(0, n, [&](int i) {
    double p = p_vec[i];
    double uncertainty = (p == 0.0) ? R_PosInf : (1.0 / p);
    char filename[128];
    std::snprintf(filename, sizeof(filename), "micro_macro_erasures_P_%013.6f.csv.gz", p);
    std::string path = dir + "/" + std::string(filename);
    write_erasure_simulation(path, "momentum", p, 0.0, uncertainty, count, max_depth_limit, false);
  });
  pool.wait();
}

//' @export
// [[Rcpp::export]]
void micro_macro_erasures_angle(NumericVector angles, std::string dir, int count, double K_factor = 1.0, int n_threads = 0) {
  // Added K_factor argument (default 1.0)
  int max_depth_limit = 2000;
  std::vector<double> angles_cpp = Rcpp::as<std::vector<double>>(angles);
  size_t n = angles_cpp.size();
  int threads = (n_threads <= 0) ? (int)std::thread::hardware_concurrency() - 2 : n_threads;
  if (threads < 1) threads = 1;

  RcppThread::ThreadPool pool(threads);
  pool.parallelFor(0, n, [&](int i) {
    double angle_deg = angles_cpp[i];
    double angle_rad = angle_deg * (M_PI / 180.0);

    // Updated calculations:
    // delta_alpha = K_factor * cos^2(angle)
    // delta_beta  = K_factor * sin^2(angle)
    double cos_val = std::cos(angle_rad);
    double sin_val = std::sin(angle_rad);

    double delta_alpha = K_factor * (cos_val * cos_val);
    double delta_beta  = K_factor * (sin_val * sin_val);

    // Alpha (Alice) - Measures Source
    char f_alpha[128];
    std::snprintf(f_alpha, sizeof(f_alpha), "micro_macro_erasures_alpha_%013.6f.csv.gz", angle_deg);
    write_erasure_simulation(dir + "/" + f_alpha, "angle", angle_deg, angle_deg, delta_alpha, count, max_depth_limit, false);

    // Beta (Bob) - Measures Anti-Source
    char f_beta[128];
    std::snprintf(f_beta, sizeof(f_beta), "micro_macro_erasures_beta_%013.6f.csv.gz", angle_deg);
    write_erasure_simulation(dir + "/" + f_beta, "angle", angle_deg, angle_deg, delta_beta, count, max_depth_limit, true);
  });
  pool.wait();
}
