#include <Rcpp.h>
#include <string>
#include <vector>
#include <cmath>
#include "erase.h"

using namespace Rcpp;

// 1. PURE C++ NATIVE CORE
EraseResult erase_single_native(double microstate, double uncertainty, int max_search_depth) {

  const double threshold = (uncertainty > 0) ? uncertainty * (1.0 - 1e-15) : -1.0;

  long long l_num = -1, l_den = 0;
  long long r_num = 1, r_den = 0;
  long long numerator = 0, denominator = 1;

  int program_length = 0;
  int left_count = 0;
  int right_count = 0;

  std::string stern_brocot_path = "";
  std::string minimal_program = "";

  double macrostate = (double)numerator / denominator;
  double erasure_distance = macrostate - microstate;
  double error = std::abs(erasure_distance);

  // Core Loop
  while (program_length < max_search_depth) {
    if (threshold > 0 && error < threshold) break;

    if (macrostate < microstate) {
      l_num = numerator; l_den = denominator;
      stern_brocot_path += "R"; minimal_program += "1";
      right_count++;
    } else {
      r_num = numerator; r_den = denominator;
      stern_brocot_path += "L"; minimal_program += "0";
      left_count++;
    }

    numerator = l_num + r_num;
    denominator = l_den + r_den;

    if (denominator <= 0) break;

    macrostate = (double)numerator / denominator;

    erasure_distance = macrostate - microstate;
    error = std::abs(erasure_distance);
    program_length++;
  }

  // Entropy
  double shannon_entropy = 0.0;
  if (program_length > 0) {
    double d_val = (double)program_length;
    double pL = (double)left_count / d_val;
    double pR = (double)right_count / d_val;
    if (pL > 0) shannon_entropy -= pL * std::log2(pL);
    if (pR > 0) shannon_entropy -= pR * std::log2(pR);
  }

  bool found = (threshold > 0) ? (error < threshold) : (program_length >= max_search_depth);

  // RETURN ORDER ALIGNED WITH STRUCT DEFINITION
  return {
    erasure_distance,   // 1. First item
    microstate,         // 2.
    macrostate,         // 3.
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

// 2. R ADAPTER
DataFrame erase_core(NumericVector microstate, double uncertainty, int max_search_depth) {
  int n = microstate.size();

  // Vectors initialized in target order
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

    // Map struct members to vectors
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

  // DataFrame in exact requested order
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
