library(testthat)
library(SternBrocotPhysics)

# ==============================================================================
# GOLDEN RATIO ENGINE TESTS (SYMMETRIC)
# ==============================================================================

test_that("Golden Ratio: handles exact root properly", {
  # Root is now explicitly 0.0 to match the physical symmetry of the harmonic well
  res_zero <- golden_ratio_erase_squeezed_boundary_and_depth(x = 0.0, squeezed_boundary = 0.01, depth = 100)

  expect_equal(res_zero$erasure_displacement[1], 0.0, tolerance = 1e-12)
  expect_equal(res_zero$selected_microstate[1], 0.0, tolerance = 1e-12)
  expect_equal(res_zero$sequence_length[1], 0)
})

test_that("Golden Ratio: steers correctly and finds symmetric steps", {
  inv_phi <- 0.6180339887498948

  # Target the exact first Golden Cut on the right [0, 1]
  res_right <- golden_ratio_erase_squeezed_boundary_and_depth(x = inv_phi, squeezed_boundary = 1e-12, depth = 100)
  expect_equal(res_right$selected_microstate[1], inv_phi, tolerance = 1e-12)
  expect_equal(res_right$encoded_sequence[1], "1", info="Right side gets a '1'")

  # Target the exact first Golden Cut on the left [-1, 0]
  res_left <- golden_ratio_erase_squeezed_boundary_and_depth(x = -inv_phi, squeezed_boundary = 1e-12, depth = 100)
  expect_equal(res_left$selected_microstate[1], -inv_phi, tolerance = 1e-12)
  expect_equal(res_left$encoded_sequence[1], "0", info="Left side gets a '0'")
})

test_that("Golden Ratio: honors depth limit", {
  # 0.5 is NOT a simple Golden ratio fraction.
  res_depth <- golden_ratio_erase_squeezed_boundary_and_depth(x = 0.5, squeezed_boundary = 1e-15, depth = 15)

  expect_equal(res_depth$sequence_length[1], 15)
  expect_false(res_depth$found[1])
})

test_that("Golden Ratio: erase_depth wrapper works", {
  inv_phi <- 0.6180339887498948
  # The second cut to the right: bounds [INV_PHI, 1.0]
  target_second_cut <- inv_phi + (1.0 - inv_phi) * inv_phi

  res_depth_only <- golden_ratio_erase_depth(x = target_second_cut, depth = 2)

  expect_equal(res_depth_only$selected_microstate[1], target_second_cut, tolerance = 1e-12)
  expect_equal(res_depth_only$sequence_length[1], 2)
  expect_true(res_depth_only$found[1])
})
