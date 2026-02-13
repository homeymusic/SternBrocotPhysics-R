#include <Rcpp.h>
#include <algorithm> // For std::max
using namespace Rcpp;

//' Detect Significant Physical Features (Hysteresis)
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

   // --- STATE MACHINE ---
   // State: 0 = Seeking Valley (Moving Down), 1 = Seeking Peak (Moving Up)
   int state = 0;

   double local_max = y[0];
   double local_min = y[0];
   double local_min_x = x[0];

   for(int i = 1; i < n; ++i) {
     double val = y[i];
     double coord = x[i];
     double local_thresh = thresh_vec[i];

     // Define Strict Criteria based on local_thresh
     // 1. A valley must be deep enough to enter (Drop > Thresh)
     // 2. A node must be SIGNIFICANT (Sum > 3T or Max > 2T)
     double sum_limit = 3.0 * local_thresh;
     double strong_limit = 2.0 * local_thresh;

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
         double rise = val - local_min;

         // Basic Noise Filter: Must rise at least 1 threshold to consider confirmation
         if (rise > local_thresh) {
           double drop = local_max - local_min;

           // SIGNIFICANCE CHECK:
           // Filter out symmetric weak ripples (Center) but keep asymmetric deep wells (Node 4)
           bool is_significant = (drop + rise > sum_limit) || (std::max(drop, rise) > strong_limit);

           if (is_significant) {
             // Confirm Node
             node_x.push_back(local_min_x);
             node_y.push_back(local_min);

             state = 1;
             local_max = val;
           } else {
             // Not significant yet.
             // CRITICAL FIX: Do NOT reset state just because val > local_max.
             // Asymmetric nodes (Small Drop, Huge Rise) require us to keep climbing
             // past the "entry height" until the Rise is large enough to confirm Significance.

             // However, if the Drop was invalid (tiny noise), we should reset.
             // But we only entered State 0 if Drop > Thresh. So Drop is valid.
             // So we just wait.
           }
         }
       }
     }
   }

   return DataFrame::create(
     _["x"] = wrap(node_x),
     _["y"] = wrap(node_y)
   );
 }
