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

// Find a transform that makes the lines parallel
// Returns a number indicationg how parallel the best solution was.
// Small numbers are more parallel.
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
    for (phi = 90; phi < 130; phi += 1) {
        perspective_warp( sz, phi, M, Minv);
        float pary = paralellity( M);
        if (pary < minpary) {
            minpary = pary;
            minphi = phi;
            minM = M;
            invM = Minv;
        }
    } // for
    //perspective_warp( sz, -minphi, invM);
    return minpary;
} // parallel_projection()

// Find a rotation that makes horizontal lines truly horizontal
// Returns a number indicationg how straight the best solution was.
// Smaller numbers are straighter.
//--------------------------------------------------------------------------------
inline float straight_rotation( cv::Size sz, const std::vector<cv::Vec2f> &plines_,
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
    for (phi = -20; phi <= 20; phi += 1) {
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
} // straight_rotation()

// Undo perspective correction on several points so we can draw them on
// the original image.
//------------------------------------------------------------------------------------
inline void unwarp_points( cv::Mat &invProj, cv::Mat &invRot, const Points2f &pts_in,
                   Points2f &pts_out)
{
    pts_out.clear();
    ISLOOP( pts_in) {
        Point2f p = pts_in[i];
        cv::perspectiveTransform( pts_in, pts_out, invProj);
        cv::transform( pts_out, pts_out, invRot);
    }
} // unwarp_points()



#endif /* Perspective_hpp */
