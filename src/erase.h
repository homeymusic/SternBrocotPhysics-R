#ifndef ERASE_H
#define ERASE_H

#include <Rcpp.h>
#include <string>
#include <limits>

#ifndef INF_VAL
#define INF_VAL std::numeric_limits<double>::infinity()
#endif

struct EraseResult {
  double erasure_distance;
  double microstate;
  double macrostate;
  double uncertainty;
  double numerator;
  double denominator;
  std::string stern_brocot_path;
  std::string minimal_program;
  int program_length;
  double shannon_entropy;
  int left_count;
  int right_count;
  bool found;
};

EraseResult erase_single_native(
    double microstate,
    double uncertainty,
    int max_search_depth,
    double lower_bound  = -INF_VAL,
    double upper_bound  = INF_VAL,
    double lower_action = INF_VAL,
    double upper_action = INF_VAL
);

#endif
