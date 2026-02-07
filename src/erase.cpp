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
EraseResult erase_single_native(double microstate, double uncertainty, int max_search_depth) {

  // --- 1. HANDLE INFINITY (Clamp) ---
  if (std::isinf(uncertainty) || uncertainty > 1e9) {
    uncertainty = 1e9;
  }

  // --- 2. HANDLE ZERO UNCERTAINTY (THE IDENTITY FIX) ---
  // If uncertainty is effectively 0, the Macrostate IS the Microstate.
  // We do not need to search the tree.
  if (uncertainty != -1.0 && std::abs(uncertainty) < 1e-15) {
    return {
    0.0,            // erasure_distance: 0.0 (Perfect Match)
    microstate,     // microstate: Original
    microstate,     // macrostate: Identity
    uncertainty,    // uncertainty
    R_NaReal,       // numerator: NA (No rational approx found)
    R_NaReal,       // denominator: NA
    "",             // stern_brocot_path: Empty
    "",             // minimal_program: Empty
    R_NaInt,        // program_length: NA
    R_NaReal,       // shannon_entropy: NA (No bits generated)
    R_NaInt,        // left_count: NA
    R_NaInt,        // right_count: NA
    false           // found: False (Tree not traversed)
  };
  }

  // --- 3. NORMAL EXECUTION ---
  const double threshold = (uncertainty > 0) ? uncertainty * (1.0 - 1e-15) : -1.0;

  long long l_num = -1, l_den = 0;
  long long r_num = 1, r_den = 0;
  long long numerator = 0, denominator = 1;

  int program_length = 0;
  int left_count = 0;
  int right_count = 0;

  std::string stern_brocot_path = "";
  std::string minimal_program = "";

  // SAFETY VALVE: Max string length to prevent memory crashes during deep searches
  const size_t MAX_PATH_LEN = 128;

  double macrostate = (double)numerator / denominator;
  double erasure_distance = macrostate - microstate;
  double error = std::abs(erasure_distance);

  // Core Loop
  while (program_length < max_search_depth) {
    if (threshold > 0 && error < threshold) break;

    // Logic: Choose Left or Right
    bool move_right = (macrostate < microstate);

    // Safety Valve: Stop appending string if too long
    if (stern_brocot_path.length() < MAX_PATH_LEN) {
      if (move_right) {
        stern_brocot_path += "R";
        minimal_program += "1";
      } else {
        stern_brocot_path += "L";
        minimal_program += "0";
      }
    } else if (stern_brocot_path.length() == MAX_PATH_LEN) {
      stern_brocot_path += "...";
      minimal_program += "...";
    }

    if (move_right) {
      l_num = numerator; l_den = denominator;
      right_count++;
    } else {
      r_num = numerator; r_den = denominator;
      left_count++;
    }

    // Critical Overflow Check
    long long next_num, next_den;
    if (!safe_add(l_num, r_num, next_num) || !safe_add(l_den, r_den, next_den)) {
      break;
    }

    numerator = next_num;
    denominator = next_den;

    if (denominator <= 0) break;

    macrostate = (double)numerator / denominator;
    erasure_distance = macrostate - microstate;
    error = std::abs(erasure_distance);
    program_length++;
  }

  // Entropy Calculation
  double shannon_entropy = 0.0;
  if (program_length > 0) {
    double d_val = (double)program_length;
    double pL = (double)left_count / d_val;
    double pR = (double)right_count / d_val;
    if (pL > 0) shannon_entropy -= pL * std::log2(pL);
    if (pR > 0) shannon_entropy -= pR * std::log2(pR);
  }

  bool found = (threshold > 0) ? (error < threshold) : (program_length < max_search_depth);

  return {
    erasure_distance,
    microstate,
    macrostate,
    uncertainty,
    (double)numerator,
    (double)denominator,
    stern_brocot_path,
    minimal_program,
    program_length,
    shannon_entropy,
    left_count,
    right_count,
    found
  };
}

// 2. R ADAPTER (Standard Mappings)
DataFrame erase_core(NumericVector microstate, double uncertainty, int max_search_depth) {
  int n = microstate.size();

  NumericVector res_erasure_distance(n);
  NumericVector res_macro(n);
  NumericVector res_num(n);
  NumericVector res_den(n);
  CharacterVector res_path(n);
  CharacterVector res_b_path(n);
  IntegerVector depths(n);
  NumericVector res_shannon(n);
  IntegerVector res_l_count(n);
  IntegerVector res_r_count(n);
  LogicalVector res_found(n);

  for (int i = 0; i < n; ++i) {
    EraseResult res = erase_single_native(microstate[i], uncertainty, max_search_depth);

    res_erasure_distance[i] = res.erasure_distance;
    res_macro[i]            = res.macrostate;
    res_num[i]              = res.numerator;
    res_den[i]              = res.denominator;
    res_path[i]             = res.stern_brocot_path;
    res_b_path[i]           = res.minimal_program;
    depths[i]               = res.program_length;
    res_shannon[i]          = res.shannon_entropy;
    res_l_count[i]          = res.left_count;
    res_r_count[i]          = res.right_count;
    res_found[i]            = res.found;
  }

  return DataFrame::create(
    _["erasure_distance"]  = res_erasure_distance,
    _["microstate"]        = microstate,
    _["macrostate"]        = res_macro,
    _["uncertainty"]       = uncertainty,
    _["numerator"]         = res_num,
    _["denominator"]       = res_den,
    _["stern_brocot_path"] = res_path,
    _["minimal_program"]   = res_b_path,
    _["program_length"]    = depths,
    _["shannon_entropy"]   = res_shannon,
    _["left_count"]        = res_l_count,
    _["right_count"]       = res_r_count,
    _["max_search_depth"]  = max_search_depth,
    _["found"]             = res_found
  );
}

// [[Rcpp::export(name = "erase_by_uncertainty")]]
DataFrame erase_uncertainty(NumericVector x, double uncertainty) {
  if (uncertainty <= 0) stop("uncertainty must be positive");
  return erase_core(x, uncertainty, 20000);
}

// [[Rcpp::export(name = "erase_by_depth")]]
DataFrame erase_depth(NumericVector x, int depth) {
  return erase_core(x, -1.0, depth);
}

// [[Rcpp::export(name = "erase_by_uncertainty_and_depth")]]
DataFrame erase_uncertainty_and_depth(NumericVector x, double uncertainty, int depth) {
  return erase_core(x, uncertainty, depth);
}
