//
//  DrawBoard.cpp
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

#include "Globals.h"
#include "DrawBoard.hpp"

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
