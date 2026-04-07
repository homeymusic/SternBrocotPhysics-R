#ifndef ERASE_H
#define ERASE_H

#include <string>

struct EraseResult {
  double erasure_displacement;  // epsilon_x^*
  double blob_center;           // x_b
  double selected_microstate;   // x_mu^*
  double squeezed_boundary;     // delta x
  double numerator;             // num
  double denominator;           // den
  std::string encoded_sequence; // s_x^*
  int sequence_length;          // N_x
  double shannon_entropy;
  int zero_count;
  int one_count;
  bool found;
};

// Stern-Brocot declaration
EraseResult stern_brocot_erase_single_native(double blob_center, double squeezed_boundary, int max_sequence_length);

// K-D Tree declaration
EraseResult kdtree_erase_single_native(double blob_center, double squeezed_boundary, int max_sequence_length);

// Action-Angle declaration
EraseResult action_angle_erase_single_native(double blob_center, double squeezed_boundary, int max_sequence_length);

// Golden Ratio (KAM) declaration
EraseResult golden_ratio_erase_single_native(double blob_center, double squeezed_boundary, int max_sequence_length);

#endif
