//
//  BlackWhiteEmpty.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-11-16.
//  Copyright © 2017 AHN. All rights reserved.
//

// Classify board intersection into Black, White, Empty

#ifndef BlackWhiteEmpty_hpp
#define BlackWhiteEmpty_hpp

#include <iostream>
#include "Common.hpp"
#include "Globals.h"
#include "Helpers.hpp"
#include "Ocv.hpp"

//extern cv::Mat mat_dbg;  // debug image to viz intermediate results

class BlackWhiteEmpty
//=====================
{
private:
    std::vector<double> BWE_brightmatch;
    std::vector<double> BWE_darkmatch;
    std::vector<double> BWE_graymean;
    std::vector<double> BWE_sum_inner;
    std::vector<double> BWE_white_holes;
public:
    //----------------------------------------------------------------------------------
    inline std::vector<int> classify( const cv::Mat &pyr,
                                            const cv::Mat &gray,
                                            const Points2f &intersections,
                                            double &match_quality)
    {
        // Preprocess image
        //-------------------
        cv::Mat pyrgray;
        cv::cvtColor( pyr, pyrgray, cv::COLOR_RGB2GRAY);
        cv::Mat gray_threshed;
        thresh_dilate( gray, gray_threshed, 4);
        cv::Mat bright_places;
        cv::adaptiveThreshold( gray, bright_places, 255, CV_ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 81, -50);
        cv::Mat dark_places;
        cv::adaptiveThreshold( pyrgray, dark_places, 255, CV_ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, 51, 50);
        
        // Replace dark places with average to make white dynamic threshold work
        uint8_t mean = cv::mean( pyrgray)[0];
        cv::Mat black_places;
        cv::adaptiveThreshold( pyrgray, black_places, mean, CV_ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, 51, 50);
        cv::Mat pyr_masked = pyrgray.clone();
        // Copy over if not zero
        pyr_masked.forEach<uint8_t>( [&black_places](uint8_t &v, const int *p)
                                    {
                                        int row = p[0]; int col = p[1];
                                        if (auto p = black_places.at<uint8_t>( row,col)) {
                                            v = p;
                                        }
                                    });
        // The White stones become black holes, all else is white
        int nhood_sz =  25;
        double thresh = -32;
        cv::Mat white_holes;
        cv::adaptiveThreshold( pyr_masked, white_holes, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV,
                              nhood_sz, thresh);
        //        cv::Mat element = cv::getStructuringElement( cv::MORPH_RECT, cv::Size(2,2));
        //        cv::dilate( white_holes, white_holes, element );
        
        // Compute features
        //--------------------
        cv::Mat emptyMask3( 3, 3, CV_8UC1, cv::Scalar(0));
        cv::Mat emptyMask7( 7, 7, CV_8UC1, cv::Scalar(0));
        cv::Mat fullMask7( 7, 7, CV_8UC1, cv::Scalar(255));
        cv::Mat fullMask11( 11, 11, CV_8UC1, cv::Scalar(255));
        
        int wiggle = 1;
        match_mask_near_points( white_holes, emptyMask3, intersections, wiggle+1, BWE_white_holes);
        match_mask_near_points( gray_threshed, emptyMask7, intersections, wiggle, BWE_sum_inner);
        match_mask_near_points( bright_places, fullMask7, intersections, wiggle, BWE_brightmatch);
        match_mask_near_points( dark_places, fullMask11, intersections, wiggle+2, BWE_darkmatch);
        
        // Gray mean
        const int r = 4;
        const int yshift = 0;
        const bool dontscale = false;
        get_feature( pyrgray, intersections, r,
                    [](const cv::Mat &hood) { return cv::mean(hood)[0]; },
                    BWE_graymean, yshift, dontscale);
        
        // Classify intersections
        //----------------------------------------------
        std::vector<int> res( SZ(intersections), EEMPTY);
        ISLOOP (intersections) {
            double whiteness   = BWE_white_holes[i];
            double brightmatch = BWE_brightmatch[i];
            double darkmatch   = BWE_darkmatch[i];
            double brightness  = BWE_graymean[i];
            double white_glare = BWE_sum_inner[i];
            
            if (darkmatch < 120) {
                res[i] = BBLACK;
            }
            else {
                if (brightmatch < 100 &&  whiteness < 80) res[i] = WWHITE; // frozen
                if (brightness > 200 &&   white_glare < 15) res[i] = WWHITE;
            }
        }
        return res;
    } // classify()
    
    // Vote across several video frames. The previous TIMEBUFSZ frames get to vote.
    //---------------------------------------------------------------------------------------------------
    inline
    std::vector<int> frame_vote( const Points2f &intersections, const cv::Mat &img, const cv::Mat &gray,
                                int TIMEBUFSZ = 1)
    {
        double match_quality;
        std::vector<int> diagram = this->classify( img, gray,
                                                  intersections, match_quality);
        // Vote across time
        static std::vector<std::vector<int> > timevotes(19*19);
        assert( SZ(diagram) <= 19*19);
        ISLOOP (diagram) {
            ringpush( timevotes[i], diagram[i], TIMEBUFSZ);
        }
        ISLOOP (timevotes) {
            std::vector<int> counts( DDONTKNOW, 0); // index is bwe
            for (int bwe: timevotes[i]) { ++counts[bwe]; }
            int winner = argmax( counts);
            diagram[i] = winner;
        }
        return diagram;
    } // frame_vote()
    
    // Check if a rectangle makes sense
    //---------------------------------------------------------------------
    inline bool check_rect( const cv::Rect &r, int rows, int cols )
    {
        if (0 <= r.x && r.x < 1e6 &&
            0 <= r.width && r.width < 1e6 &&
            r.x + r.width <= cols &&
            0 <= r.y &&  r.y < 1e6 &&
            0 <= r.height &&  r.height < 1e6 &&
            r.y + r.height <= rows)
        {
            return true;
        }
        return false;
    } // check_rect()
    
    // Take neighborhoods around points and average them, resulting in a
    // template for matching.
    //--------------------------------------------------------------------------------------------
    inline void avg_hoods( const cv::Mat &img, const Points2f &pts, int r, cv::Mat &dst)
    {
        dst = cv::Mat( 2*r + 1, 2*r + 1, CV_64FC1);
        int n = 0;
        ISLOOP (pts) {
            cv::Point p( ROUND(pts[i].x), ROUND(pts[i].y));
            cv::Rect rect( p.x - r, p.y - r, 2*r + 1, 2*r + 1 );
            if (!check_rect( rect, img.rows, img.cols)) continue;
            cv::Mat tmp;
            img( rect).convertTo( tmp, CV_64FC1);
            dst = dst * (n/(double)(n+1)) + tmp * (1/(double)(n+1));
            n++;
        }
    } // avg_hoods
    
    // Generic way to get any feature for all intersections
    //-----------------------------------------------------------------------------------------
    template <typename F>
    inline void get_feature( const cv::Mat &img, const Points2f &intersections, int r,
                                   F Feat,
                                   std::vector<double> &res,
                                   double yshift = 0, bool scale_flag=true)
    {
        res.clear();
        double feat = 0;
        ISLOOP (intersections) {
            cv::Point p(ROUND(intersections[i].x), ROUND(intersections[i].y));
            cv::Rect rect( p.x - r, p.y - r + yshift, 2*r + 1, 2*r + 1 );
            feat = 0;
            if (check_rect( rect, img.rows, img.cols)) {
                const cv::Mat &hood( img(rect));
                feat = Feat( hood);
            }
            res.push_back( feat);
        } // for intersections
        if (scale_flag) {
            vec_scale( res, 255);
        }
    } // get_feature
    
    // Median of pixel values. Used to find B stones.
    //---------------------------------------------------------------------------------
    inline double brightness_feature( const cv::Mat &hood)
    {
        return channel_median(hood);
    } // brightness_feature()
    
    // Median of pixel values. Used to find B stones.
    //---------------------------------------------------------------------------------
    inline double sigma_feature( const cv::Mat &hood)
    {
        cv::Scalar mmean, sstddev;
        cv::meanStdDev( hood, mmean, sstddev);
        return sstddev[0];
    } // sigma_feature()
    
    // Look whether cross pixels are set in neighborhood of p_.
    // hood should be binary, 0 or 1, from an adaptive threshold operation.
    //---------------------------------------------------------------------------------
    inline double cross_feature( const cv::Mat &hood)
    {
        int mid_y = ROUND(hood.rows / 2.0);
        int mid_x = ROUND(hood.cols / 2.0);
        double ssum = 0;
        // Look for horizontal line in the middle
        CLOOP (hood.cols) {
            ssum += hood.at<uint8_t>(mid_y, c);
        }
        // Look for vertical line in the middle
        RLOOP (hood.rows) {
            ssum += hood.at<uint8_t>(r, mid_x);
        }
        double totsum = cv::sum(hood)[0];
        ssum = RAT( ssum, totsum);
        return ssum;
    } // cross_feature()
    
    // Return a ring shaped mask used to detect W stones in threshed gray img.
    // For some reason, this is much worse than outer_minus_inner.
    //-------------------------------------------------------------------------
    inline cv::Mat& ringmask()
    {
        static cv::Mat mask;
        if (mask.rows) { return mask; }
        
        // Build the mask, once.
        const int r = 12;
        //const int middle_r = 8;
        const int inner_r = 3;
        const int width = 2*r + 1;
        const int height = width;
        mask = cv::Mat( height, width, CV_8UC1);
        mask = 0;
        cv::Point center( r, r);
        cv::circle( mask, center, r, 255, -1);
        //cv::circle( mask, center, middle_r, 127, -1);
        cv::circle( mask, center, inner_r, 0, -1);
        
        return mask;
    }
    
    // Return a cross shaped mask.
    // thickness is weird: 1->1, 2->3, 3->5, 4->5, 5->7, 6->7, ...
    //-------------------------------------------------------------------------
    inline cv::Mat& crossmask( const int thickness_=5, const int r_=12)
    {
        static cv::Mat mask;
        static int thickness=0;
        static int r=0;
        if (r != r_ || thickness != thickness_) {
            r = r_;
            thickness = thickness_;
        }
        else {
            return mask;
        }
        // Build the mask, once.
        mask = cv::Mat( 2*r+1, 2*r+1, CV_8UC1);
        mask = 0;
        cv::Point center( r, r);
        // horiz
        cv::line( mask, cv::Point( 0, r), cv::Point( 2*r+1, r), 255, thickness);
        // vert
        cv::line( mask, cv::Point( r, 0), cv::Point( r, 2*r+1), 255, thickness);
        
        return mask;
    }
    
    // Match a mask to all points around p within a square of radius r. Return best match.
    // Image and mask are double mats with values 0 .. 255.0 .
    // The result is in the range 0..255. Smaller numbers indicate better match.
    // Mask dimensions must be odd.
    //---------------------------------------------------------------------------------------------------
    inline int match_mask_near_point( const cv::Mat &img, const cv::Mat &mask, Point2f pf, int r)
    {
        assert( mask.rows % 2);
        assert( mask.cols % 2);
        int dx = mask.cols / 2;
        int dy = mask.rows / 2;
        cv::Point p = pf2p( pf);
        double mindiff = 1E9;
        for (int x = p.x - r; x <= p.x + r; x++) {
            for (int y = p.y - r; y <= p.y + r; y++) {
                cv::Point q( x, y);
                cv::Rect rect( q.x - dx, q.y - dy, mask.cols, mask.rows);
                if (!check_rect( rect, img.rows, img.cols)) continue;
                cv::Mat diff = cv::abs( mask - img(rect));
                double ssum = cv::sum( diff)[0];
                if (ssum < mindiff) { mindiff = ssum; }
            } // for y
        } // for x
        mindiff /= (mask.rows * mask.cols);
        mindiff = ROUND(mindiff);
        //if (mindiff > 255) mindiff = 255;
        return mindiff;
    } // match_mask_near_point()
    
    // Match a mask to all intersections. Find best match for each intersection within a radius.
    //--------------------------------------------------------------------------------------------
    inline void match_mask_near_points( const cv::Mat &img_, const cv::Mat mask_,
                                              const Points2f &intersections, int r,
                                              std::vector<double> &res)
    {
        res.clear();
        cv::Mat img, mask;
        img_.convertTo( img, CV_64FC1);
        mask_.convertTo( mask, CV_64FC1);
        ISLOOP (intersections) {
            double feat = match_mask_near_point( img, mask, intersections[i], r);
            res.push_back( feat);
        }
    } // match_mask_near_points()
}; // class BlackWhiteEmpty

#endif /* BlackWhiteEmpty_hpp */

