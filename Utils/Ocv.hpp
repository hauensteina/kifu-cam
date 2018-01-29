//
//  Ocv.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-11-15.
//  Copyright © 2017 AHN. All rights reserved.
//

//=======================
// OpenCV helper funcs
//=======================

#ifndef Ocv_hpp
#define Ocv_hpp

#ifdef __cplusplus

#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>

#include "Common.hpp"

typedef cv::Point2f Point2f;
typedef std::vector<std::vector<cv::Point> > Contours;
typedef std::vector<cv::Point> Contour;
typedef std::vector<cv::Point> Points;
typedef cv::Point Line[2];
typedef std::vector<cv::Point2f> Points2f;
typedef struct { Point2f p; double feat; } PFeat;
typedef cv::Point3_<uint8_t> Pixel;

extern cv::RNG rng;


// Point
//=========
// Get average x of a bunch of points
double avg_x (const Points &p);
// Get average y of a bunch of points
double avg_y (const Points &p);
// Get average x of a bunch of points
double median_x (const Points &p);
// Get average y of a bunch of points
double median_y (const Points &p);
// Return unit vector of p
cv::Point2f unit_vector( cv::Point p);
// Sort points by x and remove dups
void rem_dups_x( Points &pts, double tol);


// Matrix
//==========
// Get the type string of a matrix
std::string mat_typestr( const cv::Mat &m);
// Calculate the median value of a single channel
int channel_median( cv::Mat channel );
// q1 value of a single channel
int channel_q1( cv::Mat channel );
// Elementwise L2 distance between two single channel mats.
double mat_dist( const cv::Mat &m1, const cv::Mat &m2);
// Store mat of uint8_t in vec of double
inline std::vector<double> mat2vec( cv::Mat &m)
{
    std::vector<double> res(m.rows*m.cols);
    int i=0;
    m.forEach<uint8_t>( [&i,&res](uint8_t &v, const int *p) { res[i++]=v; } );
    return res;
}
// Sum two uint8_t mats, scale back to 255
inline cv::Mat mat_sumscale( const cv::Mat &m1, const cv::Mat &m2, double w1 = 1.0, double w2 = 1.0)
{
    cv::Mat mf1, mf2;
    m1.convertTo( mf1, CV_64FC1, w1);
    m2.convertTo( mf2, CV_64FC1, w2);
    mf1 += mf2;
    double mmin, mmax;
    cv::minMaxLoc( mf1, &mmin, &mmax);
    double scale = 255.0 / mmax;
    cv::Mat res;
    mf1.convertTo( res, CV_8UC1, scale);
    return res;
}


// Contour
//=========
// Enclose a contour with an n edge polygon
Points approx_poly( Points cont, int n);
// Draw contour in random colors
void draw_contours( const Contours cont, cv::Mat &dst);

// Line
//=======
double angle_between_lines( cv::Point pa, cv::Point pe,
                           cv::Point qa, cv::Point qe);
// Average line segs by fitting a line thu the endpoints
cv::Vec4f avg_lines( const std::vector<cv::Vec4f> &lines );
// Average polar lines after setting rho to zero and conv to seg
cv::Vec4f avg_slope_line( const std::vector<cv::Vec2f> &plines );
// Distance between point and line segment
double dist_point_line( cv::Point p, const cv::Vec4f &line);
// Distance between point and polar line
double dist_point_line( cv::Point p, const cv::Vec2f &pline);
// Intersection of two lines defined by point pairs
Point2f intersection( cv::Vec4f line1, cv::Vec4f line2);
// Intersection of polar lines (rho, theta)
Point2f intersection( cv::Vec2f line1, cv::Vec2f line2);
// Length of a line segment
double line_len( cv::Point p, cv::Point q);
// Median pixel val on line segment
int median_on_segment( const cv::Mat &gray, cv::Point p1, cv::Point p2);
int median_on_segment( const cv::Mat &gray, cv::Vec4f seg);
// Sum of values on line segment
double sum_on_segment( const cv::Mat &gray, cv::Point p1, cv::Point p2);
// Median polar line bt theta
cv::Vec4f median_slope_line( const std::vector<cv::Vec2f> &plines );
// Get a line segment representation of a polar line (rho, theta)
cv::Vec4f polar2segment( const cv::Vec2f &pline);
// Line segment to polar, with positive rho
cv::Vec2f segment2polar( const cv::Vec4f &line);
// Stretch a line by factor, on both ends
Points stretch_line(Points line, double factor );
// Stretch a line by factor, on both ends
cv::Vec4f stretch_line(cv::Vec4f line, double factor );
// x given y for polar line
double x_from_y( double y, cv::Vec2f pline);
// y given x for polar line
double y_from_x( double x, cv::Vec2f pline);

// Rectangle
//=============
// Check if a rectangle makes sense
bool check_rect( const cv::Rect &r, int rows, int cols );
// Make a rect extending dx, dy both sides of center.
cv::Rect make_hood( Point2f center, int dx, int dy);

// Quad
//========
// Stretch quadrangle by factor
Points2f stretch_quad( Points quad, double factor);
// Zoom into a region with four corners
cv::Mat zoom_quad( const cv::Mat &img, cv::Mat &warped, Points2f pts);
// Return whole image as a quad
Points whole_img_quad( const cv::Mat &img);
// Find smallest quad among a few
Points smallest_quad( std::vector<Points> quads);
// Average the corners of quads
Points avg_quad( std::vector<Points> quads);
// Median the corners of quads
Points2f med_quad( std::vector<Points2f> quads);
// Sum of distances of corners, relative to shortest side.
double diff_quads( const Points2f &q1, const Points2f &q2);

// Image
//========
// Rotate image by angle. Does not adjust image size.
void rot_img( const cv::Mat &img, double angle, cv::Mat &dst);
// Resize image such that min(width,height) = sz
void resize(const cv::Mat &src, cv::Mat &dst, int sz);
// Automatic edge detection without parameters (from PyImageSearch)
void auto_canny( const cv::Mat &src, cv::Mat &dst, double sigma=0.33);
// Dilate then erode for some iterations
void morph_closing( cv::Mat &m, cv::Size sz, int iterations, int type = cv::MORPH_RECT );
// Get a center crop of an image
int get_center_crop( const cv::Mat &img, cv::Mat &dst, double frac=4);
// Get hue
void get_hue_from_rgb( const cv::Mat &img, cv::Mat &dst);
// Average over a center crop of img
double center_avg( const cv::Mat &img, double frac=4);
// Normalize mean and variance, per channel
void normalize_image( const cv::Mat &src, cv::Mat &dst);
// Normalize mean and variance for one uint channel, scale back to 0..255
void normalize_plane( const cv::Mat &src, cv::Mat &dst);
// Normalize nxn submatrices, with mean and var from larger submatrix.
void normalize_plane_local( const cv::Mat &src, cv::Mat &dst, int radius);
// Get main horizontal direction of a grid of points (in rad)
double direction( const cv::Mat &img, const Points &ps);
// Inverse threshold at median
void inv_thresh_median( const cv::Mat &gray, cv::Mat &dst);
// Inverse threshold at q1
void inv_thresh_q1( const cv::Mat &gray, cv::Mat &dst);
// Inverse threshold at average
void inv_thresh_avg( const cv::Mat &gray, cv::Mat &dst);

// Drawing
//==========
// Convert 0-255 to Penny Lane colormap
cv::Scalar cm_penny_lane( int c);
// Draw a point on an image
void draw_point( cv::Point p, cv::Mat &img, int r=1, cv::Scalar col = cv::Scalar(255,0,0));
void draw_point( cv::Point2f p, cv::Mat &img, int r, cv::Scalar col);
// Draw a square with center p
void draw_square( Point2f pf, int r, cv::Mat &dst, cv::Scalar col);
// Draw a line segment
void draw_line( const cv::Vec4f &line, cv::Mat &dst, cv::Scalar col = cv::Scalar(255,0,0));
// Draw several line segments
void draw_lines( const std::vector<cv::Vec4f> &lines, cv::Mat &dst,
                cv::Scalar col = cv::Scalar(255,0,0));
// Draw a polar line (rho, theta)
void draw_polar_line( cv::Vec2f pline, cv::Mat &dst,
                     cv::Scalar col = cv::Scalar(255,0,0));
// Draw several polar lines (rho, theta)
void draw_polar_lines( std::vector<cv::Vec2f> plines, cv::Mat &dst,
                      cv::Scalar col = cv::Scalar(255,0,0));
// Get a changing color
cv::Scalar get_color( bool reset=false);

// Type Conversions
//====================
// Vector of int points to double
void points2float( const Points &pi, Points2f &pf);
Points2f points2float( const Points &pi);
// Vector of double points to int
void points2int( const Points2f &pf, Points &pi);
inline cv::Point pf2p( const Point2f p) { return cv::Point( ROUND(p.x), ROUND(p.y)) ; }
inline cv::Point p2pf( const cv::Point p) { return Point2f( p.x, p.y) ; }

// Debugging
//=============
// Print matrix type
void print_mat_type( const cv::Mat &m);
// Print uint8 matrix
void printMatU( const cv::Mat &m);
// Print double matrix
void printMatF( const cv::Mat &m);
// Print double matrix
void printMatD( const cv::Mat &m);
// Print 3 channel uint8 matrix
void printMatU3( const cv::Mat &m);


// Misc
//========
// Make a rect extending dx, dy both sides of center.
cv::Rect make_hood( Point2f center, int dx, int dy);
std::string opencvVersion();
void test_mcluster();
void test_segment2polar();

//===================
// Templates below
//===================

// Point
//=========

// Check if point on image
//-------------------------------------------------
template <typename Point_>
bool p_on_img( Point_ p, const cv::Mat &img)
{
    return p.x >= 0 && p.y >= 0 && p.x < img.cols && p.y < img.rows;
}

// Intersection of two line segments AB CD
//-----------------------------------------------------------------
template <typename Point_>
Point2f intersection( Point_ A, Point_ B, Point_ C, Point_ D)
{
    // Line AB represented as a1x + b1y = c1
    double a1 = B.y - A.y;
    double b1 = A.x - B.x;
    double c1 = a1*(A.x) + b1*(A.y);
    
    // Line CD represented as a2x + b2y = c2
    double a2 = D.y - C.y;
    double b2 = C.x - D.x;
    double c2 = a2*(C.x)+ b2*(C.y);
    
    double determinant = a1*b2 - a2*b1;
    
    if (determinant == 0) { // The lines are parallel.
        return Point_(10E9, 10E9);
    }
    else
    {
        double x = (b2*c1 - b1*c2)/determinant;
        double y = (a1*c2 - a2*c1)/determinant;
        return Point_( x, y);
    }
}

// Get center of a bunch of points
//-----------------------------------------------------------------
template <typename Points_>
cv::Point2f get_center( const Points_ ps)
{
    double avg_x = 0, avg_y = 0;
    ISLOOP (ps) {
        avg_x += ps[i].x;
        avg_y += ps[i].y;
    }
    return cv::Point2f( avg_x / ps.size(), avg_y / ps.size());
}

// Draw several points
//----------------------------------------------------------------
template <typename T>
void draw_points( T pts, cv::Mat &img, int r, cv::Scalar col)
{
    ISLOOP( pts) draw_point( pts[i], img, r, col);
}

// Contours
//=============

// Draw one contour (e.g. the board)
//------------------------------------
template <typename Points_>
void draw_contour( cv::Mat &img, const Points_ &cont,
                  cv::Scalar color = cv::Scalar(255,0,0), int thickness = 1)
{
    cv::drawContours( img, std::vector<Points_>( 1, cont), -1, color, thickness, 8);
}

// Line
//=========

// Fit a line segment through points, L2 norm
//-----------------------------------------------
template <typename Points_>
cv::Vec4f fit_line( const Points_ &p)
{
    cv::Vec4f res,tt;
    cv::fitLine( p, tt, CV_DIST_L2, 0.0, 0.01, 0.01);
    res[0] = tt[2];
    res[1] = tt[3];
    res[2] = tt[2] + tt[0];
    res[3] = tt[3] + tt[1];
    return res;
}

// Fit a polar through points, L2 norm
//---------------------------------------------
template <typename Points_>
cv::Vec2f fit_pline( const Points_ &p)
{
    cv::Vec4f line = fit_line( p);
    return segment2polar( line);
}

// Clustering
//=============

// Order four points clockwise
//----------------------------------------
template <typename POINTS>
POINTS order_points( const POINTS &points)
{
    POINTS top_bottom = points;
    std::sort( top_bottom.begin(), top_bottom.end(), [](cv::Point2f a, cv::Point2f b){ return a.y < b.y; });
    POINTS top( top_bottom.begin(), top_bottom.begin()+2 );
    POINTS bottom( top_bottom.end()-2, top_bottom.end());
    std::sort( top.begin(), top.end(), [](cv::Point2f a, cv::Point2f b){ return a.x < b.x; });
    std::sort( bottom.begin(), bottom.end(), [](cv::Point2f a, cv::Point2f b){ return b.x < a.x; });
    POINTS res = top;
    res.insert(res.end(), bottom.begin(), bottom.end());
    return res;
}

// Cluster a vector of elements by func.
// Return clusters as vec of vec.
// Assumes feature is a single double.
//---------------------------------------------------------------------
template<typename Func, typename T>
std::vector<std::vector<T> >
cluster (std::vector<T> elts, int nof_clust, Func getFeature, double &compactness, int tries=3, int iter=10, double eps=1.0)
{
    if (elts.size() < 2) return std::vector<std::vector<T> >();
    std::vector<double> features;
    std::vector<double> centers;
    ILOOP (elts.size()) { features.push_back( getFeature( elts[i])); }
    std::vector<int> labels;
    compactness = cv::kmeans( features, nof_clust, labels,
                             cv::TermCriteria( cv::TermCriteria::EPS + cv::TermCriteria::COUNT, iter, eps),
                             tries, cv::KMEANS_PP_CENTERS, centers);
    // Extract parts
    std::vector<std::vector<T> > res( nof_clust, std::vector<T>());
    ILOOP (elts.size()) {
        res[labels[i]].push_back( elts[i]);
    }
    return res;
} // cluster()

// Cluster a vector of elements by func.
// Return clusters as vec of vec.
// Assumes feature is a vec of double of ndims.
//-----------------------------------------------------------------------
template<typename Func, typename T>
std::vector<std::vector<T> >
mcluster (std::vector<T> elts, int nof_clust, int ndims, double &compactness, Func getFeatVec)
{
    if (elts.size() < 2) return std::vector<std::vector<T> >();
    std::vector<double> featVec;
    // Append all vecs into one large one
    ILOOP (elts.size()) {
        //size_t n1 = featVec.size();
        vapp( featVec, getFeatVec( elts[i]));
        //size_t n2 = featVec.size();
    }
    // Reshape into a matrix with one row per feature vector
    //cv::Mat m = cv::Mat(featVec).reshape( 0, sizeof(elts) );
    //assert (featVec.size() == 361*ndims);
    cv::Mat m = cv::Mat(featVec).reshape( 0, int(elts.size()));
    
    // Cluster
    std::vector<int> labels;
    cv::Mat centers;
    compactness = cv::kmeans( m, nof_clust, labels,
                             cv::TermCriteria( cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 100, 1.0),
                             3, cv::KMEANS_PP_CENTERS, centers);
    // Extract parts
    std::vector<std::vector<T> > res( nof_clust, std::vector<T>());
    ILOOP (elts.size()) {
        res[labels[i]].push_back( elts[i]);
    }
    return res;
} // mcluster()

#endif /* __clusplus */
#endif /* Ocv_hpp */

