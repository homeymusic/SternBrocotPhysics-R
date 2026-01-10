#include <Rcpp.h>
#include <string>
#include <cmath>

using namespace Rcpp;

// Maximum safety boundary for 2026 search operations
const int MAX_SEARCH_DEPTH = 20000;

// Core erasure logic template
template <typename StopPredicate>
DataFrame erase_core(NumericVector microstate, StopPredicate stop_criteria, double display_uncertainty, int max_depth_limit) {
  int n = microstate.size();

  // 1. Declare Storage Vectors (Original + New Physics)
  NumericVector res_num(n), res_den(n), depths(n), max_depths(n), res_fluctuation(n), res_macro(n);
  NumericVector res_l_count(n), res_r_count(n), res_shannon(n);
  NumericVector res_fisher_n2(n), res_fisher_n4(n); // Fisher Information
  NumericVector res_symplectic_capacity(n), res_winding_number(n), res_phase_density(n); // De Gosson

  CharacterVector res_path(n), res_b_path(n);
  LogicalVector found(n);

  for (int i = 0; i < n; ++i) {
    double target = microstate[i];

    long long l_num = -1, l_den = 0;
    long long r_num = 1, r_den = 0;
    long long c_num = 0, c_den = 1;

    int depth = 0;
    int count_l = 0;
    int count_r = 0;
    std::string path = "", b_path = "";
    double macro_val = (double)c_num / c_den;
    double error = std::abs(macro_val - target);

    while (!stop_criteria(error, depth) && depth < max_depth_limit) {
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

    // 2. Physics & Information Calculations
    double shannon = 0.0;
    double qfi_n2 = 0.0;
    double qfi_n4 = 0.0;

    if (depth > 0) {
      double d_val = (double)depth;
      double pL = (double)count_l / d_val;
      double pR = (double)count_r / d_val;

      // Entropy
      if (pL > 0) shannon -= pL * std::log2(pL);
      if (pR > 0) shannon -= pR * std::log2(pR);

      // Fisher Information (Standard HL and Super-Heisenberg)
      qfi_n2 = 4.0 * d_val * d_val * pL * pR;
      qfi_n4 = 4.0 * std::pow(d_val, 4.0) * pL * pR;
      if (pL == 0 || pR == 0) {
        qfi_n2 = d_val * d_val;
        qfi_n4 = std::pow(d_val, 4.0);
      }
    }

    // Assigning results
    res_num[i] = (double)c_num;
    res_den[i] = (double)c_den;
    res_macro[i] = macro_val;
    res_fluctuation[i] = macro_val - target;
    res_path[i] = path;
    res_b_path[i] = b_path;
    res_l_count[i] = count_l;
    res_r_count[i] = count_r;
    res_shannon[i] = shannon;
    res_fisher_n2[i] = qfi_n2;
    res_fisher_n4[i] = qfi_n4;
    res_symplectic_capacity[i] = std::abs(macro_val * (double)c_den);
    res_winding_number[i] = (double)count_r - (double)count_l;
    res_phase_density[i] = (depth > 0) ? (double)depth / (std::abs(error) + 1e-18) : 0.0;
    depths[i] = depth;
    max_depths[i] = max_depth_limit;

    if (NumericVector::is_na(display_uncertainty)) {
      found[i] = (depth >= max_depth_limit);
    } else {
      const double threshold = display_uncertainty * (1.0 - 1e-15);
      found[i] = (error < threshold);
    }
  }

  // 3. Return Final Stable API (No values removed)
  return DataFrame::create(
    _["microstate"]             = microstate,
    _["macrostate"]             = res_macro,
    _["fluctuation"]            = res_fluctuation,
    _["numerator"]              = res_num,
    _["denominator"]            = res_den,
    _["minimal_program"]        = res_b_path,
    _["kolmogorov_complexity"]  = depths,
    _["shannon_entropy"]        = res_shannon,
    _["fisher_N2"]              = res_fisher_n2,
    _["fisher_N4"]              = res_fisher_n4,
    _["symplectic_capacity"]    = res_symplectic_capacity,
    _["winding_number"]         = res_winding_number,
    _["phase_density"]          = res_phase_density,
    _["stern_brocot_path"]      = res_path,
    _["uncertainty"]            = display_uncertainty,
    _["l_count"]                = res_l_count,
    _["r_count"]                = res_r_count,
    _["max_search_depth"]       = max_depths,
    _["found"]                  = found
  );
}

// [[Rcpp::export(name = "erase_by_uncertainty")]]
DataFrame erase_uncertainty(NumericVector x, double uncertainty) {
  if (uncertainty <= 0) stop("uncertainty must be positive");
  const double threshold = uncertainty * (1.0 - 1e-15);
  return erase_core(x, [threshold](double err, int d) {
    return err < threshold;
  }, uncertainty, MAX_SEARCH_DEPTH);
}

// [[Rcpp::export(name = "erase_by_depth")]]
DataFrame erase_depth(NumericVector x, int depth) {
  if (depth < 0 || depth > MAX_SEARCH_DEPTH) stop("Invalid depth");
  return erase_core(x, [depth](double err, int d) {
    return d >= depth;
  }, NA_REAL, depth);
}

// [[Rcpp::export(name = "erase_by_uncertainty_and_depth")]]
DataFrame erase_uncertainty_and_depth(NumericVector x, double uncertainty, int depth) {
  if (uncertainty <= 0) stop("uncertainty must be positive");
  if (depth < 0 || depth > MAX_SEARCH_DEPTH) stop("Invalid depth");
  return erase_core(x, [depth](double err, int d) {
    return d >= depth;
  }, uncertainty, depth);
}
