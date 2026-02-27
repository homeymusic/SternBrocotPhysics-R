#include <Rcpp.h>
#include <string>
#include <vector>
#include <cmath>
#include <limits>
#include "erase.h"

using namespace Rcpp;

// --- HELPER: SAFE ADDITION ---
bool safe_add(long long a, long long b, long long &res) {
  if (b > 0 && a > std::numeric_limits<long long>::max() - b) return false;
  if (b < 0 && a < std::numeric_limits<long long>::min() - b) return false;
  res = a + b;
  return true;
}

// 1. PURE C++ NATIVE CORE
EraseResult erase_single_native(double microstate, double uncertainty, int max_search_depth,
                                double lower_bound, double upper_bound,
                                double lower_action, double upper_action) {

  // --- 1. INSTANT REJECTION ---
  if ((microstate <= lower_bound && std::isinf(lower_action)) ||
      (microstate >= upper_bound && std::isinf(upper_action))) {
    return { R_NaReal, microstate, R_NaReal, uncertainty, R_NaReal, R_NaReal,
             "", "", 0, R_NaReal, 0, 0, false };
  }

  // --- 2. LOGIC TOGGLE: Uncertainty vs Depth-Only ---
  bool is_uncertainty_mode = !std::isnan(uncertainty);

  // --- 3. GEOMETRIC WINDOWING ---
  double safe_min = -INF_VAL;
  double safe_max = INF_VAL;
  double effective_target = microstate;

  if (is_uncertainty_mode) {
    if (std::abs(uncertainty) < 1e-15) {
      return { 0.0, microstate, microstate, uncertainty, R_NaReal, R_NaReal,
               "", "", 0, R_NaReal, 0, 0, false };
    }

    double target_min = microstate - uncertainty;
    double target_max = microstate + uncertainty;

    if (target_max > upper_bound) {
      double shift = target_max - upper_bound;
      target_max -= shift;
      target_min -= shift;
    }
    if (target_min < lower_bound) {
      double shift = lower_bound - target_min;
      target_min += shift;
      target_max += shift;
    }

    safe_min = target_min + (uncertainty * 1e-15);
    safe_max = target_max - (uncertainty * 1e-15);

    if (effective_target > safe_max) effective_target = safe_max;
    if (effective_target < safe_min) effective_target = safe_min;
  }

  // --- 4. STERN-BROCOT LOOP ---
  long long l_num = -1, l_den = 0;
  long long r_num = 1, r_den = 0;
  long long numerator = 0, denominator = 1;
  int program_length = 0, left_count = 0, right_count = 0;
  std::string stern_brocot_path = "";
  std::string minimal_program = "";
  double macrostate = (double)numerator / denominator;

  while (program_length < max_search_depth) {
    if (is_uncertainty_mode && macrostate >= safe_min && macrostate <= safe_max) break;

    bool move_right = (macrostate < effective_target);

    if (move_right) {
      l_num = numerator; l_den = denominator;
      right_count++;
      if (stern_brocot_path.length() < 128) {
        stern_brocot_path += "R";
        minimal_program += "1";
      }
    } else {
      r_num = numerator; r_den = denominator;
      left_count++;
      if (stern_brocot_path.length() < 128) {
        stern_brocot_path += "L";
        minimal_program += "0";
      }
    }

    long long next_num, next_den;
    if (!safe_add(l_num, r_num, next_num) || !safe_add(l_den, r_den, next_den)) break;

    numerator = next_num;
    denominator = next_den;
    if (denominator <= 0) break;

    macrostate = (double)numerator / denominator;
    program_length++;
  }

  // Entropy Calculation
  double shannon_entropy = 0.0;
  if (program_length > 0) {
    double pL = (double)left_count / (double)program_length;
    double pR = (double)right_count / (double)program_length;
    if (pL > 0) shannon_entropy -= pL * std::log2(pL);
    if (pR > 0) shannon_entropy -= pR * std::log2(pR);
  }

  bool found = is_uncertainty_mode ? (macrostate >= safe_min && macrostate <= safe_max)
    : (program_length < max_search_depth);

  return { macrostate - microstate, microstate, macrostate, uncertainty,
           (double)numerator, (double)denominator, stern_brocot_path,
           minimal_program, program_length, shannon_entropy, left_count,
           right_count, found };
}

// 2. R ADAPTER
DataFrame erase_core(NumericVector microstate, double uncertainty, int max_search_depth,
                     double lower_bound, double upper_bound,
                     double lower_action, double upper_action) {
  int n = microstate.size();
  NumericVector res_dist(n), res_macro(n), res_num(n), res_den(n), res_unc(n), res_shannon(n);
  CharacterVector res_path(n), res_min_prog(n);
  IntegerVector depths(n), res_l(n), res_r(n);
  LogicalVector res_found(n);

  for (int i = 0; i < n; ++i) {
    EraseResult res = erase_single_native(microstate[i], uncertainty, max_search_depth,
                                          lower_bound, upper_bound, lower_action, upper_action);
    res_dist[i] = res.erasure_distance;
    res_macro[i] = res.macrostate;
    res_unc[i] = res.uncertainty;
    res_num[i] = res.numerator;
    res_den[i] = res.denominator;
    res_path[i] = res.stern_brocot_path;
    res_min_prog[i] = res.minimal_program;
    depths[i] = res.program_length;
    res_shannon[i] = res.shannon_entropy;
    res_l[i] = res.left_count;
    res_r[i] = res.right_count;
    res_found[i] = res.found;
  }

  return DataFrame::create(
    _["erasure_distance"]  = res_dist,
    _["microstate"]        = microstate,
    _["macrostate"]        = res_macro,
    _["uncertainty"]       = res_unc,
    _["numerator"]         = res_num,
    _["denominator"]       = res_den,
    _["stern_brocot_path"] = res_path,
    _["minimal_program"]   = res_min_prog,
    _["program_length"]    = depths,
    _["shannon_entropy"]   = res_shannon,
    _["left_count"]        = res_l,
    _["right_count"]       = res_r,
    _["max_search_depth"]  = max_search_depth,
    _["found"]             = res_found
  );
}

// --- Exports ---

// [[Rcpp::export]]
DataFrame erase_by_uncertainty(NumericVector x, double uncertainty) {
  if (uncertainty <= 0) stop("uncertainty must be positive");
  return erase_core(x, uncertainty, 20000, -INF_VAL, INF_VAL, INF_VAL, INF_VAL);
}

// [[Rcpp::export]]
DataFrame erase_uncertainty_bounded(NumericVector x, double uncertainty,
                                    double lower_bound, double upper_bound,
                                    double lower_action = 1.0/0.0,
                                    double upper_action = 1.0/0.0) {
  if (uncertainty <= 0) stop("uncertainty must be positive");
  return erase_core(x, uncertainty, 20000, lower_bound, upper_bound, lower_action, upper_action);
}

// [[Rcpp::export]]
DataFrame erase_by_depth(NumericVector x, int depth) {
  return erase_core(x, R_NaReal, depth, -INF_VAL, INF_VAL, INF_VAL, INF_VAL);
}

// [[Rcpp::export]]
DataFrame erase_by_uncertainty_and_depth(NumericVector x, double uncertainty, int depth) {
  return erase_core(x, uncertainty, depth, -INF_VAL, INF_VAL, INF_VAL, INF_VAL);
}
