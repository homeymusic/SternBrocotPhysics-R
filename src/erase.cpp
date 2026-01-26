#include <Rcpp.h>
#include <string>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// 1. PURE C++ NATIVE CORE (Thread-safe, no R dependencies)
EraseResult erase_single_native(double target, double uncertainty, int max_depth_limit) {
  // Determine threshold
  const double threshold = (uncertainty > 0) ? uncertainty * (1.0 - 1e-15) : -1.0;

  long long l_num = -1, l_den = 0;
  long long r_num = 1, r_den = 0;
  long long c_num = 0, c_den = 1;

  int depth = 0;
  int count_l = 0;
  int count_r = 0;
  std::string path = "", b_path = "";
  double macro_val = (double)c_num / c_den;
  double error = std::abs(macro_val - target);

  // Core Loop Logic
  while (depth < max_depth_limit) {
    // Exit condition: if uncertainty is provided, use error threshold
    // If uncertainty is NA (passed as -1 or NaN), loop continues to max_depth
    if (threshold > 0 && error < threshold) break;

    if (macro_val < target) {
      l_num = c_num; l_den = c_den;
      path += "R"; b_path += "1";
      count_r++;
    } else {
      r_num = c_num; r_den = c_den;
      path += "L"; b_path += "0";
      count_l++;
    }

    c_num = l_num + r_num;
    c_den = l_den + r_den;

    if (c_den <= 0) break;

    macro_val = (double)c_num / c_den;
    error = std::abs(macro_val - target);
    depth++;
  }

  // Shannon Entropy
  double shannon = 0.0;
  if (depth > 0) {
    double d_val = (double)depth;
    double pL = (double)count_l / d_val;
    double pR = (double)count_r / d_val;
    if (pL > 0) shannon -= pL * std::log2(pL);
    if (pR > 0) shannon -= pR * std::log2(pR);
  }

  bool found = (threshold > 0) ? (error < threshold) : (depth >= max_depth_limit);

  return {target, macro_val, shannon, uncertainty, (double)c_num, (double)c_den,
          depth, count_l, count_r, path, b_path, found};
}

// 2. R ADAPTER (The "DRY" Wrapper for Rcpp exports)
DataFrame erase_core(NumericVector microstate, double uncertainty, int max_depth_limit) {
  int n = microstate.size();

  NumericVector res_num(n), res_den(n), depths(n), res_fluctuation(n), res_macro(n);
  NumericVector res_l_count(n), res_r_count(n), res_shannon(n);
  CharacterVector res_path(n), res_b_path(n);
  LogicalVector res_found(n);

  for (int i = 0; i < n; ++i) {
    EraseResult res = erase_single_native(microstate[i], uncertainty, max_depth_limit);

    res_num[i] = res.c_num;
    res_den[i] = res.c_den;
    res_macro[i] = res.macro_val;
    res_fluctuation[i] = res.macro_val - res.microstate;
    res_path[i] = res.path;
    res_b_path[i] = res.b_path;
    res_l_count[i] = res.count_l;
    res_r_count[i] = res.count_r;
    res_shannon[i] = res.shannon;
    depths[i] = res.depth;
    res_found[i] = res.found;
  }

  return DataFrame::create(
    _["microstate"]        = microstate,
    _["macrostate"]        = res_macro,
    _["fluctuation"]       = res_fluctuation,
    _["numerator"]         = res_num,
    _["denominator"]       = res_den,
    _["minimal_program"]   = res_b_path,
    _["program_length"]    = depths,
    _["shannon_entropy"]   = res_shannon,
    _["stern_brocot_path"] = res_path,
    _["uncertainty"]       = uncertainty,
    _["l_count"]           = res_l_count,
    _["r_count"]           = res_r_count,
    _["max_search_depth"]  = max_depth_limit,
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
  return erase_core(x, -1.0, depth); // -1.0 signals depth-only mode
}

// [[Rcpp::export(name = "erase_by_uncertainty_and_depth")]]
DataFrame erase_uncertainty_and_depth(NumericVector x, double uncertainty, int depth) {
  return erase_core(x, uncertainty, depth);
}
