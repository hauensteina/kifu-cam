//
//  WarpMatrix.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-03-15.
//  Copyright © 2018 AHN. All rights reserved.
//

// Perspective transform an image by giving
// three rotational angles, scale, and field of view.
// From
// https://stackoverflow.com/questions/17087446/how-to-calculate-perspective-transform-for-opencv-from-rotation-angles

#ifndef WarpMatrix_hpp
#define WarpMatrix_hpp

// Don't change the order of these two,
// and don't move them down
#import "Ocv.hpp"
#include <stdio.h>

// Easy projection matrix for angle phi
void easyWarp( cv::Size sz, double phi, cv::Mat &M);

// Compute projection matrix
void warpMatrix(cv::Size sz,
                double theta,
                double phi,
                double gamma,
                double scale,
                double fovy,
                cv::Mat &M,
                std::vector<Point2f> *corners);

// Compute matrix and warp image
void warpImage(const     cv::Mat &src,
               double    theta,
               double    phi,
               double    gamma,
               double    scale,
               double    fovy,
               cv::Mat   &dst,
               cv::Mat   &M,
               std::vector<Point2f> &corners);


#endif /* WarpMatrix_hpp */
