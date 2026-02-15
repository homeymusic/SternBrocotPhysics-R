#include <Rcpp.h>
using namespace Rcpp;

//' Detect Significant Physical Features (Standard Hysteresis)
//'
//' @param sub_df DataFrame with x (coordinate) and y (density)
//' @param thresh_vec Vector of adaptive thresholds matching sub_df rows
//' @export
// [[Rcpp::export]]
DataFrame count_nodes_cpp(DataFrame sub_df, NumericVector thresh_vec) {

  if (!sub_df.containsElementNamed("x") || !sub_df.containsElementNamed("y")) {
    stop("DataFrame must contain 'x' and 'y' columns.");
  }

  NumericVector x = sub_df["x"];
  NumericVector y = sub_df["y"];
  int n = x.size();

  if (n < 2) return DataFrame::create(_["x"] = NumericVector(0), _["y"] = NumericVector(0));

  if (thresh_vec.size() != n) {
    stop("Threshold vector length must match DataFrame length.");
  }

  std::vector<double> node_x;
  std::vector<double> node_y;

  // --- STATE INITIALIZATION ---
  // State 0 = Seeking Valley / In Valley
  // State 1 = Seeking Peak / Climbing
  //
  // CRITICAL FIX: Always start in State 0.
  // Since we start scanning from the symmetry center, we are either at a Peak or a Node.
  // - If at a Node (Valley): We will see a Rise immediately and count it.
  // - If at a Peak: We will see a Drop (updating local_min) until we hit the first real valley.
  // This ensures we don't miss a central node even if it is flat or slightly noisy.
  int state = 0;

  double local_max = y[0];
  double local_min = y[0];
  double local_min_x = x[0];

  for(int i = 1; i < n; ++i) {
    double val = y[i];
    double coord = x[i];
    double local_thresh = thresh_vec[i];

    if (state == 1) {
      // --- STATE: CLIMBING (SEEKING PEAK) ---
      if (val > local_max) {
        local_max = val;
      } else {
        // Check for drop to enter Valley State
        if (val < (local_max - local_thresh)) {
          state = 0;
          local_min = val;
          local_min_x = coord;
        }
      }
    }
    else {
      // --- STATE: FALLING (SEEKING VALLEY/NODE) ---
      if (val < local_min) {
        local_min = val;
        local_min_x = coord;
      } else {
        // Check for Rise
        // Must rise by at least 'local_thresh' to confirm the previous minimum was a Node
        if (val > (local_min + local_thresh)) {

          // Confirmed Node
          node_x.push_back(local_min_x);
          node_y.push_back(local_min);

          // Switch back to seeking peak
          state = 1;
          local_max = val;
        }
      }
    }
  }

  return DataFrame::create(
    _["x"] = wrap(node_x),
    _["y"] = wrap(node_y)
  );
}
