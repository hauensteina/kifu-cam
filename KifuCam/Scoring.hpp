
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
    //-------------
    Scoring() {}
    
    //-------------------------------------------------------------------------------------------------------
    std::tuple<int,int,int> score( const int pos[], const double wprobs_[], int turn, char *&terrmap_out) {
        const double *wprobs;
        m_board = GoBoard( pos);
        
        probs2terr( wprobs_, turn, terrmap_out);
        wprobs = wprobs_;
        fix_seki( terrmap_out, wprobs );
        auto [wwpoints, bbpoints, dame] = probs2terr( wprobs, turn, terrmap_out);

        return {wwpoints, bbpoints, dame};
    } // score()
    
private:
    GoBoard m_board;

    // Some dead stones might actually be seki. Find them and fix. //@@@
    //--------------------------------------------------------------
    void fix_seki( char *&terrmap, const double *&wprobs) {
        static double wprobs_out[ BOARD_SZ * BOARD_SZ];
        ILOOP (BOARD_SZ * BOARD_SZ) {
            wprobs_out[i] = wprobs[i];
        }
        auto strs = m_board.strings();
        for (auto gostr : strs) {
            if (gostr.color() < 0) { continue; }
            auto point = *(gostr.stones().begin());

            auto terrcol = terrmap[point.idx()];
            auto dead = (((gostr.color() == BBLACK) && (terrcol == 'w')) ||
                         ((gostr.color() == WWHITE) && (terrcol == 'b')));
            if (!dead) { continue; }
            // Try to fill the liberties of the supposedly dead string
            auto couldfill = true;
            auto seki = false;
            auto tboard = m_board; // Deep copy
            auto other_player = gostr.color() == BBLACK ? WWHITE : BBLACK;

            while( couldfill) {
                couldfill = false;
                auto gstr = tboard.get_go_string( point);
                if (gstr.color() < 0) { //captured
                    break;
                }
                // Fill all liberties that aren't self atari
                for (auto lib : gstr.liberties()) {
                    if (!tboard.is_self_capture( other_player, lib)) {
                        auto temp = tboard;
                        temp.place_stone( other_player, lib);
                        auto oppstr = temp.get_go_string( lib);
                        //auto tt = tboard.get_go_string( lib);
                        if (oppstr.num_liberties() > 1) { // not self atari
                            //tboard.place_stone( other_player, lib); // Let's play there
                            tboard = temp;
                            couldfill = true;
                        }
                        else {
                            std::cout << "self atari\n";
                        }
                    }
                } // for
                if (couldfill) {
                    continue;
                }
                seki = true;
            } // while( couldfill)
            if (seki) {
                auto myprob = gostr.color() == WWHITE ? 1.0 : 0.0;
                // All the dead stones are alive
                for (auto s : gostr.stones()) {
                    wprobs_out[s.idx()] = myprob;
                }
                // Non eye libs are neutral
                for (auto lib : gostr.liberties()) {
                    if (!m_board.is_weak_eye( gostr.color(), lib)) {
                        wprobs_out[lib.idx()] = 0.5;
                    }
                    else {
                        wprobs_out[lib.idx()] = (gostr.color() == WWHITE ? 1.0 : 0.0 );
                    }
                } // for
            }
        } // for all strings
        wprobs = wprobs_out;
    } // fix_seki()
    
    //------------------------------------------------------------------------------------------
    std::tuple<int,int,int> probs2terr( const double wprobs[], int turn, char *&terrmap_out) {
        static char terrmap[BOARD_SZ * BOARD_SZ];
        ILOOP (BOARD_SZ * BOARD_SZ) {
            terrmap[i] = color( wprobs[i]);
        }
        enforce_strings( terrmap, wprobs);
        // Compute score. Split neutral points between players.
        auto player = turn;
        int wpoints = 0, bpoints = 0, dame = 0;
        ILOOP( BOARD_SZ * BOARD_SZ) {
            auto col = terrmap[i];
            if (col == 'w') {
                wpoints++;
            }
            else if (col == 'b') {
                bpoints++;
            }
            else { // neutral
                dame++;
                if (player == BBLACK) {
                    bpoints++; player = WWHITE;
                }
                else {
                    wpoints++; player = BBLACK;
                }
            }
        } // ILOOP
        terrmap_out = terrmap;
        return {wpoints, bpoints, dame};
    } // probs2terr()
        
    // Decide color from wprob for each point
    //-------------------------------------------
    char color( double wprob) {
        // smaller means less neutral points
        const double NEUTRAL_THRESH = 0.40; // 0.22; //0.4; // 0.30; // 0.40 0.15
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
