#include <Rcpp.h>
#include <string>
#include <vector>
#include <cmath>
#include <limits>
#include "erase.h"

using namespace Rcpp;

bool safe_add(long long a, long long b, long long &res) {
  if (b > 0 && a > std::numeric_limits<long long>::max() - b) return false;
  if (b < 0 && a < std::numeric_limits<long long>::min() - b) return false;
  res = a + b;
  return true;
}

EraseResult stern_brocot_erase_single_native(double blob_center, double squeezed_boundary, int max_sequence_length) {

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

  long long left_num = -1, left_den = 0;
  long long right_num = 1, right_den = 0;
  long long num = 0, den = 1;

  int sequence_length = 0;
  int zero_count = 0;
  int one_count = 0;

  std::string encoded_sequence = "";
  const size_t MAX_PATH_LEN = 128;

  double selected_microstate = (double)num / den;
  double erasure_displacement = selected_microstate - blob_center;
  double abs_displacement = std::abs(erasure_displacement);

  // Follows pseudocode: While |x_mu^* - x_b| > delta x
  while (abs_displacement > squeezed_boundary) {

    if (sequence_length >= max_sequence_length) {
      break;
    }

    if (selected_microstate < blob_center) {
      left_num = num; left_den = den;
      if (encoded_sequence.length() < MAX_PATH_LEN) {
        encoded_sequence += "1";
      } else if (encoded_sequence.length() == MAX_PATH_LEN) {
        encoded_sequence += "...";
      }
      one_count++;
    } else {
      right_num = num; right_den = den;
      if (encoded_sequence.length() < MAX_PATH_LEN) {
        encoded_sequence += "0";
      } else if (encoded_sequence.length() == MAX_PATH_LEN) {
        encoded_sequence += "...";
      }
      zero_count++;
    }

    long long next_num, next_den;
    if (!safe_add(left_num, right_num, next_num) || !safe_add(left_den, right_den, next_den)) {
      break;
    }

    num = next_num;
    den = next_den;

    if (den <= 0) break;

    selected_microstate = (double)num / den;
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
      (double)num,
      (double)den,
      encoded_sequence,
      sequence_length,
      shannon_entropy,
      zero_count,
      one_count,
      found
    };
}

DataFrame stern_brocot_erase_core(NumericVector blob_center, double squeezed_boundary, int max_search_depth) {
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
    EraseResult res = stern_brocot_erase_single_native(blob_center[i], squeezed_boundary, max_search_depth);

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
DataFrame stern_brocot_erase_squeezed_boundary(NumericVector x, double squeezed_boundary) {
  if (squeezed_boundary <= 0) stop("squeezed_boundary must be positive");
  return stern_brocot_erase_core(x, squeezed_boundary, 20000);
}

// [[Rcpp::export]]
DataFrame stern_brocot_erase_depth(NumericVector x, int depth) {
  return stern_brocot_erase_core(x, -1.0, depth);
}

// [[Rcpp::export]]
DataFrame stern_brocot_erase_squeezed_boundary_and_depth(NumericVector x, double squeezed_boundary, int depth) {
  return stern_brocot_erase_core(x, squeezed_boundary, depth);
}
