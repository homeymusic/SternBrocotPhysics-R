#include <Rcpp.h>
using namespace Rcpp;

//' Detect Oscillatory Nodes in Physical State Density
//'
//' @param sub_df A DataFrame containing 'x' and 'y'.
//' @param thresh The sensitivity threshold.
//' @param global_h_range The total range of the histogram counts.
//' @return A DataFrame of detected node coordinates (x, y).
//' @export
// [[Rcpp::export]]
DataFrame find_nodes_cpp(DataFrame sub_df, double thresh, double global_h_range) {

  // 1. Column Extraction & Validation
  if (!sub_df.containsElementNamed("x") || !sub_df.containsElementNamed("y")) {
    stop("DataFrame must contain 'x' and 'y' columns.");
  }

  NumericVector x = sub_df["x"];
  NumericVector y = sub_df["y"];
  int n = x.size();

  // 2. Handle Edge Cases (Empty or Single Point)
  if (n < 2) {
    return DataFrame::create(_["x"] = NumericVector(0), _["y"] = NumericVector(0));
  }

  if (global_h_range <= 0) global_h_range = 1.0;

  // 3. Logic Setup
  std::vector<double> res_x;
  std::vector<double> res_y;
  bool ready_to_fire = true;
  double accumulator = 0;

  // 4. Node Detection Loop
  for(int i = 0; i < (n - 1); ++i) {
    double local_change = (y[i+1] - y[i]) / global_h_range;
    accumulator += local_change;

    if (ready_to_fire) {
      if (accumulator < -thresh) accumulator = -thresh;
      if (accumulator >= thresh) {
        res_x.push_back(x[i+1]);
        res_y.push_back(y[i+1]);
        ready_to_fire = false;
        accumulator = 0;
      }
    } else {
      if (accumulator > thresh) accumulator = thresh;
      if (accumulator <= -thresh) {
        ready_to_fire = true;
        accumulator = 0;
      }
    }
  }

  // 5. Direct Return
  return DataFrame::create(
    _["x"] = wrap(res_x),
    _["y"] = wrap(res_y)
  );
}
