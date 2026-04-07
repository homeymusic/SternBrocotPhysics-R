#include <Rcpp.h>
#include <string>
#include <vector>
#include <cmath>
#include <limits>
#include "erase.h"

using namespace Rcpp;

EraseResult action_angle_erase_single_native(double blob_center, double squeezed_boundary, int max_sequence_length) {

  if (std::isinf(squeezed_boundary) || squeezed_boundary > 1e9) {
    squeezed_boundary = 1e9;
  }

  if (squeezed_boundary != -1.0 && std::abs(squeezed_boundary) < 1e-15) {
    return {
    0.0,
    blob_center,
    blob_center,
    squeezed_boundary,
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

  int sequence_length = 0;
  int zero_count = 0;
  int one_count = 0;

  std::string encoded_sequence = "";
  const size_t MAX_PATH_LEN = 128;

  // The state is the geometric center of the phase angle, projected to physical space
  double theta_mid = (theta_left + theta_right) / 2.0;
  double selected_microstate = std::cos(theta_mid);

  double erasure_displacement = selected_microstate - blob_center;
  double abs_displacement = std::abs(erasure_displacement);

  // Match the strict boundary inequality: |x_mu^* - x_b| > delta_x
  while (abs_displacement > squeezed_boundary) {

    if (sequence_length >= max_sequence_length) {
      break;
    }

    bool bit_is_one = (blob_center > selected_microstate);

    if (encoded_sequence.length() < MAX_PATH_LEN) {
      if (bit_is_one) {
        encoded_sequence += "1";
      } else {
        encoded_sequence += "0";
      }
    } else if (encoded_sequence.length() == MAX_PATH_LEN) {
      encoded_sequence += "...";
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
    selected_microstate = std::cos(theta_mid);

    erasure_displacement = selected_microstate - blob_center;
    abs_displacement = std::abs(erasure_displacement);
    sequence_length++;
  }

  double shannon_entropy = 0.0;
  if (sequence_length > 0) {
    double d_val = (double)sequence_length;
    double p0 = (double)zero_count / d_val;
    double p1 = (double)one_count / d_val;
    if (p0 > 0) shannon_entropy -= p0 * std::log2(p0);
    if (p1 > 0) shannon_entropy -= p1 * std::log2(p1);
  }

  bool found = (squeezed_boundary > 0) ?
  (abs_displacement <= squeezed_boundary) :
    (sequence_length <= max_sequence_length);

  return {
      erasure_displacement,
      blob_center,
      selected_microstate,
      squeezed_boundary,
      (double)numerator,
      (double)denominator,
      encoded_sequence,
      sequence_length,
      shannon_entropy,
      zero_count,
      one_count,
      found
    };
}

DataFrame action_angle_erase_core(NumericVector blob_center, double squeezed_boundary, int max_search_depth) {
  int n = blob_center.size();

  NumericVector res_erasure_displacement(n);
  NumericVector res_selected_microstate(n);
  NumericVector res_numerator(n);
  NumericVector res_denominator(n);
  CharacterVector res_encoded_sequence(n);
  IntegerVector res_sequence_length(n);
  NumericVector res_shannon_entropy(n);
  IntegerVector res_zero_count(n);
  IntegerVector res_one_count(n);
  LogicalVector res_found(n);

  for (int i = 0; i < n; ++i) {
    EraseResult res = action_angle_erase_single_native(blob_center[i], squeezed_boundary, max_search_depth);

    res_erasure_displacement[i] = res.erasure_displacement;
    res_selected_microstate[i]  = res.selected_microstate;
    res_numerator[i]            = res.numerator;
    res_denominator[i]          = res.denominator;
    res_encoded_sequence[i]     = res.encoded_sequence;
    res_sequence_length[i]      = res.sequence_length;
    res_shannon_entropy[i]      = res.shannon_entropy;
    res_zero_count[i]           = res.zero_count;
    res_one_count[i]            = res.one_count;
    res_found[i]                = res.found;
  }

  return DataFrame::create(
    _["erasure_displacement"] = res_erasure_displacement,
    _["blob_center"]          = blob_center,
    _["selected_microstate"]  = res_selected_microstate,
    _["squeezed_boundary"]    = squeezed_boundary,
    _["numerator"]            = res_numerator,
    _["denominator"]          = res_denominator,
    _["encoded_sequence"]     = res_encoded_sequence,
    _["sequence_length"]      = res_sequence_length,
    _["shannon_entropy"]      = res_shannon_entropy,
    _["zero_count"]           = res_zero_count,
    _["one_count"]            = res_one_count,
    _["max_search_depth"]     = max_search_depth,
    _["found"]                = res_found
  );
}

// [[Rcpp::export]]
DataFrame action_angle_erase_squeezed_boundary(NumericVector x, double squeezed_boundary) {
  if (squeezed_boundary <= 0) stop("squeezed_boundary must be positive");
  return action_angle_erase_core(x, squeezed_boundary, 20000);
}

// [[Rcpp::export]]
DataFrame action_angle_erase_depth(NumericVector x, int depth) {
  return action_angle_erase_core(x, -1.0, depth);
}

// [[Rcpp::export]]
DataFrame action_angle_erase_squeezed_boundary_and_depth(NumericVector x, double squeezed_boundary, int depth) {
  return action_angle_erase_core(x, squeezed_boundary, depth);
}
