
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
    
    //--------------------------------------------------------------------------------------------------
    std::tuple<int,int> score( const int pos[], const double wprobs[], int turn, char *&terrmap_out) {
        replay_game( pos);
        static char terrmap[BOARD_SZ * BOARD_SZ];
        ILOOP (BOARD_SZ * BOARD_SZ) {
            terrmap[i] = color( wprobs[i]);
        }
        enforce_strings( terrmap, wprobs);
        // Compute score. Split neutral points between players.
        auto player = turn;
        int wpoints = 0, bpoints = 0;
        ILOOP( BOARD_SZ * BOARD_SZ) {
            auto col = terrmap[i];
            if (col == 'w') {
                wpoints++;
            }
            else if (col == 'b') {
                bpoints++;
            }
            else { // neutral
                if (player == BBLACK) {
                    bpoints++; player = WWHITE;
                }
                else {
                    wpoints++; player = BBLACK;
                }
            }
        } // ILOOP
        terrmap_out = terrmap;
        return {wpoints, bpoints};
    } // score()
    
private:
    GoBoard m_board;
    
    //--------------------------------------
    void replay_game( const int pos[]) {
        // Put all the stones on the board
        m_board = GoBoard( pos);
        ILOOP( BOARD_SZ * BOARD_SZ) {
            if (pos[i] != EEMPTY) {
                m_board.place_stone( pos[i], GoPoint(i));
            }
        } // ILOOP
    } // replay_game()

    // Decide color from wprob for each point
    //-------------------------------------------
    char color( double wprob) {
        const double NEUTRAL_THRESH = 0.4; // 0.30; // 0.40 0.15
        if (fabs(0.5 - wprob) < NEUTRAL_THRESH) { return 'n'; }
        else if (wprob > 0.5) { return 'w'; }
        else { return 'b'; }
    } // color()
    
    // Make sure all stones in a string have the same color
    //--------------------------------------------------------------
    void enforce_strings( char terrmap[], const double wprobs[]) {
        auto strs = m_board.strings();
        for (auto &gostr : strs) {
            auto avg_col = 0.0;
            double i = -1;
            for (auto &point : gostr.stones()) {
                i++;
                auto wprob = wprobs[point.idx()];
                avg_col = avg_col * (i/(i+1)) + wprob / (i+1);
            } // for point
            auto truecolor = avg_col < 0.5 ? 'b' : 'w';
            for (auto &point : gostr.stones()) {
                terrmap[point.idx()] = truecolor;
            }
        } // for gostr
    } // enforce_strings()
    
}; // class Scoring


#endif /* Scoring_hpp */
