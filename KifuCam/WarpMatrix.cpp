//
//  Warpcv::Matrix.cpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-03-15.
//  Copyright © 2018 AHN. All rights reserved.
//

// Perspective transform an image by giving
// three rotational angles, scale, and field of view.
// From
// https://stackoverflow.com/questions/17087446/how-to-calculate-perspective-transform-for-opencv-from-rotation-angles


#include "WarpMatrix.hpp"
#include <math.h>

static double deg2Rad(double deg){return deg*(M_PI/180);}


// Find matrix M such that a square gets viewed from angle phi.
// The bottom line of the square goes through the screen center.
// phi between pi/2 and pi.
// phi == pi => extremely distorted fron view
// phi == pi / 2 => the camera was vertically on top of the board, do nothing
//--------------------------------------------------------------
void easyWarp( cv::Size sz, double phi, cv::Mat &M)
{
    phi = deg2Rad( phi);
    Point2f center( sz.width / 2.0, sz.height / 2.0);
    // Distance of eye from image center
    double a = 1.0 * sz.width;
    double s = 1.0; // side of orig square
    // Undistoreted orig square
    Point2f bl_sq( center.x - s/2, center.y);
    Point2f br_sq( center.x + s/2, center.y);
    Point2f tl_sq( center.x - s/2, center.y - s);
    Point2f tr_sq( center.x + s/2, center.y - s);
    // Distorted by angle phi
    Point2f bl_dist( center.x - s/2, center.y);
    Point2f br_dist( center.x + s/2, center.y);
    double l2r = a / (s * (sqrt( a*a + s*s - 2*a*s*cos(phi)))); // distorted distance left to right
    double b2t = s * sin( phi); // distorted bottom to top
    Point2f tl_dist( center.x - l2r/2, center.y - b2t);
    Point2f tr_dist( center.x + l2r/2, center.y - b2t);
    // Get transform fom distorted to normal
    std::vector<Point2f> src = { tl_dist, tr_dist, br_dist, bl_dist };
    std::vector<Point2f> dst = { tl_sq, tr_sq, br_sq, bl_sq };
    M = getPerspectiveTransform( src, dst);
} // easyWarp()


// Compute the perspective transform matrix
//------------------------------------------
void warpMatrix(cv::Size sz,
                double theta,
                double phi,
                double gamma,
                double scale,
                double fovy,
                cv::Mat &M,
                std::vector<Point2f> *corners)
{
    double st = sin( deg2Rad(theta));
    double ct = cos( deg2Rad(theta));
    double sp = sin( deg2Rad(phi));
    double cp = cos( deg2Rad(phi));
    double sg = sin( deg2Rad(gamma));
    double cg = cos( deg2Rad(gamma));
    
    double halfFovy = fovy*0.5;
    double d = hypot( sz.width,sz.height);
    double sideLength = scale * d / cos( deg2Rad(halfFovy));
    double h = d / (2.0 *sin( deg2Rad(halfFovy)));
    double n = h - (d / 2.0);
    double f = h + (d / 2.0);
    
    cv::Mat F      = cv::Mat( 4, 4, CV_64FC1);      // Allocate 4x4 transformation matrix F
    cv::Mat Rtheta = cv::Mat::eye( 4, 4, CV_64FC1); // Allocate 4x4 rotation matrix around Z-axis by theta degrees
    cv::Mat Rphi   = cv::Mat::eye( 4, 4, CV_64FC1); // Allocate 4x4 rotation matrix around X-axis by phi degrees
    cv::Mat Rgamma = cv::Mat::eye( 4, 4, CV_64FC1); // Allocate 4x4 rotation matrix around Y-axis by gamma degrees
    
    cv::Mat T = cv::Mat::eye( 4, 4, CV_64FC1);    // Allocate 4x4 translation matrix along Z-axis by -h units
    cv::Mat P = cv::Mat::zeros( 4, 4, CV_64FC1);  // Allocate 4x4 projection matrix
    
    // Rtheta
    Rtheta.at<double>(0,0) = Rtheta.at<double>(1,1) = ct;
    Rtheta.at<double>(0,1) = -st;
    Rtheta.at<double>(1,0) = st;
    // Rphi
    Rphi.at<double>(1,1) = Rphi.at<double>(2,2) = cp;
    Rphi.at<double>(1,2) = -sp;
    Rphi.at<double>(2,1) = sp;
    // Rgamma
    Rgamma.at<double>(0,0) = Rgamma.at<double>(2,2) = cg;
    Rgamma.at<double>(0,2) = -sg;
    Rgamma.at<double>(2,0) = sg;
    
    // T
    T.at<double>(2,3) = -h;
    // P
    P.at<double>(0,0) = P.at<double>(1,1) = 1.0 / tan( deg2Rad(halfFovy));
    P.at<double>(2,2) = -(f+n) / (f-n);
    P.at<double>(2,3) = -(2.0*f*n) / (f-n);
    P.at<double>(3,2) = -1.0;
    // Compose transformations
    //F = P * T * Rphi * Rtheta * Rgamma;  // cv::Matrix-multiply to produce master matrix
    F = P * T * Rphi * Rtheta * Rgamma;  // cv::Matrix-multiply to produce master matrix
    //F = T * Rphi;  // cv::Matrix-multiply to produce master matrix

    // Transform 4x4 points
    double ptsIn [4*3];
    double ptsOut[4*3];
    double halfW = sz.width/2;
    double halfH = sz.height/2;
    
    ptsIn[0]  = -halfW;
    ptsIn[1]  = halfH;
    ptsIn[3]  = halfW;
    ptsIn[4]  = halfH;
    ptsIn[6]  = halfW;
    ptsIn[7]  = -halfH;
    ptsIn[9]  = -halfW;
    ptsIn[10] = -halfH;
    ptsIn[2]  = ptsIn[5] = ptsIn[8] = ptsIn[11] = 0; // Set Z component to zero for all 4 components
    
    cv::Mat ptsInMat(  1, 4, CV_64FC3, ptsIn);
    cv::Mat ptsOutMat( 1, 4, CV_64FC3, ptsOut);
    perspectiveTransform( ptsInMat, ptsOutMat, F); // Transform points

    // Get 3x3 transform and warp image
    Point2f ptsInPt2f[4];
    Point2f ptsOutPt2f[4];
    
    for (int i=0; i<4; i++) {
        Point2f ptIn(  ptsIn [i*3+0], ptsIn [i*3+1]);
        Point2f ptOut( ptsOut[i*3+0], ptsOut[i*3+1]);
        ptsInPt2f[i]  = ptIn+Point2f(halfW,halfH); // original corners
        ptsOutPt2f[i] = (ptOut+Point2f(1,1))*(sideLength*0.5); // corners after transform
    }

    M = getPerspectiveTransform( ptsInPt2f, ptsOutPt2f);
    
    if (corners) {
        corners->clear();
        corners->push_back( ptsOutPt2f[0]);
        corners->push_back( ptsOutPt2f[1]);
        corners->push_back( ptsOutPt2f[2]);
        corners->push_back( ptsOutPt2f[3]);
    }
} // warpcv::Matrix()

// Transform an image
//----------------------------------------------
void warpImage(const cv::Mat &src,
               double    theta,
               double    phi,
               double    gamma,
               double    scale,
               double    fovy,
               cv::Mat&      dst,
               cv::Mat&      M,
               std::vector<Point2f> &corners)
{
    double halfFovy = fovy*0.5;
    double d = hypot (src.cols, src.rows);
    double sideLength = scale*d / cos( deg2Rad(halfFovy));
    
    warpMatrix( src.size(), theta, phi, gamma, scale, fovy, M, &corners); // Compute warp matrix
    cv::Rect bounding = cv::boundingRect( corners);
    warpPerspective( src, dst, M, cv::Size(sideLength,sideLength)); // Do actual image warp
    dst = dst(bounding);

} // warpImage()

////---------------------
//int main(void)
//{
//    int c = 0;
//    cv::Mat m, disp, warp;
//    vector<Point2f> corners;
//    VideoCapture cap(0);
//
//    while(c != 033 && cap.isOpened()){
//        cap >> m;
//        warpImage(m, 5, 50, 0, 1, 30, disp, warp, corners);
//        imshow("Disp", disp);
//        c = waitKey(1);
//    }
//}


