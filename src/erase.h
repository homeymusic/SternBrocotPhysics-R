#ifndef ERASE_H
#define ERASE_H

#include <string>

struct EraseResult {
  double erasure_distance;
  double microstate;
  double minimal_action_state;
  double max_erasure_radius;
  double numerator;
  double denominator;
  std::string minimal_program;
  int minimal_program_length;
  double shannon_entropy;
  int zero_count;
  int one_count;
  bool found;
};

// Stern-Brocot declaration
EraseResult stern_brocot_erase_single_native(double microstate, double max_erasure_radius, int max_program_length);

// K-D Tree declaration
EraseResult kdtree_erase_single_native(double microstate, double max_erasure_radius, int max_program_length);

// Action-Angle declaration
EraseResult action_angle_erase_single_native(double microstate, double max_erasure_radius, int max_program_length);

#endif
