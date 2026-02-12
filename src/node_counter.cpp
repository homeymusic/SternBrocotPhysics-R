#include <Rcpp.h>
using namespace Rcpp;

//' Detect Significant Physical Features (Hysteresis)
//'
//' @param sub_df DataFrame with x (coordinate) and y (density)
//' @param thresh The Gabor Uncertainty Threshold
//' @export
// [[Rcpp::export]]
DataFrame count_nodes_cpp(DataFrame sub_df, double thresh) {

  if (!sub_df.containsElementNamed("x") || !sub_df.containsElementNamed("y")) {
    stop("DataFrame must contain 'x' and 'y' columns.");
  }

  NumericVector x = sub_df["x"];
  NumericVector y = sub_df["y"];
  int n = x.size();

  if (n < 2) return DataFrame::create(_["x"] = NumericVector(0), _["y"] = NumericVector(0));

  std::vector<double> node_x;
  std::vector<double> node_y;

  // --- STATE MACHINE ---
  // State: 0 = Seeking Valley (Moving Down), 1 = Seeking Peak (Moving Up)
  int state = 0;

  // Track extrema values AND their coordinates
  double local_max = y[0];
  double local_max_x = x[0]; // New tracker

  double local_min = y[0];
  double local_min_x = x[0]; // New tracker

  for(int i = 1; i < n; ++i) {
    double val = y[i];
    double coord = x[i];

    if (state == 1) {
      // --- STATE: CLIMBING (SEEKING PEAK) ---
      if (val > local_max) {
        local_max = val;
        local_max_x = coord; // Update peak location
      } else {
        // Check for significant drop (Peak Confirmed)
        if (val < (local_max - thresh)) {
          state = 0;           // Switch to looking for a valley
          local_min = val;
          local_min_x = coord; // Reset floor tracker
        }
      }
    }
    else {
      // --- STATE: FALLING (SEEKING VALLEY/NODE) ---
      if (val < local_min) {
        local_min = val;
        local_min_x = coord; // Update valley location
      } else {
        // Check for significant rise (Valley/Node Confirmed)
        if (val > (local_min + thresh)) {
          // FEATURE: We record the node at the TRUE BOTTOM, not current x[i]
          node_x.push_back(local_min_x);
          node_y.push_back(local_min);

          state = 1;           // Switch to looking for a peak
          local_max = val;
          local_max_x = coord; // Reset ceiling tracker
        }
      }
    }
  }

  return DataFrame::create(
    _["x"] = wrap(node_x),
    _["y"] = wrap(node_y)
  );
}
