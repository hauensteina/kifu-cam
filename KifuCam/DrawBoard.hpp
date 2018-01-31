//
//  DrawBoard.hpp
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

#ifndef DrawBoard_hpp
#define DrawBoard_hpp

#include <iostream>
#include "Common.hpp"
#include "Ocv.hpp"

class DrawBoard
//=================
{
public:
    // Constructor
    DrawBoard( cv::Mat &dst, int topmarg, int leftmarg, int board_sz):
    m_dst(dst), m_topmarg(topmarg), m_leftmarg(leftmarg), m_board_sz(board_sz)
    {}
    // Draw board and position
    void draw( std::vector<int> diagram);
private:
    cv::Mat   &m_dst;
    const int m_topmarg;
    const int m_leftmarg;
    const int m_board_sz;
    
    // Board coords to screen coords
    void b2xy( int boardrow, int boardcol,
              int &x, int &y); // out

}; // class DrawBoard


#endif /* DrawBoard_hpp */
