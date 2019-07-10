
//
//  Scoring.hpp
//  KifuCam
//
// The MIT License (MIT)
//
// Copyright (c) 2019 Andreas Hauenstein <hauensteina@gmail.com>
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

// Class to score a position, given scoring network output (wprobs)

#ifndef Scoring_hpp
#define Scoring_hpp

#import "Globals.h"
#import "Common.hpp"
#import "GoBoard.hpp"

//=================
class Scoring
{
public:
    //---------------------
    Scoring() {}
    
    //---------------------------------------------------------------
    void score( const int pos[], const double wprobs[], int turn) {
        replay_game( pos);
        int tt=42;
    } // score()
    
    //--------------------------------------
    void replay_game( const int pos[]) {
        // Put all the stones on the board
        m_board = GoBoard( pos);
        ILOOP( 361) {
            if (pos[i] != EEMPTY) {
                m_board.place_stone( pos[i], GoPoint(i));
            }
        } // ILOOP
    } // replay_game()
    
private:
    GoBoard m_board;
}; // class Scoring


#endif /* Scoring_hpp */
