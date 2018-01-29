//
//  Boardness.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-12-19.
//  Copyright © 2017 AHN. All rights reserved.
//

// Class to find out how likely a board starts at left upper corner r,c
// in the grid of intersections.

#ifndef Boardness_hpp
#define Boardness_hpp

#include <iostream>
#include "Common.hpp"
#include "Ocv.hpp"

extern cv::Mat mat_dbg;

class Boardness
//=================
{
public:
    // Data
    //--------
    
    // From constructor
    const Points2f &m_intersections; // all intersections
    const cv::Mat  &m_pyr;           // pyramid filtered color image
    const Points2f m_blobs;         // Potential intersections found by BlobDetector
    const std::vector<cv::Vec2f> &m_horiz_lines; // Horizontal lines
    const std::vector<cv::Vec2f> &m_vert_lines; // Horizontal lines
    const int m_boardsz;
    
    // Internal
    cv::Mat m_pyrpix;          // A pixel per intersection, from m_pyr
    cv::Mat m_pyrpix_edgeness;  // pyrpix preprocessed for edgeness
    std::vector<bool> m_blobflags; // For each intersection, is there a blob
    cv::Mat m_edgeness;  // Prob of board at r,c by edgeness
    cv::Mat m_blobness;  // Prob of board at r,c by blobness
    
    // Methods
    //----------
    
    //---------------------------------------------------------------------------------------------------
    Boardness( const Points2f &intersections, const Points &blobs, const cv::Mat &pyr, int boardsz,
              const std::vector<cv::Vec2f> &horiz_lines, const std::vector<cv::Vec2f> &vert_lines) :
    m_intersections(intersections), m_pyr(pyr), m_blobs(points2float(blobs)), m_boardsz(boardsz),
    m_horiz_lines(horiz_lines), m_vert_lines(vert_lines)
    {
        // Pyr pixel value at each intersection as an image
        m_pyrpix = cv::Mat::zeros( SZ(horiz_lines), SZ(vert_lines), CV_8UC3);
        int i=0;
        RSLOOP (horiz_lines) {
            CSLOOP (vert_lines) {
                Point2f pf = intersections[i++];
                const int rad = 2;
                auto hood = make_hood( pf, rad, rad);
                if (check_rect( hood, pyr.rows, pyr.cols)) {
                    cv::Scalar m = cv::mean( pyr(hood));
                    m_pyrpix.at<cv::Vec3b>(r,c) = cv::Vec3b( m[0], m[1], m[2]);
                }
                
                //                cv::Point p = pf2p(pf);
                //                if (p.x < m_pyr.cols && p.y < m_pyr.rows && p.x >= 0 && p.y >= 0) {
                //                    m_pyrpix.at<cv::Vec3b>(r,c) = m_pyr.at<cv::Vec3b>(p);
                //                }
            } // CSLOOP
        } // RSLOOP
    } // constructor
    
    // Color Difference between first lines and the backgroud
    //------------------------------------------------------------------------
    cv::Mat& edgeness()
    {
        m_pyrpix_edgeness = m_pyrpix.clone();
        cv::Mat &m = m_pyrpix_edgeness;
        // Replace really dark places with average to suppress fake edges inside the board
        cv::Scalar smean = cv::mean( m);
        Pixel mean( smean[0], smean[1], smean[2]);
        m.forEach<Pixel>( [&mean](Pixel &v, const int *p)
                         {
                             double gray = (v.x + v.y + v.z) / 3.0;
                             if (gray < 50 ) {
                                 v = mean;
                             }
                         });
        
        cv::Mat tmp = cv::Mat::zeros( SZ(m_horiz_lines), SZ(m_vert_lines), CV_64FC1);
        double mmax = -1E9;
        
        RSLOOP (m_horiz_lines) {
            CSLOOP (m_vert_lines) {
                double lsum, rsum, tsum, bsum;
                lsum = rsum = tsum = bsum = 0;
                int lcount, rcount, tcount, bcount;
                lcount = rcount = tcount = bcount = 0;
                
                // Left and right edge
                for (int rr = r; rr < r + m_boardsz; rr++) {
                    if (p_on_img( cv::Point( c, rr), m) &&
                        p_on_img( cv::Point( c - 1, rr), m))
                    {
                        auto b_l = m.at<cv::Vec3b>( rr, c); // on the board
                        auto o_l = m.at<cv::Vec3b>( rr, c - 1); // just outside the board
                        if (cv::norm(b_l) > 0 && cv::norm(o_l) > 0) {
                            lsum += cv::norm( b_l, o_l);
                            lcount++;
                        }
                    }
                    if (p_on_img( cv::Point( c + m_boardsz - 1, rr), m) &&
                        p_on_img( cv::Point( c + m_boardsz, rr), m))
                    {
                        auto b_r = m.at<cv::Vec3b>( rr, c + m_boardsz - 1);
                        auto o_r = m.at<cv::Vec3b>( rr, c + m_boardsz);
                        if (cv::norm(b_r) > 0 && cv::norm(o_r) > 0) {
                            rsum += cv::norm( b_r, o_r);
                            rcount++;
                        }
                    }
                } // for rr
                // Top and bottom edge
                for (int cc = c; cc < c + m_boardsz; cc++) {
                    if (p_on_img( cv::Point( cc, r), m) &&
                        p_on_img( cv::Point( cc, r - 1), m))
                    {
                        auto b_t = m.at<cv::Vec3b>( r, cc); // on the board
                        auto o_t = m.at<cv::Vec3b>( r - 1, cc); // just outside the board
                        if (cv::norm(b_t) > 0 && cv::norm(o_t) > 0) {
                            tsum += cv::norm( b_t, o_t);
                            tcount++;
                        }
                    }
                    if (p_on_img( cv::Point( cc, r + m_boardsz - 1), m) &&
                        p_on_img( cv::Point( cc, r + m_boardsz), m))
                    {
                        auto b_b = m.at<cv::Vec3b>( r + m_boardsz - 1, cc);
                        auto o_b = m.at<cv::Vec3b>( r + m_boardsz, cc);
                        if (cv::norm(b_b) > 0 && cv::norm(o_b) > 0) {
                            bsum += cv::norm( b_b, o_b);
                            bcount++;
                        }
                    }
                } // for cc
                // Sum lets an outlier dominate
                //tmp.at<double>(r,c) =  lsum + rsum + tsum + bsum;
                // Multiplying instead of summ rewards similarity between factors
                tmp.at<double>(r,c) =  RAT(lsum,lcount) * RAT(rsum,rcount) * RAT(tsum,tcount) * RAT(bsum,bcount);
                if (tmp.at<double>(r,c) > mmax) {
                    mmax = tmp.at<double>(r,c) ;
                    //PLOG ("r: %d c: %d mmax: %.2f counts: %d %d %d %d\n", r, c, mmax, lcount, rcount, tcount, bcount);
                }
            } // CSLOOP
        } // RSLOOP
        double scale = 255.0 / mmax;
        tmp.convertTo( m_edgeness, CV_8UC1, scale);
        return m_edgeness;
    } // edgeness()
    
    // Percentage of blobs captured by the board
    //---------------------------------------------
    cv::Mat& blobness()
    {
        const cv::Mat &m = m_pyrpix;
        cv::Mat tmp = cv::Mat::zeros( SZ(m_horiz_lines), SZ(m_vert_lines), CV_64FC1);
        double mmax = -1E9;
        
        if (!SZ(m_blobflags)) { fill_m_blobflags(); }
        RSLOOP (m_horiz_lines) {
            CSLOOP (m_vert_lines) {
                double ssum = 0;
                for (int rr = r; rr < r + m_boardsz; rr++) {
                    for (int cc = c; cc < c + m_boardsz; cc++) {
                        if (!p_on_img( cv::Point( cc, rr), m)) continue;
                        int idx = rc2idx( rr,cc);
                        if (m_blobflags[idx]) { ssum += 1; }
                    }
                }
                tmp.at<double>(r,c) = ssum;
                if (ssum > mmax) mmax = ssum;
            } // CSLOOP
        } // RSLOOP
        double scale = 255.0 / mmax;
        tmp.convertTo( m_blobness, CV_8UC1, scale);
        return m_blobness;
    } // blobness
    
private:
    // Fill m_blobflags. For each intersection, is there a blob.
    //------------------------------------------------------------
    void fill_m_blobflags()
    {
        const int EPS = 4.0;
        typedef struct { int idx; double d; } Idxd;
        // All points on horiz lines
        std::vector<Idxd> blob_to_horiz( SZ(m_blobs), {-1,1E9});
        ISLOOP (m_horiz_lines) {
            KSLOOP (m_blobs) {
                auto p = m_blobs[k];
                double d = fabs(dist_point_line( p, m_horiz_lines[i]));
                if (d < blob_to_horiz[k].d) {
                    blob_to_horiz[k].idx = i;
                    blob_to_horiz[k].d = d;
                }
            }
        } // ISLOOP
        // All points on vert lines
        std::vector<Idxd> blob_to_vert( SZ(m_blobs), {-1,1E9});
        ISLOOP (m_vert_lines) {
            KSLOOP (m_blobs) {
                auto p = m_blobs[k];
                double d = fabs(dist_point_line( p, m_vert_lines[i]));
                if (d < blob_to_vert[k].d) {
                    blob_to_vert[k].idx = i;
                    blob_to_vert[k].d = d;
                }
            }
        } // ISLOOP
        
        m_blobflags = std::vector<bool>(SZ(m_intersections),false);
        //mat_dbg = cv::Mat::zeros( SZ(m_horiz_lines), SZ(m_vert_lines), CV_8UC3);
        KSLOOP (m_blobs) {
            int blobrow = blob_to_horiz[k].idx;
            int blobcol = blob_to_vert[k].idx;
            double blobd_h = blob_to_horiz[k].d;
            double blobd_v = blob_to_horiz[k].d;
            if (blobrow >= 0 && blobcol >= 0 && blobd_h < EPS && blobd_v < EPS) {
                m_blobflags[rc2idx(blobrow, blobcol)] = true;
                //auto col = get_color();
                //mat_dbg.at<cv::Vec3b>(blobrow,blobcol) = cv::Vec3b( col[0],col[1],col[2]);
            }
        } // KSLOOP
    } // fill_m_blobflags()
    
    // Convert r,c of intersection into linear index
    //--------------------------------------------------
    int rc2idx( int r, int c)
    {
        return r * SZ(m_vert_lines) + c;
    }
}; // class Boardness


#endif /* Boardness_hpp */

