//
//  BlobFinder.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-11-17.
//  Copyright © 2017 AHN. All rights reserved.
//

// Find board intersections and stones in an image

#ifndef BlobFinder_hpp
#define BlobFinder_hpp

#include <iostream>
#include "Common.hpp"
#include "Ocv.hpp"

class BlobFinder
//=================
{
public:
    // Find empty intersections in a grayscale image
    static void find_empty_places( const cv::Mat &img, Points &result, int athresh=8);
    // Find stones in a grayscale image
    static void find_stones( const cv::Mat &img, Points &result);
    // Clean outliers
    static Points clean(  Points &pts);
    
    // Data
    static cv::Mat m_matchRes;
private:
    static void matchTemplate( const cv::Mat &img, const cv::Mat &templ, Points &result, double thresh);
}; // class BlobFinder

#endif /* BlobFinder_hpp */
