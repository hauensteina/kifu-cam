//
//  BlobFinder.hpp
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
    static void find_empty_places( const cv::Mat &img, Points &result);
    // Find empty intersections after dewarp
    static void find_empty_places_perp( const cv::Mat &img, Points &result);
    // Find stones in a grayscale image
    static void find_stones( const cv::Mat &img, Points &result);
    // Find stones after dewarp
    static void find_stones_perp( const cv::Mat &img, Points &result);
    // Clean outliers
    static Points clean(  Points &pts);
    
    // Data
    static cv::Mat m_matchRes;
private:
    static void matchTemplate( const cv::Mat &img, const cv::Mat &templ, Points &result, double thresh);
}; // class BlobFinder

#endif /* BlobFinder_hpp */
