library(testthat)
library(SternBrocotPhysics)

# ==============================================================================
# ACTION-ANGLE ENGINE TESTS
# ==============================================================================

test_that("Action-Angle: erase handles exact blob centers properly", {
  # The Action-Angle tree initializes with bounds [PI, 0].
  # Center angle is PI/2. cos(PI/2) = 0.0.
  res_zero <- action_angle_erase_squeezed_boundary_and_depth(x = 0.0, squeezed_boundary = 0.01, depth = 100)

  expect_equal(res_zero$erasure_displacement[1], 0.0, tolerance = 1e-15, info = "0.0 is the exact root center of the Action-Angle tree.")
  expect_equal(res_zero$selected_microstate[1], 0.0, tolerance = 1e-15)
  expect_equal(res_zero$sequence_length[1], 0, info = "Root center should require 0 steps.")
})

test_that("Action-Angle: finds exact dyadic angles perfectly", {
  # target: cos(PI/4) = sqrt(2)/2 = 0.70710678...
  # Step 1: Center 0.0. Target > 0.0 -> bit '1'. New bounds [PI/2, 0].
  # New center: PI/4. cos(PI/4) is an exact hit!
  target_val <- cos(pi / 4)

  res_pi_four <- action_angle_erase_squeezed_boundary_and_depth(x = target_val, squeezed_boundary = 1e-10, depth = 100)

  expect_equal(res_pi_four$selected_microstate[1], target_val, tolerance = 1e-15)
  expect_equal(res_pi_four$sequence_length[1], 1, info = "cos(PI/4) takes exactly 1 step (bit 1).")
  expect_equal(res_pi_four$encoded_sequence[1], "1")
  expect_true(res_pi_four$found[1])
})

test_that("Action-Angle: honors depth limit on irrational angles", {
  # x = 0.5 corresponds to theta = PI/3.
  # 1/3 is NOT a dyadic rational (denominator is not a power of 2).
  # Therefore, Action-Angle can NEVER hit x = 0.5 exactly; it requires an infinite sequence!
  res_depth <- action_angle_erase_squeezed_boundary_and_depth(x = 0.5, squeezed_boundary = 1e-15, depth = 15)

  expect_equal(res_depth$sequence_length[1], 15, info = "Search must stop at depth limit.")
  expect_false(res_depth$found[1], info = "Should not find cos(PI/3) perfectly in finite dyadic steps.")
})

test_that("Action-Angle: steers correctly (0 vs 1 paths)", {
  # Target cos(3*PI/4) = -0.70710678...
  # Root center 0.0. Target < 0.0 -> bit '0'. New center is 3*PI/4.
  target_val_left <- cos(3 * pi / 4)

  res_neg_angle <- action_angle_erase_squeezed_boundary_and_depth(x = target_val_left, squeezed_boundary = 1e-10, depth = 100)

  expect_equal(res_neg_angle$selected_microstate[1], target_val_left, tolerance = 1e-15)
  expect_equal(res_neg_angle$encoded_sequence[1], "0", info = "Negative target steers to the left angle (bit 0).")
})

test_that("Action-Angle: erase_depth wrapper works", {
  # Target 1 step to the right: center cos(PI/4) = 0.7071...
  res_depth_only <- action_angle_erase_depth(x = 0.7071067811865476, depth = 1)

  expect_equal(res_depth_only$selected_microstate[1], 0.7071067811865476, tolerance = 1e-15)
  expect_equal(res_depth_only$sequence_length[1], 1)
  expect_true(res_depth_only$found[1], info = "Found is strictly true when hitting the depth ceiling.")
})
