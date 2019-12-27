
//
//  GoBoard.hpp
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

// Class to represent a Go position in terms of strings on a grid

#ifndef GoBoard_hpp
#define GoBoard_hpp

#import <set>
#import "Globals.h"
#import "Common.hpp"

// An intersection on a Go board. row, col 0 to boardsize - 1.
//==============================================================
class GoPoint
{
public:
    GoPoint( int row, int col) : m_row(row), m_col(col) {}
    GoPoint( int idx) : m_row(idx/BOARD_SZ), m_col(idx % BOARD_SZ) {}
    GoPoint():m_row(-1), m_col(-1) {}
    //---------------------------------------------
    bool operator < (const GoPoint& rhs) const {
        return (m_row < rhs.m_row) || ((m_row == rhs.m_row) && (m_col < rhs.m_col));
    }
    //int idx() const { return (BOARD_SZ - m_row) * BOARD_SZ + m_col; }
    int idx() const { return m_row * BOARD_SZ + m_col; }
    int m_row;
    int m_col;
}; // class GoPoint

// A string of connected stones
//================================
class GoString
{
public:
    // Default constructor to get map to work with GoString values
    //---------------------------------------------------------------
    GoString():m_color(-1){}
    //-----------------------------------------------------------------------------------------
    GoString( int color, const std::set<GoPoint> &stones, const std::set<GoPoint> &liberties):
    m_color(color), m_stones(stones), m_liberties(liberties) {}
    
    //----------------------------------------------
    bool operator < (const GoString& rhs) const {
        auto myfirst = *(m_stones.begin());
        auto rightfirst = *(rhs.m_stones.begin());
        return (myfirst < rightfirst);
    }
    
    //------------------------------------
    GoString add_liberty( GoPoint p) {
        auto res = *this;
        res.m_liberties.insert( p);
        return res;
    } // add_liberty()
        
    //-----------------------------------
    GoString rm_liberty( GoPoint p) {
        auto res = *this;
        if (res.m_liberties.count(p)) {
            res.m_liberties.erase(p);
        }
        return res;
    } // rm_liberty()
    int color() const { return m_color; }
    const std::set<GoPoint> & stones() const { return m_stones; }
    const std::set<GoPoint> & liberties() const { return m_liberties; }
    //--------------------------------------------------------
    int num_liberties() { return (int)m_liberties.size(); }
    //------------------------------------------------
    GoString merged_with( const GoString & gostr) {
        auto stones = m_stones;
        stones.insert( gostr.m_stones.begin(), gostr.m_stones.end());
        auto libs0 = m_liberties;
        libs0.insert( gostr.m_liberties.begin(), gostr.m_liberties.end());
        std::set<GoPoint> libs;
        std::set_difference( libs0.begin(), libs0.end(), stones.begin(), stones.end(),
                            std::inserter( libs, libs.end()));
        return GoString( m_color, stones, libs);
    } // merged_with()
    //---------------------
    static void test() {
        // Merge, no common stones
        std::set<GoPoint> stones1 { GoPoint(0,0), GoPoint(0,1) };
        std::set<GoPoint> libs1 { GoPoint(1,0), GoPoint(1,1), GoPoint(0,2) };
        std::set<GoPoint> stones2 { GoPoint(0,2), GoPoint(0,3) };
        std::set<GoPoint> libs2 { GoPoint(0,1), GoPoint(0,4), GoPoint(1,2), GoPoint(1,3) };
        GoString str1( BBLACK,stones1,libs1), str2( BBLACK,stones2,libs2);
        auto merged1 = str1.merged_with( str2);
        // Merge, common stones
        std::set<GoPoint> stones3 { GoPoint(0,0), GoPoint(0,1) };
        std::set<GoPoint> libs3 { GoPoint(1,0), GoPoint(1,1), GoPoint(0,2) };
        std::set<GoPoint> stones4 { GoPoint(0,1), GoPoint(1,1) };
        std::set<GoPoint> libs4 { GoPoint(0,0), GoPoint(1,0), GoPoint(0,2), GoPoint(1,2), GoPoint(2,1) };
        GoString str3( BBLACK,stones3,libs3), str4( BBLACK,stones4, libs4);
        auto merged2 = str3.merged_with( str4);
        // Remove a liberty which exists
        merged2 = merged2.rm_liberty( GoPoint( 2,1));
        // Remove a liberty that does not exist
        merged2 = merged2.rm_liberty( GoPoint( 10,10));
        // Add a liberty
        merged2 = merged2.add_liberty( GoPoint( 2,1));
    } // test()
private:
    int m_color; // BBLACK, WWHITE, EEMPTY
    std::set<GoPoint> m_stones;
    std::set<GoPoint> m_liberties;
}; // class GoString

//=================
class GoBoard
{
public:
    //---------------------
    GoBoard( int sz=BOARD_SZ) {
        m_sz = sz;
    } // GoBoard()
    
    // Make a GoBoard from a recognized position
    //-----------------------------------------------
    GoBoard( const int pos[], int sz=BOARD_SZ) {
        m_sz = sz;
        ILOOP( sz*sz) {
            if (pos[i] == EEMPTY) { continue; }
            int row = i / BOARD_SZ;
            int col = i % BOARD_SZ;
            place_stone( pos[i], GoPoint(row,col));
        } // for
    } // GoBoard( pos)
    
    //------------------------------------------
    std::set<GoPoint> neighbors( GoPoint p) {
        std::set<GoPoint> res;
        if (p.m_col > 0) { auto left = GoPoint( p.m_row, p.m_col - 1 ); res.insert( left); }
        if (p.m_col < m_sz-1) { auto right = GoPoint( p.m_row, p.m_col + 1 ); res.insert( right); }
        if (p.m_row > 0) { auto top = GoPoint( p.m_row-1, p.m_col); res.insert( top); }
        if (p.m_row < m_sz-1) { auto bot = GoPoint( p.m_row+1, p.m_col); res.insert( bot); }
        return res;
    } // neighbors()

    //------------------------------------
    GoString get_go_string( GoPoint p) {
        return m_grid[p];
    } // get_go_string()

    //------------------------------------
    int color( GoPoint p) {
        return m_grid[p].color();
    } // color()

    //--------------------------------
    bool isempty( GoPoint p) {
        return m_grid[p].color() < 0;
    } // isempty()

    //-------------------------------------------
    void place_stone( int color, GoPoint p_) {
        std::set<GoPoint> liberties;
        std::set<GoPoint> adj_same_color;
        std::set<GoPoint> adj_other_color;
        for (auto p : neighbors(p_)) {
            if (isempty(p)) { liberties.insert( p); } // @@@
            else { // there's a stone at p
                GoString &neigh_str( m_grid[p]);
                if (neigh_str.color() == color) { // a friend
                    adj_same_color.insert( p);
                }
                else { // a foe
                    adj_other_color.insert( p);
                }
            }
        } // for neighbors
        GoString new_string( color, { p_ }, liberties);
        // Merge adjacent strings of same color
        for (auto p:adj_same_color) {
            new_string = new_string.merged_with( m_grid[p]);
        } // for
        for (auto p : new_string.stones() ) {
            m_grid[p] = new_string;
        } // for
        // Take this liberty off the other color strings
        for( auto p:adj_other_color) {
            auto gostr = get_go_string( p);
            //std::cout << str_ptr << std::endl;
            auto repl = gostr.rm_liberty( p_);
            if (!repl.num_liberties()) { // No libs, take it off
                rm_string( gostr);
            }
            else { // take the lib off the neighbor string
                for (auto p : repl.stones() ) {
                    m_grid[p] = repl;
                }
            }
        } // for str_ptr
        //std::cout << ">>>>>>>>>>>\n";
    } // place_stone()
    
    // Remove a captured string from the board
    //-------------------------------------------
    void rm_string( GoString gostr) {
        for (auto p : gostr.stones()) {
            // Create libs for the neighboring strings
            auto neighs = neighbors(p);
            for (auto neigh : neighs) {
                if (!m_grid.count(neigh)) { continue; } // empty
                if (gostr.stones().count(neigh)) { continue; } // that's ourselves
                auto neighstr = m_grid[neigh];
                auto repl = neighstr.add_liberty( p);
                for (auto &p : repl.stones() ) {
                    m_grid[p] = repl;
                }
            } // for neighs
            m_grid.erase( p);
        } // for p in gostr
    } // rm_string()
    
    //---------------------------------
    std::set<GoString> strings() {
        std::set<GoString> res;
        for( auto const& [key, val] : m_grid ) {
            res.insert( val);
        } // for
        return res;
    } // strings()
        
    //---------------------------------------------
    bool is_self_capture( int col, GoPoint p) {
        std::set<GoString> friendly_strings;
        for (auto neighbor: neighbors(p)) {
            auto neighbor_string = m_grid[neighbor];
            if (neighbor_string.color() < 0) { // liberty
               return false;
            }
            else if (neighbor_string.color() == col) {
                friendly_strings.insert( neighbor_string);
            }
            else if (neighbor_string.num_liberties() == 1) { // capture
               return false;
            }
        } // for
        if (std::all_of( friendly_strings.begin(), friendly_strings.end(),
                        [](GoString s) { return s.num_liberties() == 1; })) {
            return true;
        }
        return false;
    } // is_self_capture()
    
    //---------------------------------------------
    bool is_weak_eye( int col, GoPoint p) {
        if (m_grid[p].color() < 0) {
            return false;
        }
        for (auto neighbor: neighbors(p)) {
            auto ncol = m_grid[neighbor].color();
            if (ncol != col) {
                return false;
            }
        }
        return true;
    } // is_weak_eye()
        
    //----------------------
    static void test() {
        int pos[BOARD_SZ * BOARD_SZ];
        ILOOP(BOARD_SZ * BOARD_SZ) { pos[i] = EEMPTY; }
        auto w = [&pos](int row,int col) { pos[(row)*BOARD_SZ + col] = WWHITE; };
        auto b = [&pos](int row,int col) { pos[(row)*BOARD_SZ + col] = BBLACK; };

        // Just two strings, B and W, no captures
        /*
         x x . o .
         o o o o .
         */
        b(0,0); b(0,1);
        w(1,0); w(1,1); w(1,2); w(1,3); w(0,3);
        auto board = GoBoard( pos);
        
        // Two stones captured
        /*
         x x o o .
         o o o o .
         */
        ILOOP(BOARD_SZ * BOARD_SZ) { pos[i] = EEMPTY; }
        b(0,0); b(0,1);
        w(1,0); w(1,1); w(1,2); w(1,3); w(0,3);
        w(0,2);
        board = GoBoard( pos);
    } // test()
private:
    int m_sz;
    std::map<GoPoint,GoString> m_grid;
}; // class GoBoard


#endif /* GoBoard_hpp */
