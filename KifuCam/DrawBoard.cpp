//
//  DrawBoard.cpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-12-14.
//  Copyright © 2017 AHN. All rights reserved.
//

#include "Globals.h"
#include "DrawBoard.hpp"
//#include "BlackWhiteEmpty.hpp"


// Draw a board from a list of B,W,E
//---------------------------------------------------------------
void DrawBoard::draw( std::vector<int> diagram)
{
    int x,y;
    // The lines
    RLOOP (m_board_sz) {
        b2xy( r, 0, x, y);
        cv::Point p1( x,y);
        b2xy( r, 18, x, y);
        cv::Point p2( x,y);
        int color = 0; int width = 1;
        cv::line( m_dst, p1, p2, color, width, CV_AA);
    }
    CLOOP (m_board_sz) {
        b2xy( 0, c, x, y);
        cv::Point p1( x,y);
        b2xy( 18, c, x, y);
        cv::Point p2( x,y);
        int color = 0; int width = 1;
        cv::line( m_dst, p1, p2, color, width, CV_AA);
    }
    // The stones
    const int rightmarg = m_leftmarg;
    const double boardwidth  = m_dst.cols - m_leftmarg - rightmarg;
    int r = ROUND( 0.5 * boardwidth / (m_board_sz - 1)) +1;
    ISLOOP (diagram) {
        int row = i / m_board_sz;
        int col = i % m_board_sz;
        b2xy( row, col, x, y);
        if (diagram[i] == BBLACK) {
            int color = 0;
            cv::circle( m_dst, cv::Point(x,y), r, color, -1);
        }
        else if (diagram[i] == WWHITE) {
            int color = 255;
            cv::circle( m_dst, cv::Point(x,y), r, color, -1);
        }
    }
    
} // draw()

// Board row and col (0-18) to pixel coord
//--------------------------------------------------------------
void DrawBoard::b2xy( int boardrow, int boardcol,
                     int &x, int &y) // out
{
    const int rightmarg = m_leftmarg;
    const double boardwidth  = m_dst.cols - m_leftmarg - rightmarg;
    const double boardheight = boardwidth;
    x = ROUND( m_leftmarg + boardcol * boardwidth / (m_board_sz-1));
    y = ROUND( m_topmarg + boardrow * boardheight / (m_board_sz-1));
} // b2xy()
