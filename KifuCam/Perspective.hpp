//
//  WarpMatrix.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-03-15.
//  Copyright © 2018 AHN. All rights reserved.
//

// Perspective transform helpers

#ifndef Perspective_hpp
#define Perspective_hpp

// Don't change the order of these two,
// and don't move them down
#import "Ocv.hpp"
#include <stdio.h>

// Find matrix M such that we look down with pitch phi.
// The bottom line of the square goes through the screen center.
// phi between pi/2 and pi.
// phi == pi => No pitch. Extremely distorted front view.
// phi == pi / 2 => Looking straight down.
//---------------------------------------------------------------------------------
inline void perspective_warp( cv::Size sz, double phi, cv::Mat &M, cv::Mat &invM)
{
    phi *= PI/ 180;
    Point2f center( sz.width / 2.0, sz.height / 2.0);
    // Distance of eye from image center
    double a = 1.0 * sz.width;
    double s = 1.0; // side of orig square
    // Undistoreted orig square
    // Move the square down to avoid projecting the top edge off screen
    double d = (sz.height / 4.0) * cos(phi) * -1;
    Point2f bl_sq( center.x - s/2, center.y + d);
    Point2f br_sq( center.x + s/2, center.y + d);
    Point2f tl_sq( center.x - s/2, center.y - s + d);
    Point2f tr_sq( center.x + s/2, center.y - s + d);
    // Distorted by angle phi
    Point2f bl_dist( center.x - s/2, center.y);
    Point2f br_dist( center.x + s/2, center.y);
    double l2r = a / (s * (sqrt( a*a + s*s - 2*a*s*cos(phi)))); // distorted distance left to right
    double b2t = s * sin( phi); // distorted bottom to top
    Point2f tl_dist( center.x - l2r/2, center.y - b2t);
    Point2f tr_dist( center.x + l2r/2, center.y - b2t);
    
    // Get transform from distorted to normal
    std::vector<Point2f> src = { tl_dist, tr_dist, br_dist, bl_dist };
    std::vector<Point2f> dst = { tl_sq, tr_sq, br_sq, bl_sq };
    M = getPerspectiveTransform( src, dst);
    invM = getPerspectiveTransform( dst, src);
} // perspective_warp()

// Run a matrix over a bunch of polar lines.
//--------------------------------------------------------------------------------------
inline void warp_plines( const std::vector<cv::Vec2f> &plines_in, const cv::Mat &M,
                        std::vector<cv::Vec2f> &plines_out)
{
    if (!SZ(plines_in)) {
        plines_out.clear();
        return;
    }
    Points2f p1s, p2s;
    ISLOOP( plines_in) {
        cv::Vec4f seg = polar2segment( plines_in[i]);
        p1s.push_back( Point2f( seg[0],seg[1]));
        p2s.push_back( Point2f( seg[2],seg[3]));
    }
    
    std::vector<cv::Vec2f>  res;
    Points2f p1srot, p2srot;
    if (M.rows == 3) { // persp trans
        cv::perspectiveTransform( p1s, p1srot, M);
        cv::perspectiveTransform( p2s, p2srot, M);
    }
    else { // affine trans
        cv::transform( p1s, p1srot, M);
        cv::transform( p2s, p2srot, M);
    }
    ISLOOP( p1srot) {
        res.push_back( segment2polar( cv::Vec4f( p1srot[i].x, p1srot[i].y,  p2srot[i].x,  p2srot[i].y)));
    }
    plines_out = res;
} // warp_plines()

// Run a matrix over a bunch of points
//---------------------------------------------------------------------
inline void warp_points( const Points &points_in, const cv::Mat &M,
                         Points &points_out)
{
    if (!SZ(points_in)) {
        points_out.clear();
        return;
    }
    Points2f pf = points2float( points_in);
    Points2f res;
    if (M.rows == 3) { // persp trans
        cv::perspectiveTransform( pf, res, M);
    }
    else { // affine trans
        cv::transform( pf, res, M);
    }
    points2int( res, points_out);
} // warp_points()

// Find a transform that makes the lines parallel
// Returns a number indicationg how parallel the best solution was.
// Small numbers are more paralleinl.
//----------------------------------------------------------------------------------------
inline float parallel_projection( cv::Size sz, const std::vector<cv::Vec2f> &plines_,
                                 float &minphi, cv::Mat &minM, cv::Mat &invM)
{
    auto paralellity = [plines_]( const cv::Mat &M) {
        std::vector<cv::Vec2f> plines;
        warp_plines( plines_, M, plines);
        auto thetas = vec_extract( plines, [](cv::Vec2f line) { return line[1]; } );
        double q1 = vec_q1( thetas);
        double q3 = vec_q3( thetas);
        double dq = q3 - q1;
        return dq;
    }; // paralellity()
    double phi;
    float minpary = 1E9;
    minphi = -1;
    cv::Mat M, Minv;
    for (phi = 70; phi < 130; phi += 0.25) {
        perspective_warp( sz, phi, M, Minv);
        float pary = paralellity( M);
        if (pary < minpary) {
            minpary = pary;
            minphi = phi;
            minM = M;
            invM = Minv;
        }
    } // for
    return minpary;
} // parallel_projection()

// Find a rotation that makes horizontal lines truly horizontal
// Returns a number indicationg how straight the best solution was.
// Smaller numbers are straighter.
//-----------------------------------------------------------------------------------------
inline float straight_horiz_rotation( cv::Size sz, const std::vector<cv::Vec2f> &plines_,
                                     float &minphi, cv::Mat &minM, cv::Mat &invM)
{
    Point2f center( sz.width/2.0, sz.height/2.0);
    auto straightness = [plines_]( const cv::Mat &M) {
        std::vector<cv::Vec2f> plines;
        warp_plines( plines_, M, plines);
        auto thetas = vec_extract( plines, [](cv::Vec2f line) { return line[1]; } );
        double med = vec_median( thetas);
        return fabs(PI/2 - med);
    }; // straightness()
    double phi;
    float minstr = 1E9;
    minphi = -1;
    cv::Mat M;
    for (phi = -20; phi <= 20; phi += 0.25) {
        M = cv::getRotationMatrix2D( center, phi, 1.0);
        float strness = straightness( M);
        if (strness < minstr ) {
            minstr = strness;
            minphi = phi;
            minM = M;
        }
    } // for
    invM = cv::getRotationMatrix2D( center, -minphi, 1.0);
    return minstr;
} // straight_horiz_rotation()

// Find a rotation that makes vertical lines truly vertical.
// Returns a number indicationg how straight the best solution was.
// Smaller numbers are straighter.
//-----------------------------------------------------------------------------------------
inline float straight_vert_rotation( cv::Size sz, const std::vector<cv::Vec2f> &plines_,
                                    float &minphi, cv::Mat &minM, cv::Mat &invM)
{
    Point2f center( sz.width/2.0, sz.height/2.0);
    auto straightness = [plines_]( const cv::Mat &M) {
        std::vector<cv::Vec2f> plines;
        warp_plines( plines_, M, plines);
        auto thetas = vec_extract( plines, [](cv::Vec2f line) { return line[1]; } );
        double med = vec_median( thetas);
        return fmin( fabs(med), fabs(PI-med));
    }; // straightness()
    double phi;
    float minstr = 1E9;
    minphi = -1;
    cv::Mat M;
    for (phi = -20; phi <= 20; phi += 0.25) {
        M = cv::getRotationMatrix2D( center, phi, 1.0);
        float strness = straightness( M);
        if (strness < minstr ) {
            minstr = strness;
            minphi = phi;
            minM = M;
        }
    } // for
    invM = cv::getRotationMatrix2D( center, -minphi, 1.0);
    return minstr;
} // straight_vert_rotation()

// Get affine transform to scale image
//-----------------------------------------------
inline cv::Mat scale_transform( double scale)
{
    cv::Mat res;
    cv::Point2f src[3];
    src[0] = Point2f(0,0);
    src[1] = Point2f(0,1);
    src[2] = Point2f(1,1);

    cv::Point2f target[3];
    target[0] = Point2f(0,0);
    target[1] = Point2f(0,scale);
    target[2] = Point2f(scale,scale);

    res = cv::getAffineTransform( src, target);
    return res;
} // scale_transform()

// Undo perspective correction on several points so we can draw them on
// the original image.
//---------------------------------------------------------------------------------------------------
inline void unwarp_points( cv::Mat &invProj, cv::Mat &invRot, cv::Mat &invDist, const Points2f &pts_in,
                   Points2f &pts_out)
{
    pts_out.clear();
    ISLOOP( pts_in) {
        Point2f p = pts_in[i];
        cv::transform( pts_in, pts_out, invDist);
        cv::perspectiveTransform( pts_out, pts_out, invProj);
        cv::transform( pts_out, pts_out, invRot);
    }
} // unwarp_points()

// Scale image to make distance of verticals == CROPSIZE. Return the transform and its inverse.
//-----------------------------------------------------------------------------------------------
inline void fix_vertical_distance( std::vector<cv::Vec2f> &lines, cv::Mat &small_img,
                                  float &scale, cv::Mat &Md, cv::Mat &invMd)

{
    const int mid_y = 0.5 * small_img.rows;

    std::sort( lines.begin(), lines.end(),
              [mid_y](cv::Vec2f a, cv::Vec2f b) {
                  return x_from_y( mid_y, a) < x_from_y( mid_y, b);
              });
    std::vector<double> mid_rhos = vec_extract( lines,
                                               [mid_y](cv::Vec2f a) { return x_from_y( mid_y, a); });

    auto d_mid_rhos = vec_delta( mid_rhos);
    vec_filter( d_mid_rhos, [](double d){ return d > 8 && d < 20;});
    if (SZ(d_mid_rhos) < 2) {
        Md = scale_transform(1.0);
        invMd = scale_transform(1.0);
        scale = 1.0;
        return;
    }

    double d_mid_rho = vec_median( d_mid_rhos);
    scale = CROPSIZE / d_mid_rho; 
    Md = scale_transform( scale);
    invMd = scale_transform( 1.0 / scale);
    const cv::Size sz( small_img.cols * scale, small_img.rows * scale);
    cv::warpAffine( small_img, small_img, Md, sz);
} // fix_vertical_distance()

// Find a good perspective transform by wriggling the forth point
// of a distored rectangle.
//-------------------------------------------------------------------------------
inline bool wiggle_transform( std::vector<cv::Vec2f> hlines,
                             std::vector<cv::Vec2f> vlines,
                             double width, double height,
                             cv::Mat &minM, cv::Mat &invM)
{
    Point2f tl,tr,br,bl;
    Point2f ttl,ttr,tbr,tbl;
    
    // Find a good vertical line
    const int bot_y = 0.8 * height;
    std::sort( vlines.begin(), vlines.end(),
              [bot_y](cv::Vec2f a, cv::Vec2f b) {
                  return x_from_y( bot_y, a) < x_from_y( bot_y, b);
              });
    int good_vidx = good_center_line( vlines);
    if (good_vidx < 0) { return false; }
    cv::Vec2f med_vline = vlines[good_vidx];
    
    // Find a good horizontal line
    const int right_x = 0.8 * width;
    std::sort( hlines.begin(), hlines.end(),
              [right_x](cv::Vec2f a, cv::Vec2f b) {
                  return y_from_x( right_x, a) < y_from_x( right_x, b);
              });
    int good_hidx = good_center_line( hlines);
    if (good_hidx < 0) { return false; }
    cv::Vec2f med_hline = hlines[good_hidx];
    
    // Intersection is the top left corner
    tl = intersection( med_vline, med_hline);
    
    // Target rectangle
    const double delta = 20.0;
    ttl = tl;
    ttr = Point2f( ttl.x + delta, ttl.y);
    tbr = Point2f( ttl.x + delta, ttl.y + delta);
    tbl = Point2f( ttl.x, ttl.y + delta);
    
    // Distorted source 'rectangle', top right and bot left
    tr = Point2f( ttl.x + delta, y_from_x( ttl.x + delta, med_hline));
    bl = Point2f( x_from_y( ttl.y + delta, med_vline), ttl.y + delta);
    
    // Guess the bottom right point
    auto hline = med_hline;
    hline[0] += delta;
    auto vline = med_vline;
    vline[0] += delta;
    auto br_guess = intersection( hline, vline);
    
    // Minmize this cost
    auto parallelity = [vlines]( const cv::Mat &M) {
        std::vector<cv::Vec2f> plines;
        warp_plines( vlines, M, plines);
        auto thetas = vec_extract( plines, [](cv::Vec2f line) { return line[1]; } );
        double q1 = vec_q1( thetas);
        double q3 = vec_q3( thetas);
        double dq = q3 - q1;
        return dq;
    }; // paralellity()
    
    // Wiggle bottom right source corner until cost minimized
    const int r = 10;
    float minpary = 1E9;
    cv::Mat M, Minv;
    for (auto x = br_guess.x - r; x <= br_guess.x + r; x += 1.0) {
        for (auto y = br_guess.y - r; y <= br_guess.y + r; y += 1.0) {
            auto br = Point2f( x, y);
            cv::Mat M;
            std::vector<Point2f> source = {tl, tr, br, bl};
            std::vector<Point2f> target = {ttl, ttr, tbr, tbl};
            cv::perspectiveTransform( source, target, M);
            float pary = parallelity( M);
            if (pary < minpary) {
                minpary = pary;
                minM = M;
                cv::perspectiveTransform( target, source, Minv);
            }
        } // for y
    } // for x
    return true;
} // wiggle_transform()

#endif /* Perspective_hpp */
