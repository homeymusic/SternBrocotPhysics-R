#ifndef ERASE_H
#define ERASE_H

#include <string>

struct EraseResult {
  // Exact order matching the requested DataFrame
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

// Function declaration
EraseResult erase_single_native(double microstate, double uncertainty, int max_search_depth);

#endif
