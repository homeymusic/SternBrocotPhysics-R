library(testthat)
library(SternBrocotPhysics)

# ==============================================================================
# STERN-BROCOT ENGINE TESTS
# ==============================================================================

test_that("Stern-Brocot: erase handles exact microstates properly (Identity Fix)", {
  res_zero <- stern_brocot_erase_max_erasure_radius_and_depth(x = 0.5, max_erasure_radius = 0.0, depth = 100)

  expect_equal(res_zero$erasure_distance[1], 0.0, info = "Zero max_erasure_radius should return exact identity.")
  expect_equal(res_zero$minimal_action_state[1], 0.5, info = "minimal_action_state should equal microstate.")
  expect_false(res_zero$found[1], info = "Found should be false since the tree isn't traversed.")
})

test_that("Stern-Brocot: finds exact simple rationals quickly", {
  res_half <- stern_brocot_erase_max_erasure_radius_and_depth(x = 0.5, max_erasure_radius = 0.1, depth = 100)

  expect_equal(res_half$minimal_action_state[1], 0.5, info = "Should immediately find exact fraction 1/2.")
  expect_equal(res_half$minimal_program_length[1], 2, info = "1/2 requires exactly 2 steps from 0/1.")
  expect_true(res_half$found[1], info = "Exact hit inside max_erasure_radius should return true.")
})

test_that("Stern-Brocot: honors max_program_length", {
  pi_approx <- pi - 3.0 # Fractional part of pi: 0.14159...

  res_depth <- stern_brocot_erase_max_erasure_radius_and_depth(x = pi_approx, max_erasure_radius = 1e-12, depth = 15)

  expect_equal(res_depth$minimal_program_length[1], 15, info = "Search must stop at max_program_length.")
  expect_false(res_depth$found[1], info = "Should not find a path within 1e-12 in only 15 steps.")
})

test_that("Stern-Brocot: steers correctly (0 vs 1 paths)", {
  # 1/3 -> Path should steer 100 (Right, Left, Left)
  res_third <- stern_brocot_erase_max_erasure_radius_and_depth(x = 1/3, max_erasure_radius = 0.05, depth = 100)

  expect_equal(res_third$minimal_action_state[1], 1/3, tolerance = 1e-12, info = "Should find 1/3 exactly.")
  expect_equal(res_third$minimal_program[1], "100", info = "1/3 steering: 1 (>0), 0 (<1), 0 (<1/2).")

  # 2/3 -> Path should steer 101 (Right, Left, Right)
  res_two_thirds <- stern_brocot_erase_max_erasure_radius_and_depth(x = 2/3, max_erasure_radius = 0.05, depth = 100)

  expect_equal(res_two_thirds$minimal_action_state[1], 2/3, tolerance = 1e-12, info = "Should find 2/3 exactly.")
  expect_equal(res_two_thirds$minimal_program[1], "101", info = "2/3 steering: 1 (>0), 0 (<1), 1 (>1/2).")
})

test_that("Stern-Brocot: erase_depth wrapper works", {
  # 3/4 requires exactly 4 steps: 0(R)->1(L)->1/2(R)->2/3(R)->3/4 -> "1011"
  res_depth_only <- stern_brocot_erase_depth(x = 0.75, depth = 4)

  expect_equal(res_depth_only$minimal_action_state[1], 0.75, info = "Should land exactly on 3/4 at depth 4.")
  expect_equal(res_depth_only$minimal_program_length[1], 4, info = "Depth should be exactly 4.")
  expect_true(res_depth_only$found[1], info = "Found is strictly true when hitting the depth ceiling in depth-only mode.")
})
