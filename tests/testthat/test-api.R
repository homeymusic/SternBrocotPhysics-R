test_that("Erase API remains stable", {
  # Define the mandatory schema
  expected_columns <- c(
    "erasure_distance", "microstate", "macrostate", "uncertainty",
    "numerator", "denominator", "stern_brocot_path", "minimal_program",
    "program_length", "shannon_entropy", "left_count", "right_count",
    "max_search_depth", "found"
  )

  # Run a standard erasure
  res <- erase_by_uncertainty(x = 0.5, uncertainty = 0.1)

  # 1. Check for missing or renamed columns
  expect_true(all(expected_columns %in% names(res)),
              info = "API BREAK: Missing columns in EraseResult")

  # 2. Check for unexpected additions
  expect_equal(length(names(res)), length(expected_columns),
               info = "API BREAK: Unexpected columns added to EraseResult")

  # 3. Check data types
  expect_type(res$stern_brocot_path, "character")
  expect_type(res$found, "logical")
})
