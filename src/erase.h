#ifndef ERASE_H
#define ERASE_H

#include <string>

struct EraseResult {
  // Exact order matching the requested DataFrame
  double erasure_distance;
  double microstate;
  double minimal_action_state;
  double max_erasure_radius;
  double numerator;
  double denominator;
  std::string stern_brocot_path;
  std::string minimal_program;
  int minimal_program_length;
  double shannon_entropy;
  int left_count;
  int right_count;
  bool found;
};

// Function declaration
EraseResult erase_single_native(double microstate, double max_erasure_radius, int max_program_length);

#endif
