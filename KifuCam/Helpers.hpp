//
//  Helpers.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-09.
//  Copyright © 2018 AHN. All rights reserved.
//

// Collection of app specific standalone C++ functions

#ifndef Helpers_hpp
#define Helpers_hpp
#ifdef __cplusplus

#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <regex>

#include "Common.hpp"
#include "Boardness.hpp"
#include "Clust1D.hpp"

// Apply inverse thresh and dilate grayscale image.
//-------------------------------------------------------------------------------------------
inline void thresh_dilate( const cv::Mat &img, cv::Mat &dst, int thresh = 8)
{
    cv::adaptiveThreshold( img, dst, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV,
                          5 /* 11 */ ,  // neighborhood_size
                          thresh);  // threshold
    cv::Mat element = cv::getStructuringElement( cv::MORPH_RECT, cv::Size(3,3));
    cv::dilate( dst, dst, element );
}

// Convert vector of int diagram to sgf.
// sgf coordinates range a,b,c,..,i,j,...,s
// column first, row second
// Example:
/*
 (;GM[1]
 GN[<game_name>]
 FF[4]
 CA[UTF-8]
 AP[KifuCam]
 RU[Chinese]
 SZ[19]
 KM[7.5]
 GC[Super great game]
 PW[w]
 PB[ahnb]
 AB[aa][ba][ja][sa][aj][jj][sj][as][js][ss])
*/
//----------------------------------------------------------------------------------
inline std::string generate_sgf( const std::string &title, const std::vector<int> diagram,
                         double komi=7.5)
{
    const int BUFSZ = 10000;
    char buf[BUFSZ+1];
    if (!SZ(diagram)) return "";
    int boardsz = ROUND( sqrt( SZ(diagram)));
    snprintf( buf, BUFSZ,
             "(;GM[1]"
             " GN[%s]"
             " FF[4]"
             " CA[UTF-8]"
             " AP[KifuCam]"
             " RU[Chinese]"
             " SZ[%d]"
             " KM[%f]",
             title.c_str(), boardsz, komi);

    std::string moves="";
    ISLOOP (diagram) {
        int row = i / boardsz;
        int col = i % boardsz;
        char ccol = 'a' + col;
        char crow = 'a' + row;
        std::string tag;
        if (diagram[i] == WWHITE) { tag = "AW"; }
        else if (diagram[i] == BBLACK) { tag = "AB"; }
        else continue;
        moves += tag + "[" + ccol + crow + "]";
    }
    return buf + moves + ")\n";
} // generate_sgf()

// e.g for board size, call get_sgf_tag( sgf, "SZ")
//----------------------------------------------------------------------------------------
inline std::string get_sgf_tag( const std::string &sgf, const std::string &tag)
{
    std::string res;
    std::regex re_tag( tag + "\\[[^\\]]*\\]");
    std::smatch m;
    std::regex_search( sgf, m, re_tag);
    if (!SZ(m)) {
        return "";
    }
    std::string mstr = m[0];
    std::vector<std::string> parts, parts1;
    str_split( mstr, parts, '[');
    str_split( parts[1], parts1, ']');
    res = parts1[0];
    return res;
} // get_sgf_tag()

// Look for AB[ab][cd] or AW[ab]... and transform into a linear vector
// of ints
//-----------------------------------------------------------
inline std::vector<int> sgf2vec( const std::string &sgf_)
{
    //PLOG("==========\n");
    const int NONE = 0;
    const int AB = 1;
    const int AW = 2;
    std::string sgf = std::regex_replace( sgf_, std::regex("\\s+"), "" ); // no whitespace
    int boardsz = std::stoi( get_sgf_tag( sgf, "SZ"));
    std::vector<int> res( boardsz * boardsz, EEMPTY);
    if (SZ(sgf) < 3) return res;
    char window[4];
    window[0] = sgf[0];
    window[1] = sgf[1];
    window[2] = sgf[2];
    window[3] = '\0';
    int i;
    auto shiftwin = [&i,&window,&sgf](){window[0] = window[1]; window[1] = window[2]; window[2] = sgf[i++];};
    int mode = NONE;
    for (i=3; i < SZ(sgf); ) {
        std::string tstr(window);
        if (window[2] != '[') {
            mode = NONE;
            shiftwin();
            continue;
        }
        else if (tstr == "AB[" || mode == AB) {
            mode = AB;
            if (i+2 > SZ(sgf)) break;
            int col = sgf[i] - 'a';
            shiftwin();
            int row = sgf[i] - 'a';
            shiftwin();
            int idx = col + row * boardsz;
            res[idx] = BBLACK;
            //PLOG("B at %c%c\n",col+'a',row+'a');
            shiftwin(); shiftwin();
        }
        else if (tstr == "AW[" || mode == AW) {
            mode = AW;
            if (i+2 > SZ(sgf)) break;
            int col = sgf[i] - 'a';
            shiftwin();
            int row = sgf[i] - 'a';
            shiftwin();
            int idx = col + row * boardsz;
            res[idx] = WWHITE;
            //PLOG("W at %c%c\n",col+'a',row+'a');
            shiftwin(); shiftwin();
        }
        else {
            mode = NONE;
            shiftwin();
        }
    } // for
    return res;
} // sgf2vec

// Draw sgf on a square single channel Mat
//----------------------------------------------------------------------
inline void draw_sgf( const std::string &sgf_, cv::Mat &dst, int width)
{
    std::string sgf = std::regex_replace( sgf_, std::regex("\\s+"), "" ); // no whitespace
    int height = width;
    dst = cv::Mat( height, width, CV_8UC1);
    dst = 180;
    int boardsz = 19;
    std::vector<int> diagram( boardsz*boardsz,EEMPTY);
    int marg = width * 0.05;
    int innerwidth = width - 2*marg;
    if (SZ(sgf) > 3) {
        boardsz = std::stoi( get_sgf_tag( sgf, "SZ"));
        diagram = sgf2vec( sgf);
    }
    auto rc2p = [boardsz, innerwidth, marg](int row, int col) {
        cv::Point res;
        float d = innerwidth / (boardsz-1.0) ;
        res.x = ROUND( marg + d*col);
        res.y = ROUND( marg + d*row);
        return res;
    };
    // Draw the lines
    ILOOP (boardsz) {
        cv::Point p1 = rc2p( i, 0);
        cv::Point p2 = rc2p( i, boardsz-1);
        cv::Point q1 = rc2p( 0, i);
        cv::Point q2 = rc2p( boardsz-1, i);
        cv::line( dst, p1, p2, cv::Scalar(0,0,0), 1, CV_AA);
        cv::line( dst, q1, q2, cv::Scalar(0,0,0), 1, CV_AA);
    }
    // Draw the hoshis
    int r = ROUND( 0.25 * innerwidth / (boardsz-1.0));
    cv::Point p;
    p = rc2p( 3, 3);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 15, 15);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 3, 15);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 15, 3);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 9, 9);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 9, 3);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 3, 9);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 9, 15);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( 15, 9);
    cv::circle( dst, p, r, 0, -1);

    // Draw the stones
    int rad = ROUND( 0.5 * innerwidth / (boardsz-1.0));
    ISLOOP (diagram) {
        int r = i / boardsz;
        int c = i % boardsz;
        cv::Point p = rc2p( r,c);
        if (diagram[i] == WWHITE) {
            cv::circle( dst, p, rad, 255, -1);
            cv::circle( dst, p, rad, 0, 2);
        }
        else if (diagram[i] == BBLACK) {
            cv::circle( dst, p, rad, 0, -1);
        }
    } // ISLOOP
} // draw_sgf()

// Reject board if opposing lines not parallel
// or adjacent lines not at right angles
//-----------------------------------------------------------
inline bool board_valid( Points2f board, const cv::Mat &img)
{
    double screenArea = img.rows * img.cols;
    if (board.size() != 4) return false;
    double area = cv::contourArea(board);
    if (area / screenArea > 0.95) return false;
    if (area / screenArea < 0.20) return false;
    
    double par_ang1   = (180.0 / M_PI) * angle_between_lines( board[0], board[1], board[3], board[2]);
    double par_ang2   = (180.0 / M_PI) * angle_between_lines( board[0], board[3], board[1], board[2]);
    double right_ang1 = (180.0 / M_PI) * angle_between_lines( board[0], board[1], board[1], board[2]);
    double right_ang2 = (180.0 / M_PI) * angle_between_lines( board[0], board[3], board[3], board[2]);
    //double horiz_ang   = (180.0 / M_PI) * angle_between_lines( board[0], board[1], cv::Point(0,0), cv::Point(1,0));
    //NSLog(@"%f.2, %f.2, %f.2, %f.2", par_ang1,  par_ang2,  right_ang1,  right_ang2 );
    //if (abs(horiz_ang) > 20) return false;
    if (abs(par_ang1) > 20) return false;
    if (abs(par_ang2) > 30) return false;
    if (abs(right_ang1 - 90) > 20) return false;
    if (abs(right_ang2 - 90) > 20) return false;
    return true;
} // board_valid()

// Convert horizontal (roughly) polar line to a pair
// y_at_middle, angle
//--------------------------------------------------------------
inline cv::Vec2f polar2changle( const cv::Vec2f pline, double middle_x)
{
    cv::Vec2f res;
    double y_at_middle = y_from_x( middle_x, pline);
    double angle;
    angle = -(pline[1] - PI/2);
    res = cv::Vec2f( y_at_middle, angle);
    return res;
}

// Convert a pair (y_at_middle, angle) to polar
//---------------------------------------------------------------
inline cv::Vec2f changle2polar( const cv::Vec2f cline, double middle_x)
{
    cv::Vec2f res;
    cv::Vec4f seg( middle_x, cline[0], middle_x + 1, cline[0] - tan(cline[1]));
    res = segment2polar( seg);
    return res;
}

// Convert vertical (roughly) polar line to a pair
// x_at_middle, angle
//--------------------------------------------------------------
inline cv::Vec2f polar2cvangle( const cv::Vec2f pline, double middle_y)
{
    cv::Vec2f res;
    double x_at_middle = x_from_y( middle_y, pline);
    double angle;
    angle = -pline[1];
    res = cv::Vec2f( x_at_middle, angle);
    return res;
}

// Convert a pair (x_at_middle, angle) to polar
//---------------------------------------------------------------
inline cv::Vec2f cvangle2polar( const cv::Vec2f cline, double middle_y)
{
    cv::Vec2f res;
    cv::Vec4f seg( cline[0], middle_y , cline[0] + tan(cline[1]), middle_y + 1);
    res = segment2polar( seg);
    return res;
}



// Replace close clusters of vert lines by their average.
//-----------------------------------------------------------------------------------
inline void dedup_verticals( std::vector<cv::Vec2f> &lines, const cv::Mat &img)
{
    if (SZ(lines) < 3) return;
    // Cluster by x in the middle
    //const double wwidth = 32.0;
    const double wwidth = 8.0;
    const double middle_y = img.rows / 2.0;
    const int min_clust_size = 0;
    auto Getter =  [middle_y](cv::Vec2f line) { return x_from_y( middle_y, line); };
    auto vert_line_cuts = Clust1D::cluster( lines, wwidth, Getter);
    std::vector<std::vector<cv::Vec2f> > clusters;
    Clust1D::classify( lines, vert_line_cuts, min_clust_size, Getter, clusters);
    
    // Average the clusters into single lines
    lines.clear();
    ISLOOP (clusters) {
        auto &clust = clusters[i];
        double theta = vec_avg( clust, [](cv::Vec2f line){ return line[1]; });
        double rho   = vec_avg( clust, [](cv::Vec2f line){ return line[0]; });
        cv::Vec2f line( rho, theta);
        lines.push_back( line);
    }
} // dedup_verticals()

// Replace close clusters of horiz lines by their average.
//-----------------------------------------------------------------------------------
inline void dedup_horizontals( std::vector<cv::Vec2f> &lines, const cv::Mat &img)
{
    if (SZ(lines) < 3) return;
    // Cluster by y in the middle
    const double wwidth = 32.0;
    const double middle_x = img.cols / 2.0;
    const int min_clust_size = 0;
    auto Getter =  [middle_x](cv::Vec2f line) { return y_from_x( middle_x, line); };
    auto horiz_line_cuts = Clust1D::cluster( lines, wwidth, Getter);
    std::vector<std::vector<cv::Vec2f> > clusters;
    Clust1D::classify( lines, horiz_line_cuts, min_clust_size, Getter, clusters);
    
    // Average the clusters into single lines
    lines.clear();
    ISLOOP (clusters) {
        auto &clust = clusters[i];
        double theta = vec_avg( clust, [](cv::Vec2f line){ return line[1]; });
        double rho   = vec_avg( clust, [](cv::Vec2f line){ return line[0]; });
        cv::Vec2f line( rho, theta);
        lines.push_back( line);
    }
} // dedup_horizontals()

// Find a line close to the middle with roughly median theta.
// The lines should be sorted by rho.
//--------------------------------------------------------------------------
inline int good_center_line( const std::vector<cv::Vec2f> &lines)
{
    const int r = 2;
    //const double EPS = 4 * PI/180;
    auto thetas = vec_extract( lines, [](cv::Vec2f line) { return line[1]; } );
    auto med_theta = vec_median( thetas);
    
    // Find a line close to the middle where theta is close to median theta
    int half = SZ(lines)/2;
    double mind = 1E9;
    int minidx = -1;
    ILOOP (r+1) {
        if (half - i >= 0) {
            double d = fabs( med_theta - thetas[half-i]);
            if (d < mind) {
                mind = d;
                minidx = half - i;
            }
        }
        if (half + i < SZ(lines)) {
            double d = fabs( med_theta - thetas[half+i]);
            if (d < mind) {
                mind = d;
                minidx = half + i;
            }
        }
    } // ILOOP
    return minidx;
} // good_center_line()

// Adjacent lines should have similar slope
//-----------------------------------------------------------------------------
inline void filter_vert_lines( std::vector<cv::Vec2f> &vlines)
{
    const double eps = 10.0;
    std::sort( vlines.begin(), vlines.end(), [](cv::Vec2f &a, cv::Vec2f &b) { return a[0] < b[0]; });
    int med_idx = good_center_line( vlines);
    if (med_idx < 0) return;
    const double med_theta = vlines[med_idx][1];
    // Going left and right, theta should not change abruptly
    std::vector<cv::Vec2f> good;
    good.push_back( vlines[med_idx]);
    const double EPS = eps * PI/180;
    double prev_theta;
    // right
    prev_theta = med_theta;
    for (int i = med_idx+1; i < SZ(vlines); i++ ) {
        double d = fabs( vlines[i][1] - prev_theta) + fabs( vlines[i][1] - med_theta);
        if (d < EPS) {
            good.push_back( vlines[i]);
            prev_theta = vlines[i][1];
        }
    }
    // left
    prev_theta = med_theta;
    for (int i = med_idx-1; i >= 0; i-- ) {
        double d = fabs( vlines[i][1] - prev_theta) + fabs( vlines[i][1] - med_theta);
        if (d < EPS) {
            good.push_back( vlines[i]);
            prev_theta = vlines[i][1];
        }
    }
    vlines = good;
} // filter_vert_lines()

// Adjacent lines should have similar slope
//-----------------------------------------------------------------
inline void filter_horiz_lines( std::vector<cv::Vec2f> &hlines)
{
    const double eps = 1.1;
    std::sort( hlines.begin(), hlines.end(), [](cv::Vec2f &a, cv::Vec2f &b) { return a[0] < b[0]; });
    int med_idx = good_center_line( hlines);
    if (med_idx < 0) return;
    double theta = hlines[med_idx][1];
    // Going up and down, theta should not change abruptly
    std::vector<cv::Vec2f> good;
    good.push_back( hlines[med_idx]);
    const double EPS = eps * PI/180;
    double prev_theta;
    // down
    prev_theta = theta;
    for (int i = med_idx+1; i < SZ(hlines); i++ ) {
        if (fabs( hlines[i][1] - prev_theta) < EPS) {
            good.push_back( hlines[i]);
            prev_theta = hlines[i][1];
        }
    }
    // up
    prev_theta = theta;
    for (int i = med_idx-1; i >= 0; i-- ) {
        if (fabs( hlines[i][1] - prev_theta) < EPS) {
            good.push_back( hlines[i]);
            prev_theta = hlines[i][1];
        }
    }
    hlines = good;
} // filter_horiz_lines()

// Find line where top_x and bot_x match best.
//---------------------------------------------------------------------------------------------------------------
inline int closest_vert_line( const std::vector<cv::Vec2f> &lines, double top_x, double bot_x, double top_y, double bot_y,
                      double &min_dtop, double &min_dbot, double &min_err, double &min_top_rho, double &min_bot_rho) // out
{
    std::vector<double> top_rhos = vec_extract( lines,
                                               [top_y](cv::Vec2f a) { return x_from_y( top_y, a); });
    std::vector<double> bot_rhos = vec_extract( lines,
                                               [bot_y](cv::Vec2f a) { return x_from_y( bot_y, a); });
    int minidx = -1;
    min_err = 1E9;
    ISLOOP (top_rhos) {
        double dtop = fabs( top_rhos[i] - top_x );
        double dbot = fabs( bot_rhos[i] - bot_x );
        double err = dtop + dbot;
        if (err < min_err) {
            minidx = i;
            min_err = err;
            min_dtop = dtop;
            min_dbot = dbot;
            min_top_rho = top_rhos[i];
            min_bot_rho = bot_rhos[i];
        }
    }
    return minidx;
} // closest_vert_line()

// Find the x-change per line in in upper and lower screen area and synthesize
// the whole bunch starting at the middle. Replace synthesized lines with real
// ones if close enough.
//------------------------------------------------------------------------------------------------
inline void fix_vertical_lines( std::vector<cv::Vec2f> &lines, const std::vector<cv::Vec2f> &all_vert_lines,
                        const cv::Mat &img, double x_thresh = 4.0)
{
    const double width = img.cols;
    const int top_y = 0.2 * img.rows;
    const int bot_y = 0.8 * img.rows;
    //const int mid_y = 0.5 * img.rows;
    
    std::sort( lines.begin(), lines.end(),
              [bot_y](cv::Vec2f a, cv::Vec2f b) {
                  return x_from_y( bot_y, a) < x_from_y( bot_y, b);
              });
    std::vector<double> top_rhos = vec_extract( lines,
                                               [top_y](cv::Vec2f a) { return x_from_y( top_y, a); });
    std::vector<double> bot_rhos = vec_extract( lines,
                                               [bot_y](cv::Vec2f a) { return x_from_y( bot_y, a); });
    auto d_top_rhos = vec_delta( top_rhos);
    auto d_bot_rhos = vec_delta( bot_rhos);
    vec_filter( d_top_rhos, [](double d){ return d > 5 && d < 20;});
    vec_filter( d_bot_rhos, [](double d){ return d > 8 && d < 25;});
    double d_top_rho = vec_median( d_top_rhos);
    double d_bot_rho = vec_median( d_bot_rhos);
    
    // Find a good line close to the middle
    int good_idx = good_center_line( lines);
    if (good_idx < 0) {
        lines.clear();
        return;
    }
    cv::Vec2f med_line = lines[good_idx];
    
    // Interpolate the rest
    std::vector<cv::Vec2f> synth_lines;
    synth_lines.push_back(med_line);
    double top_rho, bot_rho;
    // If there is a close line, use it. Else interpolate.
    const double X_THRESH = x_thresh; //6;
    // Lines to the right
    top_rho = x_from_y( top_y, med_line);
    bot_rho = x_from_y( bot_y, med_line);
    ILOOP(100) {
        top_rho += d_top_rho;
        bot_rho += d_bot_rho;
        //int close_idx = vec_closest( bot_rhos, bot_rho);
        //int close_idx = closest_vert_line( all_vert_lines, top_rho, bot_rho, top_y, bot_y);
        double dtop, dbot, err, top_x, bot_x;
        closest_vert_line( all_vert_lines, top_rho, bot_rho, top_y, bot_y, // in
                          dtop, dbot, err, top_x, bot_x); // out
        //double dbot = fabs( bot_rho - bot_rhos[close_idx]);
        //double dtop = fabs( top_rho - top_rhos[close_idx]);
        if (dbot < X_THRESH && dtop < X_THRESH) {
            top_rho   = top_x;
            bot_rho   = bot_x;
        }
        cv::Vec2f line = segment2polar( cv::Vec4f( top_rho, top_y, bot_rho, bot_y));
        if (top_rho > width) break;
        if (i > 19) break;
        //if (x_from_y( mid_y, line) > width) break;
        synth_lines.push_back( line);
    } // ILOOP
    // Lines to the left
    top_rho = x_from_y( top_y, med_line);
    bot_rho = x_from_y( bot_y, med_line);
    ILOOP(100) {
        top_rho -= d_top_rho;
        bot_rho -= d_bot_rho;
        //int close_idx = vec_closest( bot_rhos, bot_rho);
        //int close_idx = closest_vert_line( lines, top_rho, bot_rho, top_y, bot_y);
        double dtop, dbot, err, top_x, bot_x;
        closest_vert_line( all_vert_lines, top_rho, bot_rho, top_y, bot_y, // in
                          dtop, dbot, err, top_x, bot_x); // out
        if (dbot < X_THRESH && dtop < X_THRESH) {
            //PLOG("repl %d\n",i);
            top_rho   = top_x;
            bot_rho   = bot_x;
        }
        cv::Vec2f line = segment2polar( cv::Vec4f( top_rho, top_y, bot_rho, bot_y));
        if (top_rho < 0) break;
        if (i > 19) break;
        //if (x_from_y( mid_y, line) < 0) break;
        synth_lines.push_back( line);
    } // ILOOP
    std::sort( synth_lines.begin(), synth_lines.end(),
              [bot_y](cv::Vec2f a, cv::Vec2f b) {
                  return x_from_y( bot_y, a) < x_from_y( bot_y, b);
              });
    lines = synth_lines;
} // fix_vertical_lines()

// Find the median distance between vert lines for given horizontal.
// We use the result to find the next horizontal line.
//--------------------------------------------------------------------------------------
inline double hspace_at_line( const std::vector<cv::Vec2f> &vert_lines, cv::Vec2f hline)
{
    std::vector<double> dists;
    Point2f prev;
    ISLOOP (vert_lines) {
        //cv::Vec4f seg = polar2segment( vert_lines[i]);
        Point2f p = intersection( vert_lines[i], hline);
        if (i) {
            double d = cv::norm( p - prev);
            dists.push_back( d);
        }
        prev = p;
    }
    double res = vec_median( dists);
    //double res = dists[SZ(dists)/2];
    return res;
} // hspace_at_y()

// Similarity between two horizontal lines.
// y_distance**2 to the left plus y_distance**2 to the right.
//--------------------------------------------------------------------
inline double h_line_similarity( cv::Vec2f a, cv::Vec2f b, double middle_x)
{
    const int r = 50;
    double aleft  = y_from_x( middle_x - r, a);
    double bleft  = y_from_x( middle_x - r, b);
    double aright = y_from_x( middle_x + r, a);
    double bright = y_from_x( middle_x + r, b);
    double res = sqrt( SQR( aleft - bleft) + SQR( aright - bright));
    return res;
} // h_line_similarity()

// Find closest line in a bunch of horiz lines
//-----------------------------------------------------------------------------------------------------------
inline int closest_hline( cv::Vec2f line, const std::vector<cv::Vec2f> &hlines, double middle_x, double &d)
{
    int minidx = -1;
    d = 1E9;
    ISLOOP (hlines) {
        if (h_line_similarity( line, hlines[i], middle_x) < d) {
            d = h_line_similarity( line, hlines[i], middle_x);
            minidx = i;
        }
    }
    return minidx;
} // closest_hline()

// Similarity between two horizontal lines.
// x_distance**2 above plus x_distance**2 below.
//----------------------------------------------------------------------------
inline double v_line_similarity( cv::Vec2f a, cv::Vec2f b, double middle_y)
{
    const int r = 50;
    double atop  = x_from_y( middle_y - r, a);
    double btop  = x_from_y( middle_y - r, b);
    double abot  = x_from_y( middle_y + r, a);
    double bbot  = x_from_y( middle_y + r, b);
    double res = sqrt( SQR( atop - btop) + SQR( abot - bbot));
    return res;
} // v_line_similarity

// Find the change per line in rho and theta and synthesize the whole bunch
// starting at the middle. Replace synthesized lines with real ones if close enough.
//-----------------------------------------------------------------------------------------------------
inline void fix_horiz_lines( std::vector<cv::Vec2f> &lines_, const std::vector<cv::Vec2f> &vert_lines,
                     const cv::Mat &img)
{
    const double middle_x = img.cols / 2.0;
    const double height = img.rows;
    
    // Convert hlines to chlines (center y + angle)
    std::vector<cv::Vec2f> lines;
    ISLOOP (lines_) {
        lines.push_back( polar2changle( lines_[i], middle_x));
    }
    std::sort( lines.begin(), lines.end(), [](cv::Vec2f a, cv::Vec2f b) { return a[0] < b[0]; } );
    lines_.clear();
    ISLOOP (lines) { lines_.push_back( changle2polar( lines[i], middle_x)); }
    
    auto rhos   = vec_extract( lines, [](cv::Vec2f line) { return line[0]; } );
    //auto thetas = vec_extract( lines, [](cv::Vec2f line) { return line[1]; } );
    auto d_rhos   = vec_delta( rhos);
    //vec_filter( d_rhos, [](double d){ return d > 10;});
    
    int good_idx = good_center_line( lines);
    if (good_idx < 0) {
        lines.clear();
        return;
    }
    cv::Vec2f med_line = lines[good_idx];
    
    
    // Interpolate the rest
    std::vector<cv::Vec2f> synth_lines;
    synth_lines.push_back(med_line);
    
    double med_rho = med_line[0];
    double med_d_rho = vec_median( d_rhos);
    double alpha = RAT( hspace_at_line( vert_lines, cv::Vec2f( 0, PI/2)),
                       hspace_at_line( vert_lines, cv::Vec2f( med_rho, PI/2)));
    double dd_rho_per_y = RAT( med_d_rho * (1.0 - alpha), med_rho);
    
    double rho, theta, d_rho;
    cv::Vec2f line;
    
    // Lines below
    //d_rho = med_d_rho;
    d_rho = hspace_at_line( vert_lines, cv::Vec2f( med_rho, PI/2));
    rho = med_line[0];
    theta = med_line[1];
    ILOOP(100) {
        double old_rho = rho;
        rho += d_rho;
        double d;
        int close_idx = closest_hline( changle2polar( cv::Vec2f( rho, theta), middle_x), lines_, middle_x, d);
        if (d < d_rho * 0.6) {
            rho   = lines[close_idx][0];
            theta = lines[close_idx][1];
            d_rho = rho - old_rho;
        }
        else {
            d_rho += (rho - old_rho) * dd_rho_per_y;
            //PLOG("synth %d\n",i);
        }
        if (rho > height) break;
        cv::Vec2f line( rho,theta);
        synth_lines.push_back( line);
    } // ILOOP
    
    // Lines above
    //d_rho = med_d_rho;
    d_rho = 0.9 * hspace_at_line( vert_lines, cv::Vec2f( med_rho, PI/2));
    rho = med_line[0];
    theta = med_line[1];
    ILOOP(100) {
        double old_rho = rho;
        rho -= d_rho;
        double d;
        int close_idx = closest_hline( changle2polar( cv::Vec2f( rho, theta), middle_x), lines_, middle_x, d);
        if (d < d_rho * 0.6) {
            rho   = lines[close_idx][0];
            theta = lines[close_idx][1];
            d_rho = old_rho - rho;
        }
        else {
            d_rho += (rho - old_rho) * dd_rho_per_y;
            //PLOG("i %d d_rho %.2f\n", i, d_rho);
        }
        if (rho < 0) break;
        if (d_rho < 3) break;
        cv::Vec2f line( rho,theta);
        synth_lines.push_back( line);
    } // ILOOP
    // Sort top to bottom
    std::sort( synth_lines.begin(), synth_lines.end(),
              [](cv::Vec2f line1, cv::Vec2f line2) {
                  return line1[0] < line2[0];
              });
    lines_.clear();
    ISLOOP (synth_lines) { lines_.push_back( changle2polar( synth_lines[i], middle_x)); }
} // fix_horiz_lines()

// How many of these points are on the line, roughly.
//------------------------------------------------------------
inline int count_points_on_line( cv::Vec2f line, Points pts)
{
    int res = 0;
    for (auto p:pts) {
        double d = fabs(dist_point_line( p, line));
        if (d < 0.75) {
            res++;
        }
    }
    return res;
}

// Find a vertical line thru pt which hits a lot of other points
// PRECONDITION: allpoints must be sorted by y
//-------------------------------------------------------------------------------------------------
inline cv::Vec2f find_vert_line_thru_point( const Points &allpoints, cv::Point pt, int &maxhits)
{
    // Find next point below.
    const double THETA_EPS = /* 10 */ 20 * PI / 180;
    maxhits = -1;
    cv::Vec2f res;
    for (auto p: allpoints) {
        if (p.y <= pt.y) continue;
        Points pts = { pt, p };
        cv::Vec2f newline = segment2polar( cv::Vec4f( pt.x, pt.y, p.x, p.y));
        if (fabs(newline[1]) < THETA_EPS ) {
            int nhits = count_points_on_line( newline, allpoints);
            if (nhits > maxhits) {
                maxhits = nhits;
                res = newline;
            }
        }
    }
    return res;
} // find_vert_line_thru_point()

// Find a horiz line thru pt which hits a lot of other points
// PRECONDITION: allpoints must be sorted by x
//------------------------------------------------------------------------------------
inline cv::Vec2f find_horiz_line_thru_point( const Points &allpoints, cv::Point pt)
{
    // Find next point to the right.
    const double THETA_EPS = 5 * PI / 180;
    int maxhits = -1;
    cv::Vec2f res = {0,0};
    for (auto p: allpoints) {
        if (p.x <= pt.x) continue;
        Points pts = { pt, p };
        cv::Vec2f newline = segment2polar( cv::Vec4f( pt.x, pt.y, p.x, p.y));
        if (fabs( fabs( newline[1]) - PI/2) < THETA_EPS ) {
            int nhits = count_points_on_line( newline, allpoints);
            if (nhits > maxhits) {
                maxhits = nhits;
                res = newline;
            }
        }
    }
    return res;
} // find_horiz_line_thru_point()

// Homegrown method to find vertical line candidates, as a replacement
// for thinning Hough lines.
//-----------------------------------------------------------------------------
inline std::vector<cv::Vec2f> homegrown_vert_lines( Points pts)
{
    std::vector<cv::Vec2f> res;
    // Find points in quartile with lowest y
    std::sort( pts.begin(), pts.end(), [](Point2f p1, Point2f p2) { return p1.y < p2.y; } );
    Points top_points( SZ(pts)/4);
    std::copy_n ( pts.begin(), SZ(pts)/4, top_points.begin() );
    // For each point, find a line that hits many other points
    for (auto tp: top_points) {
        int nhits;
        cv::Vec2f newline = find_vert_line_thru_point( pts, tp, nhits);
        if (/*nhits > 5 &&*/ newline[0] != 0) {
            res.push_back( newline);
        }
    }
    return res;
} // homegrown_vert_lines()

// Homegrown method to find horizontal line candidates
//-----------------------------------------------------------------------------
inline std::vector<cv::Vec2f> homegrown_horiz_lines( Points pts)
{
    std::vector<cv::Vec2f> res;
    // Find points in quartile with lowest x
    std::sort( pts.begin(), pts.end(), [](Point2f p1, Point2f p2) { return p1.x < p2.x; } );
    Points left_points( SZ(pts)/4);
    std::copy_n ( pts.begin(), SZ(pts)/4, left_points.begin() );
    // For each point, find a line that hits many other points
    for (auto tp: left_points) {
        cv::Vec2f newline = find_horiz_line_thru_point( pts, tp);
        if (newline[0] != 0) {
            res.push_back( newline);
        }
    }
    return res;
} // homegrown_horiz_lines()


// Among the largest two in m1, choose the one where m2 is larger
//------------------------------------------------------------------
inline cv::Point tiebreak( const cv::Mat &m1, const cv::Mat &m2)
{
    cv::Mat tmp = m1.clone();
    double m1min, m1max;
    cv::Point m1minloc, m1maxloc;
    cv::minMaxLoc( tmp, &m1min, &m1max, &m1minloc, &m1maxloc);
    cv::Point largest = m1maxloc;
    tmp.at<uint8_t>(largest) = 0;
    cv::minMaxLoc( tmp, &m1min, &m1max, &m1minloc, &m1maxloc);
    cv::Point second = m1maxloc;
    
    cv::Point res = largest;
    if (m2.at<uint8_t>(second) > m2.at<uint8_t>(largest)) {
        res = second;
    }
    return res;
} // tiebreak()

// Use horizontal and vertical lines to find corners such that the board best matches the points we found
//-------------------------------------------------------------------------------------------------------------------
inline
Points2f find_corners( const Points blobs, std::vector<cv::Vec2f> &horiz_lines, std::vector<cv::Vec2f> &vert_lines,
                      const Points2f &intersections, const cv::Mat &img, const cv::Mat &threshed, int board_sz = 19)
{
    if (SZ(horiz_lines) < 3 || SZ(vert_lines) < 3) return Points2f();
    
    Boardness bness( intersections, blobs, img, board_sz, horiz_lines, vert_lines);
    cv::Mat &edgeness  = bness.edgeness();
    cv::Mat &blobness  = bness.blobness();
    
    cv::Point max_loc = tiebreak( blobness, edgeness);
    
    cv::Point tl = max_loc;
    cv::Point tr( tl.x + board_sz-1, tl.y);
    cv::Point br( tl.x + board_sz-1, tl.y + board_sz-1);
    cv::Point bl( tl.x, tl.y + board_sz-1);
    
    // Return the board lines only
    horiz_lines = vec_slice( horiz_lines, max_loc.y, board_sz);
    vert_lines  = vec_slice( vert_lines, max_loc.x, board_sz);
    
    // Mark corners for visualization
    mat_dbg = bness.m_pyrpix_edgeness.clone();
    mat_dbg.at<cv::Vec3b>( pf2p(tl)) = cv::Vec3b( 255,0,0);
    mat_dbg.at<cv::Vec3b>( pf2p(tr)) = cv::Vec3b( 255,0,0);
    mat_dbg.at<cv::Vec3b>( pf2p(bl)) = cv::Vec3b( 255,0,0);
    mat_dbg.at<cv::Vec3b>( pf2p(br)) = cv::Vec3b( 255,0,0);
    cv::resize( mat_dbg, mat_dbg, img.size(), 0,0, CV_INTER_NN);
    
    auto isec2pf = [&blobness, &intersections](cv::Point p) { return p2pf( intersections[p.y*blobness.cols + p.x]); };
    Points2f corners = { isec2pf(tl), isec2pf(tr), isec2pf(br), isec2pf(bl) };
    return corners;
} // find_corners()

// Get intersections of two sets of lines
//--------------------------------------------------------------------------
inline Points2f get_intersections( const std::vector<cv::Vec2f> &hlines,
                                  const std::vector<cv::Vec2f> &vlines)
{
    Points2f res;
    RSLOOP( hlines) {
        cv::Vec2f hl = hlines[r];
        CSLOOP( vlines) {
            cv::Vec2f vl = vlines[c];
            Point2f pf = intersection( hl, vl);
            res.push_back( pf);
        }
    }
    return res;
} // get_intersections()

// Unwarp the square defined by corners
//--------------------------------------------------------------------------------------------
inline void zoom_in( const cv::Mat &img, const Points2f &corners, cv::Mat &dst, cv::Mat &M)
{
    int marg = img.cols / 20;
    // Target square for transform
    Points2f square = {
        cv::Point( marg, marg),
        cv::Point( img.cols - marg, marg),
        cv::Point( img.cols - marg, img.cols - marg),
        cv::Point( marg, img.cols - marg) };
    M = cv::getPerspectiveTransform( corners, square);
    cv::warpPerspective( img, dst, M, cv::Size( img.cols, img.rows));
} // zoom_in()

// Fill image outside of board with average. Helps with adaptive thresholds.
//----------------------------------------------------------------------------------
inline void fill_outside_with_average_gray( cv::Mat &img, const Points2f &corners)
{
    uint8_t mean = cv::mean( img)[0];
    img.forEach<uint8_t>( [&mean, &corners](uint8_t &v, const int *p)
                         {
                             int x = p[1]; int y = p[0];
                             if (x < corners[0].x - 10) v = mean;
                             else if (x > corners[1].x + 10) v = mean;
                             if (y < corners[0].y - 10) v = mean;
                             else if (y > corners[3].y + 10) v = mean;
                         });
} // fill_outside_with_average_gray()

//----------------------------------------------------------------------------------
inline void fill_outside_with_average_rgb( cv::Mat &img, const Points2f &corners)
{
    cv::Scalar smean = cv::mean( img);
    Pixel mean( smean[0], smean[1], smean[2]);
    img.forEach<Pixel>( [&mean, &corners](Pixel &v, const int *p)
                       {
                           int x = p[1]; int y = p[0];
                           if (x < corners[0].x - 10) v = mean;
                           else if (x > corners[1].x + 10) v = mean;
                           if (y < corners[0].y - 10) v = mean;
                           else if (y > corners[3].y + 10) v = mean;
                       });
} // fill_outside_with_average_rgb()

// Visualize features, one per intersection.
//---------------------------------------------------------------------------------------------------------------
inline void viz_feature( const cv::Mat &img, const Points2f &intersections, const std::vector<double> features,
                 cv::Mat &dst, const double multiplier = 255)
{
    dst = cv::Mat::zeros( img.size(), img.type());
    ISLOOP (intersections) {
        auto pf = intersections[i];
        double feat = features[i];
        auto hood = make_hood( pf, 5, 5);
        if (check_rect( hood, img.rows, img.cols)) {
            dst( hood) = fmin( 255, feat * multiplier);
        }
    }
} // viz_feature()

// Translate a bunch of points
//--------------------------------------------------------------------------
inline void translate_points( const Points2f &pts, int dx, int dy, Points2f &dst)
{
    dst = Points2f(SZ(pts));
    ISLOOP (pts) {
        dst[i] = Point2f( pts[i].x + dx, pts[i].y + dy);
    }
} // translate_points()

// Set any points to empty if outside of the image
//----------------------------------------------------------------------------------------------
inline
void fix_diagram( std::vector<int> &diagram, const Points2f intersections, const cv::Mat &img)
{
    double marg = 10;
    ISLOOP (diagram) {
        Point2f p = intersections[i];
        if (p.x < marg || p.y < marg || p.x > img.cols - marg || p.y > img.rows - marg) {
            diagram[i] = EEMPTY;
        }
    }
} // fix_diagram()

// Save small crops around intersections for inspection
//-------------------------------------------------------------------------------
inline void save_intersections( const cv::Mat img,
                               const Points &intersections, int delta_v, int delta_h)
{
    ILOOP( intersections.size())
    {
        int x = intersections[i].x;
        int y = intersections[i].y;
        int dx = round(delta_h/2.0); int dy = round(delta_v/2.0);
        cv::Rect rect( x - dx, y - dy, 2*dx+1, 2*dy+1 );
        if (0 <= rect.x &&
            0 <= rect.width &&
            rect.x + rect.width <= img.cols &&
            0 <= rect.y &&
            0 <= rect.height &&
            rect.y + rect.height <= img.rows)
        {
            const cv::Mat &hood( img(rect));
            NSString *fname = nsprintf(@"hood_%03d.jpg",i);
            fname = getFullPath( fname);
            cv::imwrite( [fname UTF8String], hood);
        }
    } // ILOOP
} // save_intersections()

// Find all intersections from corners and boardsize
//---------------------------------------------------------------------------------------------
template <typename Points_>
void get_intersections_from_corners( const Points_ &corners, int boardsz, // in
                                    Points_ &result, double &delta_h, double &delta_v) // out
{
    if (corners.size() != 4) return;
    
    cv::Point2f tl = corners[0];
    cv::Point2f tr = corners[1];
    cv::Point2f br = corners[2];
    cv::Point2f bl = corners[3];
    
    std::vector<double> left_x;
    std::vector<double> left_y;
    std::vector<double> right_x;
    std::vector<double> right_y;
    ILOOP (boardsz) {
        left_x.push_back(  tl.x + i * (bl.x - tl.x) / (double)(boardsz-1));
        left_y.push_back(  tl.y + i * (bl.y - tl.y) / (double)(boardsz-1));
        right_x.push_back( tr.x + i * (br.x - tr.x) / (double)(boardsz-1));
        right_y.push_back( tr.y + i * (br.y - tr.y) / (double)(boardsz-1));
    }
    std::vector<double> top_x;
    std::vector<double> top_y;
    std::vector<double> bot_x;
    std::vector<double> bot_y;
    ILOOP (boardsz) {
        top_x.push_back( tl.x + i * (tr.x - tl.x) / (double)(boardsz-1));
        top_y.push_back( tl.y + i * (tr.y - tl.y) / (double)(boardsz-1));
        bot_x.push_back( bl.x + i * (br.x - bl.x) / (double)(boardsz-1));
        bot_y.push_back( bl.y + i * (br.y - bl.y) / (double)(boardsz-1));
    }
    delta_v = (bot_y[0] - top_y[0]) / (boardsz -1);
    delta_h = (right_x[0] - left_x[0]) / (boardsz -1);
    
    result = Points_();
    RLOOP (boardsz) {
        CLOOP (boardsz) {
            cv::Point2f p = intersection( cv::Point2f( left_x[r], left_y[r]), cv::Point2f( right_x[r], right_y[r]),
                                         cv::Point2f( top_x[c], top_y[c]), cv::Point2f( bot_x[c], bot_y[c]));
            result.push_back(p);
        }
    }
} // get_intersections_from_corners()


#endif /* __clusplus */
#endif /* Helpers_hpp */
