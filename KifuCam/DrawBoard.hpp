//
//  DrawBoard.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-12-14.
//  Copyright © 2017 AHN. All rights reserved.
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
