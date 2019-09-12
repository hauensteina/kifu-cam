//
//  Helpers.hpp
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

// Collection of app specific standalone C++ functions

#ifndef Helpers_hpp
#define Helpers_hpp
#ifdef __cplusplus

#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <regex>

#include "Common.hpp"
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
 GC[intersections:((13,47),...)]
 PW[w]
 PB[ahnb]
 AB[aa][ba][ja][sa][aj][jj][sj][as][js][ss])
 */
// The GC tag has the pixel coordinates of the intersections.
// Couldn't use json because sgf chokes on brackets.
//------------------------------------------------------------------------------------------------------------------------
inline std::string generate_sgf( const std::string &title,
                                const std::vector<int> diagram = std::vector<int>(),
                                const Points2f &intersections = Points2f(),
                                float phi=0, float theta=0, double komi=0.0)
{
    const int BUFSZ = 10000;
    char buf[BUFSZ+1];
//    int boardsz = 19; // default
//    if (SZ(diagram) == 13*13) boardsz = 13;
//    else if (SZ(diagram) == 9*9) boardsz = 9;
    
    // Intersection coordinate string
    std::string coords = "intersections:(";
    ISLOOP( intersections) {
        snprintf( buf, BUFSZ, "(%d,%d)", ROUND( intersections[i].x), ROUND( intersections[i].y));
        if (i>0) { coords += ","; }
        coords += buf;
    }
    coords += ")";
    snprintf( buf, BUFSZ, "phi:%.2f", phi);
    std::string phistr = buf;
    snprintf( buf, BUFSZ, "theta:%.2f", theta);
    std::string thetastr = buf;

    // Generate sgf
    snprintf( buf, BUFSZ,
             "(;GM[1]"
             " GN[%s]"
             " FF[4]"
             " CA[UTF-8]"
             " AP[KifuCam]"
             " RU[Chinese]"
             " PB[Black]"
             " PW[White]"
             " BS[0]WS[0]"
             " SZ[%d]"
             " DT[%s]"
             " KM[%f]"
             " GC[%s#%s#%s#]"
             ,title.c_str(), BOARD_SZ, local_date_stamp().c_str(), komi,
             coords.c_str(), phistr.c_str(), thetastr.c_str());

    std::string moves="";
    ISLOOP (diagram) {
        int row = i / BOARD_SZ;
        int col = i % BOARD_SZ;
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
//----------------------------------------------------------------------------------
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

// Set a tag to a value. Does not work for SZ tag. Who would wants to change the size?
//---------------------------------------------------------------------------------------------------------
inline std::string set_sgf_tag( const std::string &sgf, const std::string &tag,  const std::string &val)
{
    std::string res;
    // Remove old tag, if any
    std::regex re_tag( tag + "\\[[^\\]]*\\]");
    res = std::regex_replace( sgf, re_tag, "" );
    // Build new tag
    std::string newtag = tag + "[" + val + "]";
    // Insert right after SZ tag
    std::regex re_insert( "(.*SZ\\[[0-9]+\\])(.*)");
    res = std::regex_replace( res, re_insert, "$1" + newtag + "$2" );
    return res;
} // set_sgf_tag()

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

// Convert row, col to screen image coordinates.
//--------------------------------------------------------------------
inline cv::Point rc2p (int innerwidth, int marg, int row, int col)
{
    cv::Point res;
    float d = innerwidth / (BOARD_SZ-1.0) ;
    res.x = ROUND( marg + d*col);
    res.y = ROUND( marg + d*row);
    return res;
} // rc2p()

// Draw gray sgf on a square single channel Mat
//----------------------------------------------------------------------
inline void draw_sgf( const std::string &sgf_, cv::Mat &dst, int width)
{
    std::string sgf = std::regex_replace( sgf_, std::regex("\\s+"), "" ); // no whitespace
    int height = width;
    dst = cv::Mat( height, width, CV_8UC1);
    dst = 180; // gray background
    std::vector<int> diagram( BOARD_SZ*BOARD_SZ,EEMPTY);
    int marg = width * 0.05;
    int innerwidth = width - 2*marg;
    if (SZ(sgf) > 3) {
        diagram = sgf2vec( sgf);
    }
//    auto rc2p = [innerwidth, marg](int row, int col) {
//        cv::Point res;
//        float d = innerwidth / (BOARD_SZ-1.0) ;
//        res.x = ROUND( marg + d*col);
//        res.y = ROUND( marg + d*row);
//        return res;
//    };
    // Draw the lines
    ILOOP (BOARD_SZ) {
        cv::Point p1 = rc2p( innerwidth, marg, i, 0);
        cv::Point p2 = rc2p( innerwidth, marg, i, BOARD_SZ-1);
        cv::Point q1 = rc2p( innerwidth, marg, 0, i);
        cv::Point q2 = rc2p( innerwidth, marg, BOARD_SZ-1, i);
        cv::line( dst, p1, p2, cv::Scalar(0,0,0), 1, CV_AA);
        cv::line( dst, q1, q2, cv::Scalar(0,0,0), 1, CV_AA);
    }
    // Draw the hoshis
    int r = ROUND( 0.15 * innerwidth / (BOARD_SZ-1.0));
    cv::Point p;
    p = rc2p( innerwidth, marg, 3, 3);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 15, 15);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 3, 15);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 15, 3);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 9, 9);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 9, 3);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 3, 9);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 9, 15);
    cv::circle( dst, p, r, 0, -1);
    p = rc2p( innerwidth, marg, 15, 9);
    cv::circle( dst, p, r, 0, -1);

    // Draw the stones
    int rad = ROUND( 0.5 * innerwidth / (BOARD_SZ-1.0)) - 1;
    ISLOOP (diagram) {
        int r = i / BOARD_SZ;
        int c = i % BOARD_SZ;
        cv::Point p = rc2p( innerwidth, marg, r, c);
        if (diagram[i] == WWHITE) {
            cv::circle( dst, p, rad, 255, -1, CV_AA);
            cv::circle( dst, p, rad, 0, 1, CV_AA);
        }
        else if (diagram[i] == BBLACK) {
            cv::circle( dst, p, rad, 0, -1, CV_AA);
        }
    } // ISLOOP
} // draw_sgf()

// Draw next move on the board
//-------------------------------------------------------------------------------------------------------------------
inline void draw_next_move( const std::string &sgf, const std::string &coord, int color, cv::Mat &dst, int width) {
    draw_sgf( sgf, dst, width);
    if (coord.length() > 3) { return; }
    std::string colchars = "ABCDEFGHJKLMNOPQRST";
    int row = BOARD_SZ - atoi( coord.c_str() + 1);
    auto col = (int)colchars.find( coord.c_str()[0]);
    int marg = width * 0.05;
    int innerwidth = width - 2*marg;
    auto p = rc2p( innerwidth, marg, row, col);
    int rad = ROUND( 0.5 * innerwidth / (BOARD_SZ-1.0)) - 1;
    if (color == WWHITE) {
        cv::circle( dst, p, rad, 255, -1, CV_AA);
        cv::circle( dst, p, rad, 0, 1, CV_AA);
        // Black marker circle
        cv::circle( dst, p, rad-4, 0, 1, CV_AA);
    }
    else {
        cv::circle( dst, p, rad, 0, -1, CV_AA);
        // White marker circle
        cv::circle( dst, p, rad-4, 255, 1, CV_AA);
    }
} // draw_next_move()

// Draw score map on position image
//------------------------------------------------------
inline void draw_score( cv::Mat &img, char *terrmap)
{
    int width = img.cols;
    int marg = width * 0.05;
    int innerwidth = width - 2*marg;
    int rad = ROUND( 0.2 * innerwidth / (BOARD_SZ-1.0)) - 1;
    auto rc2p = [innerwidth, marg](int row, int col) {
        row = BOARD_SZ - 1 - row;
        cv::Point res;
        float d = innerwidth / (BOARD_SZ-1.0) ;
        res.x = ROUND( marg + d*col);
        res.y = ROUND( marg + d*row);
        return res;
    };
    ILOOP (BOARD_SZ*BOARD_SZ) {
        char col = terrmap[i];
        int r = i / BOARD_SZ;
        int c = i % BOARD_SZ;
        cv::Point p = rc2p( r,c);
        if (col == 'b') {
            cv::circle( img, p, rad, 0, -1, CV_AA);
        }
        else if (col == 'w') {
            cv::circle( img, p, rad, 255, -1, CV_AA);
        }
    } // ILOOP
} // draw_score()

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
//-----------------------------------------------------------------------
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
//-----------------------------------------------------------------------
inline cv::Vec2f changle2polar( const cv::Vec2f cline, double middle_x)
{
    cv::Vec2f res;
    cv::Vec4f seg( middle_x, cline[0], middle_x + 1, cline[0] - tan(cline[1]));
    res = segment2polar( seg);
    return res;
}

// Convert vertical (roughly) polar line to a pair
// x_at_middle, angle
//-----------------------------------------------------------------------
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
//-----------------------------------------------------------------------
inline cv::Vec2f cvangle2polar( const cv::Vec2f cline, double middle_y)
{
    cv::Vec2f res;
    cv::Vec4f seg( cline[0], middle_y , cline[0] + tan(cline[1]), middle_y + 1);
    res = segment2polar( seg);
    return res;
}

// Determine the average line per cluster
//-----------------------------------------------------------------------------------------
inline void average_cluster_lines( const std::vector<double> &cuts,
                                  const std::vector<std::vector<cv::Vec2f> > &clusters,
                                  std::vector<cv::Vec2f> &lines)
{
    // Average the clusters into single lines
    lines.clear();
    ISLOOP (clusters) {
        auto &clust = clusters[i];
        double theta = vec_avg( clust, [](cv::Vec2f line){ return line[1]; });
        double rho   = vec_avg( clust, [](cv::Vec2f line){ return line[0]; });
        cv::Vec2f line( rho, theta);
        lines.push_back( line);
    }
} // average_cluster_lines()

// Replace close clusters of vert lines by their average.
//-----------------------------------------------------------------------------------
inline void dedup_verticals( std::vector<cv::Vec2f> &lines, const cv::Mat &img)
{
    if (SZ(lines) < 3) return;
    // Cluster by x in the middle
    const double wwidth = CROPSIZE;
    const double middle_y = img.rows / 2.0;
    const int min_clust_size = 0;
    auto Getter =  [middle_y](cv::Vec2f line) { return x_from_y( middle_y, line); };
    auto vert_line_cuts = Clust1D::cluster( lines, wwidth, Getter);
    std::vector<std::vector<cv::Vec2f> > clusters;
    Clust1D::classify( lines, vert_line_cuts, min_clust_size, Getter, clusters);
    average_cluster_lines( vert_line_cuts, clusters, lines);
} // dedup_verticals()

// Replace close clusters of horiz lines by their average.
//-----------------------------------------------------------------------------------
inline void dedup_horizontals( std::vector<cv::Vec2f> &lines, const cv::Mat &img)
{
    if (SZ(lines) < 3) return;
    // Cluster by y in the middle
    const double wwidth = CROPSIZE;
    const double middle_x = img.cols / 2.0;
    const int min_clust_size = 0;
    auto Getter =  [middle_x](cv::Vec2f line) { return y_from_x( middle_x, line); };
    auto horiz_line_cuts = Clust1D::cluster( lines, wwidth, Getter);
    std::vector<std::vector<cv::Vec2f> > clusters;
    Clust1D::classify( lines, horiz_line_cuts, min_clust_size, Getter, clusters);
    average_cluster_lines( horiz_line_cuts, clusters, lines);
} // dedup_horizontals()

// Find a line close to the middle with roughly median theta.
// The lines should be sorted by rho.
//-------------------------------------------------------------------
inline int good_center_line( const std::vector<cv::Vec2f> &lines)
{
    if (SZ(lines) < 3) return -1;
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
//-----------------------------------------------------------------
inline void filter_lines( std::vector<cv::Vec2f> &lines)
{
    const double eps = 10.0;
    std::sort( lines.begin(), lines.end(), [](cv::Vec2f &a, cv::Vec2f &b) { return a[0] < b[0]; });
    int med_idx = good_center_line( lines);
    if (med_idx < 0) return;
    const double med_theta = lines[med_idx][1];
    // Going left and right, theta should not change abruptly
    std::vector<cv::Vec2f> good;
    good.push_back( lines[med_idx]);
    const double EPS = eps * PI/180;
    double prev_theta;
    // right
    prev_theta = med_theta;
    for (int i = med_idx+1; i < SZ(lines); i++ ) {
        double d = fabs( lines[i][1] - prev_theta) + fabs( lines[i][1] - med_theta);
        if (d < EPS) {
            good.push_back( lines[i]);
            prev_theta = lines[i][1];
        }
    }
    // left
    prev_theta = med_theta;
    for (int i = med_idx-1; i >= 0; i-- ) {
        double d = fabs( lines[i][1] - prev_theta) + fabs( lines[i][1] - med_theta);
        if (d < EPS) {
            good.push_back( lines[i]);
            prev_theta = lines[i][1];
        }
    }
    lines = good;
} // filter_lines()

// Find line where top_x and bot_x match best.
//------------------------------------------------------------------------------------------------------------------------------------
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

// Find line where left_y and right_y match best.
//--------------------------------------------------------------------------------------------------------------------------------------
inline int closest_horiz_line( const std::vector<cv::Vec2f> &lines, double left_y, double right_y, double left_x, double right_x,
                             double &min_dleft, double &min_dright, double &min_err, double &min_left_rho, double &min_right_rho) // out
{
    std::vector<double> left_rhos = vec_extract( lines,
                                                [left_x](cv::Vec2f a) { return y_from_x( left_x, a); });
    std::vector<double> right_rhos = vec_extract( lines,
                                                 [right_x](cv::Vec2f a) { return y_from_x( right_x, a); });
    int minidx = -1;
    min_err = 1E9;
    ISLOOP (left_rhos) {
        double dleft = fabs( left_rhos[i] - left_y );
        double dright = fabs( right_rhos[i] - right_y );
        double err = dleft + dright;
        if (err < min_err) {
            minidx = i;
            min_err = err;
            min_dleft = dleft;
            min_dright = dright;
            min_left_rho = left_rhos[i];
            min_right_rho = right_rhos[i];
        }
    }
    return minidx;
} // closest_horiz_line()

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
    vec_filter( d_top_rhos, [](double d){ return d > 0.8 * CROPSIZE && d < 1.5 * CROPSIZE;});
    vec_filter( d_bot_rhos, [](double d){ return d > 0.8 * CROPSIZE && d < 1.5 * CROPSIZE;});
    //double d_top_rho = vec_median( d_top_rhos);
    //double d_bot_rho = vec_median( d_bot_rhos);
    double d_rho = vec_median( vconc( d_top_rhos, d_bot_rhos));

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
        //top_rho += d_top_rho;
        top_rho += d_rho;
        bot_rho += d_rho;
        double dtop, dbot, err, top_x, bot_x;
        //closest_vert_line( all_vert_lines, top_rho, bot_rho, top_y, bot_y, // in
        closest_vert_line( lines, top_rho, bot_rho, top_y, bot_y, // in
                          dtop, dbot, err, top_x, bot_x); // out
        if (dbot < X_THRESH && dtop < X_THRESH) {
            top_rho   = top_x;
            bot_rho   = bot_x;
        }
        cv::Vec2f line = segment2polar( cv::Vec4f( top_rho, top_y, bot_rho, bot_y));
        if (top_rho > width) break;
        if (i > BOARD_SZ) break;
        synth_lines.push_back( line);
    } // ILOOP
    // Lines to the left
    top_rho = x_from_y( top_y, med_line);
    bot_rho = x_from_y( bot_y, med_line);
    ILOOP(100) {
        //top_rho -= d_top_rho;
        top_rho -= d_rho;
        bot_rho -= d_rho;
        double dtop, dbot, err, top_x, bot_x;
        //closest_vert_line( all_vert_lines, top_rho, bot_rho, top_y, bot_y, // in
        closest_vert_line( lines, top_rho, bot_rho, top_y, bot_y, // in
                          dtop, dbot, err, top_x, bot_x); // out
        if (dbot < X_THRESH && dtop < X_THRESH) {
            top_rho   = top_x;
            bot_rho   = bot_x;
        }
        cv::Vec2f line = segment2polar( cv::Vec4f( top_rho, top_y, bot_rho, bot_y));
        if (top_rho < 0) break;
        if (i > BOARD_SZ) break;
        synth_lines.push_back( line);
    } // ILOOP
    std::sort( synth_lines.begin(), synth_lines.end(),
              [bot_y](cv::Vec2f a, cv::Vec2f b) {
                  return x_from_y( bot_y, a) < x_from_y( bot_y, b);
              });
    lines = synth_lines;
} // fix_vertical_lines()

// Find the y-change per line in in left and right screen area and synthesize
// the whole bunch starting at the middle. Replace synthesized lines with real
// ones if close enough.
//-------------------------------------------------------------------------------------------------------------
inline void fix_horizontal_lines( std::vector<cv::Vec2f> &lines, const std::vector<cv::Vec2f> &all_horiz_lines,
                                 const cv::Mat &img, double y_thresh = 4.0)
{
    const double height = img.rows;
    const int left_x = 0.2 * img.cols;
    const int right_x = 0.8 * img.cols;

    std::sort( lines.begin(), lines.end(),
              [right_x](cv::Vec2f a, cv::Vec2f b) {
                  return y_from_x( right_x, a) < y_from_x( right_x, b);
              });
    std::vector<double> left_rhos = vec_extract( lines,
                                                [left_x](cv::Vec2f a) { return y_from_x( left_x, a); });
    std::vector<double> right_rhos = vec_extract( lines,
                                                 [right_x](cv::Vec2f a) { return y_from_x( right_x, a); });
    auto d_left_rhos = vec_delta( left_rhos);
    auto d_right_rhos = vec_delta( right_rhos);
    vec_filter( d_left_rhos, [](double d){ return d > 0.8 * CROPSIZE && d < 2 * CROPSIZE;});
    vec_filter( d_right_rhos, [](double d){ return d > 0.8 * CROPSIZE && d < 2 * CROPSIZE;});
    //double d_left_rho  = vec_median( d_left_rhos);
    //double d_right_rho = vec_median( d_right_rhos);
    double d_rho = vec_median( vconc( d_left_rhos, d_right_rhos));

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
    double left_rho, right_rho;
    // If there is a close line, use it. Else interpolate.
    const double Y_THRESH = y_thresh; //6;
    // Lines below
    left_rho = y_from_x( left_x, med_line);
    right_rho = y_from_x( right_x, med_line);
    ILOOP(100) {
        left_rho += d_rho;
        right_rho += d_rho;
        double dleft, dright, err, left_y, right_y;
        //closest_horiz_line( all_horiz_lines, left_rho, right_rho, left_x, right_x, // in
        closest_horiz_line( lines, left_rho, right_rho, left_x, right_x, // in
                           dleft, dright, err, left_y, right_y); // out
        if (dleft < Y_THRESH && dright < Y_THRESH) {
            left_rho    = left_y;
            right_rho   = right_y;
        }
        cv::Vec2f line = segment2polar( cv::Vec4f( left_x, left_rho, right_x, right_rho));
        if (right_rho > height) break;
        if (i > BOARD_SZ) break;
        synth_lines.push_back( line);
    } // ILOOP
    // Lines above
    left_rho = y_from_x( left_x, med_line);
    right_rho = y_from_x( right_x, med_line);
    ILOOP(100) {
        left_rho -= d_rho;
        right_rho -= d_rho;
        double dleft, dright, err, left_y, right_y;
        //closest_horiz_line( all_horiz_lines, left_rho, right_rho, left_x, right_x, // in
        closest_horiz_line( lines, left_rho, right_rho, left_x, right_x, // in
                           dleft, dright, err, left_y, right_y); // out
        if (dleft < Y_THRESH && dright < Y_THRESH) {
            left_rho    = left_y;
            right_rho   = right_y;
        }
        cv::Vec2f line = segment2polar( cv::Vec4f( left_x, left_rho, right_x, right_rho));
        if (left_rho < 0) break;
        if (i > BOARD_SZ) break;
        synth_lines.push_back( line);
    } // ILOOP
    std::sort( synth_lines.begin(), synth_lines.end(),
              [right_x](cv::Vec2f a, cv::Vec2f b) {
                  return y_from_x( right_x, a) < y_from_x( right_x, b);
              });
    lines = synth_lines;
} // fix_horizontal_lines()


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

// Similarity between two vertical lines.
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

// Find corners by pixelwise boardness score, typically from a neural network
//-------------------------------------------------------------------------------------------------------------------
inline
Points2f find_corners_from_score( std::vector<cv::Vec2f> &horiz_lines, std::vector<cv::Vec2f> &vert_lines,
                                 const Points2f &intersections, const cv::Mat &pixel_boardness, int board_sz = BOARD_SZ)
{
    int i;
    if (SZ(horiz_lines) < 3 || SZ(vert_lines) < 3) return Points2f();
    
    // Compute boardness for each intersection
    cv::Mat isec_boardness = cv::Mat::zeros( SZ(horiz_lines), SZ(vert_lines), CV_8UC1);
    i = -1;
    RSLOOP (horiz_lines) {
        CSLOOP (vert_lines) {
            i++;
            Point2f pf = intersections[i];
            //const int rad = 3;
            const int rad = 0;
            auto hood = make_hood( pf, rad, rad);
            if (check_rect( hood, pixel_boardness.rows, pixel_boardness.cols)) {
                cv::Scalar m = cv::mean( pixel_boardness(hood));
                isec_boardness.at<uchar>(r,c) = m[0];
            }
        } // CSLOOP
    } // RSLOOP
    // Find top left for board_sz * board_sz region with highest score
    double mmax = -1E9;
    i = -1; int best_r = -1; int best_c = -1;
    RSLOOP (horiz_lines) {
        CSLOOP (vert_lines) {
            i++;
            double ssum = 0;
            for (int rr = r; rr < r + board_sz; rr++) {
                for (int cc = c; cc < c + board_sz; cc++) {
                    if (!p_on_img( cv::Point( cc, rr), isec_boardness)) {
                        ssum = -1E10;
                        goto OUTER;
                    }
                    // Only sum inside
                    if (rr == r || rr == r + board_sz - 1 ||
                        cc == c || cc == c + board_sz -1)
                    {}
                    else {
                        ssum += isec_boardness.at<uchar>(rr,cc);
                    }
                } // for(cc)
            } // for(rr)
        OUTER:
            if (ssum > mmax) {
                mmax = ssum;
                best_r = r; best_c = c;
            }
        } // CSLOOP
    } // RSLOOP
    auto rc2pf = [&](int r, int c) { return intersections[r * SZ(vert_lines) + c]; };
    Point2f tl = rc2pf( best_r, best_c);
    Point2f tr = rc2pf( best_r, best_c + board_sz - 1);
    Point2f br = rc2pf( best_r + board_sz - 1, best_c + board_sz - 1);
    Point2f bl = rc2pf( best_r + board_sz - 1, best_c);
    Points2f corners = { tl, tr, br, bl };
    // Return the board lines only
    horiz_lines = vec_slice( horiz_lines, best_r, board_sz);
    vert_lines  = vec_slice( vert_lines, best_c, board_sz);

    return corners;
} // find_corners_from_score()

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
//-----------------------------------------------------------
inline void zoom_in( const Points2f &corners, cv::Mat &M)
{
    int lmarg = IMG_WIDTH / 20;
    int tmarg = IMG_WIDTH / 20; // 15;
    // Target square for transform
    Points2f square = {
        cv::Point( lmarg, tmarg),
        cv::Point( IMG_WIDTH - lmarg, tmarg),
        cv::Point( IMG_WIDTH - lmarg, IMG_WIDTH - tmarg),
        cv::Point( lmarg, IMG_WIDTH - tmarg) };
    M = cv::getPerspectiveTransform( corners, square);
} // zoom_in()

// Fill image outside of board with average. Helps with adaptive thresholds.
//----------------------------------------------------------------------------------
inline void fill_outside_with_average_gray( cv::Mat &img, const Points2f &corners)
{
    int lmarg = 10;
    int tmarg = 15;
    uint8_t mean = cv::mean( img)[0];
    img.forEach<uint8_t>( [&mean, &corners, lmarg, tmarg](uint8_t &v, const int *p)
                         {
                             int x = p[1]; int y = p[0];
                             if (x < corners[0].x - lmarg) v = mean;
                             else if (x > corners[1].x + lmarg) v = mean;
                             if (y < corners[0].y - tmarg) v = mean;
                             else if (y > corners[3].y + tmarg) v = mean;
                         });
} // fill_outside_with_average_gray()

//----------------------------------------------------------------------------------
inline void fill_outside_with_average_rgb( cv::Mat &img, const Points2f &corners)
{
    int lmarg = 10;
    int tmarg = 15;
    cv::Scalar smean = cv::mean( img);
    Pixel mean( smean[0], smean[1], smean[2]);
    img.forEach<Pixel>( [&mean, &corners, lmarg, tmarg](Pixel &v, const int *p)
                       {
                           int x = p[1]; int y = p[0];
                           if (x < corners[0].x - lmarg) v = mean;
                           else if (x > corners[1].x + lmarg) v = mean;
                           if (y < corners[0].y - tmarg) v = mean;
                           else if (y > corners[3].y + tmarg) v = mean;
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
//----------------------------------------------------------------------------------
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
    if (diagram.size() != intersections.size()) { return; }
    double marg = 10;
    ISLOOP (diagram) {
        Point2f p = intersections[i];
        if (p.x < marg || p.y < marg || p.x > img.cols - marg || p.y > img.rows - marg) {
            diagram[i] = EEMPTY;
        }
    }
} // fix_diagram()

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
