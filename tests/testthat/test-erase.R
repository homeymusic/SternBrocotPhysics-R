library(testthat)
library(SternBrocotPhysics)

test_that("erase handles exact microstates properly (Identity Fix)", {
  # We use erase_by_uncertainty_and_depth because erase_by_uncertainty throws an R-side stop for <= 0
  res_zero <- erase_by_uncertainty_and_depth(x = 0.5, uncertainty = 0.0, depth = 100)

  expect_equal(res_zero$erasure_distance[1], 0.0, info = "Zero uncertainty should return exact identity.")
  expect_equal(res_zero$macrostate[1], 0.5, info = "Macrostate should equal microstate.")
  expect_false(res_zero$found[1], info = "Found should be false since the tree isn't traversed.")
})

test_that("erase finds exact simple rationals quickly", {
  res_half <- erase_by_uncertainty_and_depth(x = 0.5, uncertainty = 0.1, depth = 100)

  expect_equal(res_half$macrostate[1], 0.5, info = "Should immediately find exact fraction 1/2.")
  expect_equal(res_half$program_length[1], 2, info = "1/2 requires exactly 1 step (1 node).")
  expect_true(res_half$found[1], info = "Exact hit inside uncertainty should return true.")
})

test_that("erase honors max_search_depth", {
  # Given an irrational number, the search should terminate exactly at the depth limit
  pi_approx <- pi - 3.0 # Fractional part of pi: 0.14159...

  res_depth <- erase_by_uncertainty_and_depth(x = pi_approx, uncertainty = 1e-12, depth = 15)

  expect_equal(res_depth$program_length[1], 15, info = "Search must stop at max_search_depth.")
  expect_false(res_depth$found[1], info = "Should not find a path within 1e-12 in only 15 steps.")
})

test_that("erase steers correctly (L vs R paths)", {
  # 1/3 -> Path should steer Left
  res_third <- erase_by_uncertainty_and_depth(x = 1/3, uncertainty = 0.05, depth = 100)

  expect_equal(res_third$macrostate[1], 1/3, tolerance = 1e-12, info = "Should find 1/3 exactly.")
  expect_equal(res_third$stern_brocot_path[1], "RLL", info = "1/3 is less than 1/2, first step is L.")

  # 2/3 -> Path should steer Right
  res_two_thirds <- erase_by_uncertainty_and_depth(x = 2/3, uncertainty = 0.05, depth = 100)

  expect_equal(res_two_thirds$macrostate[1], 2/3, tolerance = 1e-12, info = "Should find 2/3 exactly.")
  expect_equal(res_two_thirds$stern_brocot_path[1], "RLR", info = "2/3 is greater than 1/2, first step is R.")
})

test_that("erase_by_depth wrapper works as expected without uncertainty limit", {
  # 3/4 requires exactly 4 steps: 1/2 (L) -> 2/3 (R) -> 3/4 (R)
  res_depth_only <- erase_by_depth(x = 0.75, depth = 4)

  expect_equal(res_depth_only$macrostate[1], 0.75, info = "Should land exactly on 3/4 at depth 3.")
  expect_equal(res_depth_only$program_length[1], 4, info = "Depth should be exactly 3.")
  # Since uncertainty is -1, 'found' resolves to (program_length < max_search_depth). 3 < 3 is FALSE.
  expect_false(res_depth_only$found[1], info = "Found is strictly false when hitting the depth ceiling in depth-only mode.")
})

test_that("erase_uncertainty_bounded handles the PIB Infinite Wall", {
  # 1. Microstate at 0.95, Wall at 1.0, Uncertainty 0.1
  # The window [0.85, 1.05] slides to [0.90, 1.00].
  # Search should succeed because it can resolve inside the wall.
  res_success <- erase_uncertainty_bounded(x = 0.95, uncertainty = 0.1,
                                           lower_bound = -1.0, upper_bound = 1.0)
  expect_true(res_success$found[1])
  expect_true(res_success$macrostate[1] <= 1.0)

  # 2. Microstate at 1.1, Wall at 1.0
  # Since default action is Inf, this must be instantly erased (PIB rule).
  res_fail <- erase_uncertainty_bounded(x = 1.1, uncertainty = 0.1,
                                        lower_bound = -1.0, upper_bound = 1.0)
  expect_false(res_fail$found[1])
  expect_true(is.na(res_fail$macrostate[1]))
})

test_that("erase_uncertainty_bounded allows tunneling with finite Action", {
  # Microstate outside the wall at 1.1, Wall at 1.0.
  # Uncertainty 0.5 reaches back to 0.6 (inside the box).
  # With a finite action penalty, the instant-rejection block is bypassed.
  res_tunnel <- erase_uncertainty_bounded(x = 1.1, uncertainty = 0.5,
                                          lower_bound = -1.0, upper_bound = 1.0,
                                          lower_action = 1.0, upper_action = 1.0)

  expect_true(res_tunnel$found[1])
  # The macrostate should have resolved INSIDE the boundary [ -1, 1 ]
  expect_true(res_tunnel$macrostate[1] <= 1.0)
})

test_that("Backwards compatibility: erase_by_uncertainty still works as free space", {
  # This uses the original wrapper which we want to ensure still works
  res_free <- erase_by_uncertainty(x = 5.0, uncertainty = 0.1)
  expect_true(res_free$found[1])
  expect_equal(res_free$macrostate[1], 5.0, tolerance = 0.1)
})
