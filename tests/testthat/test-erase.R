library(testthat)
library(SternBrocotPhysics)

test_that("erase handles exact microstates properly (Identity Fix)", {
  # We use erase_by_max_erasure_radius_and_depth because erase_by_max_erasure_radius throws an R-side stop for <= 0
  res_zero <- erase_by_max_erasure_radius_and_depth(x = 0.5, max_erasure_radius = 0.0, depth = 100)

  expect_equal(res_zero$erasure_distance[1], 0.0, info = "Zero max_erasure_radius should return exact identity.")
  expect_equal(res_zero$minimal_action_state[1], 0.5, info = "minimal_action_state should equal microstate.")
  expect_false(res_zero$found[1], info = "Found should be false since the tree isn't traversed.")
})

test_that("erase finds exact simple rationals quickly", {
  res_half <- erase_by_max_erasure_radius_and_depth(x = 0.5, max_erasure_radius = 0.1, depth = 100)

  expect_equal(res_half$minimal_action_state[1], 0.5, info = "Should immediately find exact fraction 1/2.")
  expect_equal(res_half$minimal_program_length[1], 2, info = "1/2 requires exactly 1 step (1 node).")
  expect_true(res_half$found[1], info = "Exact hit inside max_erasure_radius should return true.")
})

test_that("erase honors max_program_length", {
  # Given an irrational number, the search should terminate exactly at the depth limit
  pi_approx <- pi - 3.0 # Fractional part of pi: 0.14159...

  res_depth <- erase_by_max_erasure_radius_and_depth(x = pi_approx, max_erasure_radius = 1e-12, depth = 15)

  expect_equal(res_depth$minimal_program_length[1], 15, info = "Search must stop at max_program_length.")
  expect_false(res_depth$found[1], info = "Should not find a path within 1e-12 in only 15 steps.")
})

test_that("erase steers correctly (L vs R paths)", {
  # 1/3 -> Path should steer Left
  res_third <- erase_by_max_erasure_radius_and_depth(x = 1/3, max_erasure_radius = 0.05, depth = 100)

  expect_equal(res_third$minimal_action_state[1], 1/3, tolerance = 1e-12, info = "Should find 1/3 exactly.")
  expect_equal(res_third$stern_brocot_path[1], "RLL", info = "1/3 is less than 1/2, first step is L.")

  # 2/3 -> Path should steer Right
  res_two_thirds <- erase_by_max_erasure_radius_and_depth(x = 2/3, max_erasure_radius = 0.05, depth = 100)

  expect_equal(res_two_thirds$minimal_action_state[1], 2/3, tolerance = 1e-12, info = "Should find 2/3 exactly.")
  expect_equal(res_two_thirds$stern_brocot_path[1], "RLR", info = "2/3 is greater than 1/2, first step is R.")
})

test_that("erase_by_depth wrapper works as expected without max_erasure_radius limit", {
  # 3/4 requires exactly 4 steps: 1/2 (L) -> 2/3 (R) -> 3/4 (R)
  res_depth_only <- erase_by_depth(x = 0.75, depth = 4)

  expect_equal(res_depth_only$minimal_action_state[1], 0.75, info = "Should land exactly on 3/4 at depth 3.")
  expect_equal(res_depth_only$minimal_program_length[1], 4, info = "Depth should be exactly 3.")
  # Since max_erasure_radius is -1, 'found' resolves to (minimal_program_length < max_program_length). 3 < 3 is FALSE.
  expect_false(res_depth_only$found[1], info = "Found is strictly false when hitting the depth ceiling in depth-only mode.")
})
