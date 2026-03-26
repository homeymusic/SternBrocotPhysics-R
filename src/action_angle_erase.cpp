#include <Rcpp.h>
#include <string>
#include <vector>
#include <cmath>
#include <limits>
#include "erase.h"

using namespace Rcpp;

EraseResult action_angle_erase_single_native(double microstate, double max_erasure_radius, int max_program_length) {

  if (std::isinf(max_erasure_radius) || max_erasure_radius > 1e9) {
    max_erasure_radius = 1e9;
  }

  if (max_erasure_radius != -1.0 && std::abs(max_erasure_radius) < 1e-15) {
    return {
    0.0,
    microstate,
    microstate,
    max_erasure_radius,
    R_NaReal,
    R_NaReal,
    "",
    R_NaInt,
    R_NaReal,
    R_NaInt,
    R_NaInt,
    false
  };
  }

  // Action-Angle initialized for the phase space
  // theta = PI maps to physical left_bound (-1.0)
  // theta = 0 maps to physical right_bound (1.0)
  double theta_left = M_PI;
  double theta_right = 0.0;

  long long numerator = 0;
  long long denominator = 1;

  int minimal_program_length = 0;
  int zero_count = 0;
  int one_count = 0;

  std::string minimal_program = "";
  const size_t MAX_PATH_LEN = 128;

  // The state is the geometric center of the phase angle, projected to physical space
  double theta_mid = (theta_left + theta_right) / 2.0;
  double minimal_action_state = std::cos(theta_mid);

  double erasure_distance = minimal_action_state - microstate;
  double absolute_erasure_distance = std::abs(erasure_distance);

  while (absolute_erasure_distance >= max_erasure_radius) {

    if (minimal_program_length >= max_program_length) {
      break;
    }

    bool bit_is_one = (microstate > minimal_action_state);

    if (minimal_program.length() < MAX_PATH_LEN) {
      if (bit_is_one) {
        minimal_program += "1";
      } else {
        minimal_program += "0";
      }
    } else if (minimal_program.length() == MAX_PATH_LEN) {
      minimal_program += "...";
    }

    if (bit_is_one) {
      // Shifting the left physical wall means shifting the larger angle
      theta_left = theta_mid;
      numerator = (numerator * 2) + 1;
      one_count++;
    } else {
      // Shifting the right physical wall means shifting the smaller angle
      theta_right = theta_mid;
      numerator = (numerator * 2) - 1;
      zero_count++;
    }

    denominator *= 2;

    // Recalculate via harmonic projection
    theta_mid = (theta_left + theta_right) / 2.0;
    minimal_action_state = std::cos(theta_mid);

    erasure_distance = minimal_action_state - microstate;
    absolute_erasure_distance = std::abs(erasure_distance);
    minimal_program_length++;
  }

  double shannon_entropy = 0.0;
  if (minimal_program_length > 0) {
    double d_val = (double)minimal_program_length;
    double p0 = (double)zero_count / d_val;
    double p1 = (double)one_count / d_val;
    if (p0 > 0) shannon_entropy -= p0 * std::log2(p0);
    if (p1 > 0) shannon_entropy -= p1 * std::log2(p1);
  }

  bool found = (max_erasure_radius > 0) ?
  (absolute_erasure_distance <= max_erasure_radius) :
    (minimal_program_length <= max_program_length);

  return {
      erasure_distance,
      microstate,
      minimal_action_state,
      max_erasure_radius,
      (double)numerator,
      (double)denominator,
      minimal_program,
      minimal_program_length,
      shannon_entropy,
      zero_count,
      one_count,
      found
    };
}

DataFrame action_angle_erase_core(NumericVector microstate, double max_erasure_radius, int max_search_depth) {
  int n = microstate.size();

  NumericVector res_erasure_distance(n);
  NumericVector res_minimal_action_state(n);
  NumericVector res_numerator(n);
  NumericVector res_denominator(n);
  CharacterVector res_minimal_program(n);
  IntegerVector res_minimal_program_length(n);
  NumericVector res_shannon_entropy(n);
  IntegerVector res_zero_count(n);
  IntegerVector res_one_count(n);
  LogicalVector res_found(n);

  for (int i = 0; i < n; ++i) {
    EraseResult res = action_angle_erase_single_native(microstate[i], max_erasure_radius, max_search_depth);

    res_erasure_distance[i]       = res.erasure_distance;
    res_minimal_action_state[i]   = res.minimal_action_state;
    res_numerator[i]              = res.numerator;
    res_denominator[i]            = res.denominator;
    res_minimal_program[i]        = res.minimal_program;
    res_minimal_program_length[i] = res.minimal_program_length;
    res_shannon_entropy[i]        = res.shannon_entropy;
    res_zero_count[i]             = res.zero_count;
    res_one_count[i]              = res.one_count;
    res_found[i]                  = res.found;
  }

  return DataFrame::create(
    _["erasure_distance"]       = res_erasure_distance,
    _["microstate"]             = microstate,
    _["minimal_action_state"]   = res_minimal_action_state,
    _["max_erasure_radius"]     = max_erasure_radius,
    _["numerator"]              = res_numerator,
    _["denominator"]            = res_denominator,
    _["minimal_program"]        = res_minimal_program,
    _["minimal_program_length"] = res_minimal_program_length,
    _["shannon_entropy"]        = res_shannon_entropy,
    _["zero_count"]             = res_zero_count,
    _["one_count"]              = res_one_count,
    _["max_search_depth"]       = max_search_depth,
    _["found"]                  = res_found
  );
}

// [[Rcpp::export]]
DataFrame action_angle_erase_max_erasure_radius(NumericVector x, double max_erasure_radius) {
  if (max_erasure_radius <= 0) stop("max_erasure_radius must be positive");
  return action_angle_erase_core(x, max_erasure_radius, 20000);
}

// [[Rcpp::export]]
DataFrame action_angle_erase_depth(NumericVector x, int depth) {
  return action_angle_erase_core(x, -1.0, depth);
}

// [[Rcpp::export]]
DataFrame action_angle_erase_max_erasure_radius_and_depth(NumericVector x, double max_erasure_radius, int depth) {
  return action_angle_erase_core(x, max_erasure_radius, depth);
}
