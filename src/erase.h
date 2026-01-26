#ifndef ERASE_H
#define ERASE_H

#include <Rcpp.h>
#include <string>

// 1. Data carrier struct (Pure C++ types for thread-safety)
struct EraseResult {
  double microstate;
  double macro_val;
  double shannon;
  double uncertainty;
  double c_num;
  double c_den;
  int depth;
  int count_l;
  int count_r;
  std::string path;
  std::string b_path;
  bool found;
};

// 2. Declaration of the native function
// This allows erase_experiments.cpp to call the math logic directly
EraseResult erase_single_native(double target, double uncertainty, int max_depth_limit);

// 3. Declarations for RcppExports/Adapter
Rcpp::DataFrame erase_uncertainty(Rcpp::NumericVector x, double uncertainty);
Rcpp::DataFrame erase_depth(Rcpp::NumericVector x, int depth);
Rcpp::DataFrame erase_uncertainty_and_depth(Rcpp::NumericVector x, double uncertainty, int depth);

#endif
