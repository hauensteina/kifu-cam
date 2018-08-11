//
//  BlobFinder.cpp
//  KifuCam
//
// The MIT License (MIT)
//
// Copyright (c) 2018 Andreas Hauenstein <hauensteina@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

// Find board intersections and stones in an image

#include "Globals.h"
#include "BlobFinder.hpp"

extern cv::Mat mat_dbg;

cv::Mat BlobFinder::m_matchRes;

// Find empty intersections in a thresholded, dilated image
//------------------------------------------------------------------------------
void BlobFinder::find_empty_places( const cv::Mat &threshed, Points &result)
{
    // Define the templates
    const int tsz = 15;
    uint8_t cross[tsz*tsz] = {
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
        0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,
    };
    cv::Mat mcross  = 255 * cv::Mat(tsz, tsz, CV_8UC1, cross);
    
    // Match
    double thresh = 75; //90;
    matchTemplate( threshed, mcross, result, thresh);
} // find_empty_places()

// Find empty intersections after dewarp
//-----------------------------------------------------------------------------------
void BlobFinder::find_empty_places_perp( const cv::Mat &threshed, Points &result)
{
    // Define the templates
    const int tsz = 21;
    uint8_t cross[tsz*tsz] = {
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,
    };
    cv::Mat mcross  = 255 * cv::Mat(tsz, tsz, CV_8UC1, cross);
    
    // Match
    double thresh = 60; //75; 
    matchTemplate( threshed, mcross, result, thresh);
} // find_empty_places_perp()

// Find stones in a grayscale image
//----------------------------------------------------------------
void BlobFinder::find_stones( const cv::Mat &img, Points &result)
{
    cv::Mat mtmp;
    // Find circles
    std::vector<cv::Vec3f> circles;
    //cv::GaussianBlur( img, mtmp, cv::Size(5, 5), 2, 2 );
    cv::HoughCircles( img, circles, CV_HOUGH_GRADIENT,
                     1, // acumulator res == image res; Larger means less acc res
                     img.rows/30, // minimum distance between circles
                     260, // upper canny thresh; half of this is the lower canny
                     12, // less means more circles. The higher ones come first in the result
                     3,   // min radius
                     25 ); // max radius
    if (!circles.size()) return;
    
    // Keep the ones where radius close to avg radius
    std::vector<double> rads;
    ISLOOP (circles){ rads.push_back( circles[i][2]); }
    double avg_r = vec_median( rads);
    
    std::vector<cv::Vec3f> good_circles;
    //const double TOL_LO = 2.0;
    const double TOL_HI = 0.5;
    ISLOOP (circles)
    {
        cv::Vec3f c = circles[i];
        if ( c[2] > avg_r && (c[2] - avg_r) / avg_r < TOL_HI) {
            good_circles.push_back( circles[i]);
        }
        else if ( c[2] <= avg_r) {
            good_circles.push_back( circles[i]);
        }
    }
    ISLOOP (good_circles) { result.push_back( cv::Point( circles[i][0], circles[i][1]) ); }
} // find_stones()

// Template maching for empty intersections
//--------------------------------------------------------------------------------------------------------
void BlobFinder::matchTemplate( const cv::Mat &img, const cv::Mat &templ, Points &result, double thresh)
{
    //cv::Mat matchRes;
    cv::Mat mtmp;
    int tsz = templ.rows;
    cv::copyMakeBorder( img, mtmp, tsz/2, tsz/2, tsz/2, tsz/2, cv::BORDER_REPLICATE, cv::Scalar(0));
    cv::matchTemplate( mtmp, templ, m_matchRes, CV_TM_SQDIFF);
    cv::normalize( m_matchRes, m_matchRes, 0 , 255, CV_MINMAX, CV_8UC1);
    cv::adaptiveThreshold( m_matchRes, mtmp, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV,
                          11,  // neighborhood_size
                          thresh); // threshold; less is more
    
    //mat_dbg = mtmp.clone();
    // Find the blobs. They are the empty places.
    cv::SimpleBlobDetector::Params params;
    params.filterByColor = true;
    params.blobColor = 255;
    params.minDistBetweenBlobs = 2;
    params.filterByConvexity = false;
    params.filterByInertia = false;
    params.filterByCircularity = false;
    params.minCircularity = 0.0;
    params.maxCircularity = 100;
    params.minArea = 2;
    params.maxArea = 100;
    cv::Ptr<cv::SimpleBlobDetector> d = cv::SimpleBlobDetector::create(params);
    std::vector<cv::KeyPoint> keypoints;
    d->detect( mtmp, keypoints);
    //result = Points();
    ILOOP (keypoints.size()) { result.push_back(keypoints[i].pt); }
} // matchTemplate()

// Remove outliers. A good point has many with similar dist from center.
//-----------------------------------------------------------------------
Points BlobFinder::clean(  Points &pts)
{
    Points res;
    do {
        if (!SZ(pts)) break;
        // Find center
        int med_x = median_x( pts);
        int med_y = median_y( pts);
        // Sort by dist from center. Maxnorm, not euklidean.
        std::sort( pts.begin(), pts.end(),
                  [med_x, med_y] (cv::Point p1, cv::Point p2) {
                      int d1 = MAX( fabs( p1.x - med_x), fabs( p1.y - med_y));
                      int d2 = MAX( fabs( p2.x - med_x), fabs( p2.y - med_y));
                      return d1 < d2;
                  });
        const int RAD = 4;
        const int MAXDIST = 10;
        const int THRESH = RAD;
        ISLOOP (pts) {
            cv::Point p = pts[i];
            int d = MAX( fabs( p.x - med_x), fabs( p.y - med_y));
            int count = 0;
            for (int j = i-RAD; j <= i+RAD; j++) {
                if (j >= 0 && j < SZ(pts)) {
                    cv::Point pj = pts[j];
                    int dj = MAX( fabs( pj.x - med_x), fabs( pj.y - med_y));
                    if (fabs( dj - d) < MAXDIST) count++;
                }
            }
            if (count >= THRESH) {
                res.push_back( p);
            }
        } // ISLOOP( pts)
    } while(0);
    return res;
} // clean()















































