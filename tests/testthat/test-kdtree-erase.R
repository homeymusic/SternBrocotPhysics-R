library(testthat)
library(SternBrocotPhysics)

# ==============================================================================
# KD-TREE ENGINE TESTS
# ==============================================================================

test_that("KD-Tree: erase handles exact microstates properly", {
  res_zero <- kdtree_erase_max_erasure_radius_and_depth(x = 0.25, max_erasure_radius = 0.0, depth = 100)

  expect_equal(res_zero$erasure_distance[1], 0.0, info = "Zero max_erasure_radius should return exact identity.")
  expect_equal(res_zero$minimal_action_state[1], 0.25, info = "minimal_action_state should equal microstate.")
  expect_false(res_zero$found[1], info = "Found should be false since the tree isn't traversed.")
})

test_that("KD-Tree: finds exact dyadic rationals perfectly", {
  # The KD-Tree initializes at [-1, 1] with center 0.0
  # x = 0.5 should take exactly 1 step (bit 1 -> new center is 0.5)
  res_half <- kdtree_erase_max_erasure_radius_and_depth(x = 0.5, max_erasure_radius = 0.01, depth = 100)

  expect_equal(res_half$minimal_action_state[1], 0.5, info = "Should immediately find exact center 0.5.")
  expect_equal(res_half$minimal_program_length[1], 1, info = "KD-tree takes exactly 1 step to hit 0.5 from root 0.0.")
  expect_true(res_half$found[1], info = "Exact hit inside max_erasure_radius should return true.")
})

test_that("KD-Tree: honors max_program_length", {
  pi_approx <- pi - 3.0 # Fractional part of pi: 0.14159...

  res_depth <- kdtree_erase_max_erasure_radius_and_depth(x = pi_approx, max_erasure_radius = 1e-12, depth = 15)

  expect_equal(res_depth$minimal_program_length[1], 15, info = "Search must stop at max_program_length.")
  expect_false(res_depth$found[1], info = "Should not find a path within 1e-12 in only 15 steps.")
})

test_that("KD-Tree: steers correctly (0 vs 1 paths)", {
  # Target 0.75
  # Step 0: Center 0.0. 0.75 > 0.0 -> bit '1'. New center 0.5
  # Step 1: Center 0.5. 0.75 > 0.5 -> bit '1'. New center 0.75
  res_three_quarters <- kdtree_erase_max_erasure_radius_and_depth(x = 0.75, max_erasure_radius = 0.01, depth = 100)

  expect_equal(res_three_quarters$minimal_action_state[1], 0.75, tolerance = 1e-12)
  expect_equal(res_three_quarters$minimal_program[1], "11", info = "0.75 steering in KD-Tree is 11.")

  # Target -0.5
  # Step 0: Center 0.0. -0.5 < 0.0 -> bit '0'. New center -0.5.
  res_neg_half <- kdtree_erase_max_erasure_radius_and_depth(x = -0.5, max_erasure_radius = 0.01, depth = 100)

  expect_equal(res_neg_half$minimal_action_state[1], -0.5, tolerance = 1e-12)
  expect_equal(res_neg_half$minimal_program[1], "0", info = "-0.5 steering in KD-Tree is just 0.")
})

test_that("KD-Tree: erase_depth wrapper works", {
  # 0.375 requires exactly 3 steps in KD-Tree:
  # 1. > 0 (1) -> center 0.5
  # 2. < 0.5 (0) -> center 0.25
  # 3. > 0.25 (1) -> center 0.375. Path: "101"
  res_depth_only <- kdtree_erase_depth(x = 0.375, depth = 3)

  expect_equal(res_depth_only$minimal_action_state[1], 0.375, info = "Should land exactly on 0.375 at depth 3.")
  expect_equal(res_depth_only$minimal_program_length[1], 3, info = "Depth should be exactly 3.")
  expect_true(res_depth_only$found[1], info = "Found is strictly true when hitting the depth ceiling.")
})
