//
//  CppInterface.mm
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

// Entry point to core functionality for the UI controllers.
// This class is the only place where Objective-C and C++ mix.
// All other files are either pure Obj-C or pure C++.

// Don't change the order of these two,
// and don't move them down
#import "Ocv.hpp"
#import <opencv2/imgcodecs/ios.h>

#import "Common.h"
#import "Globals.h"
#import "Helpers.hpp"

#import "AppDelegate.h"
#import "BlobFinder.hpp"
#import "Clust1D.hpp"
#import "CppInterface.h"
#import "KerasBoardModel.h"
#import "KerasScoreModel.h"
#import "KerasStoneModel.h"
#import "Perspective.hpp"

#import "Scoring.hpp"

extern cv::Mat mat_dbg;

@interface CppInterface()
//=======================
@property float phi; // projection angle in degrees
@property cv::Mat Mp, invProj; // Projection matrix and inverse
@property float theta; // rotation angle in degrees
@property cv::Mat Ms, invRot;  // Rotation matrix and inverse
@property float scale; // scale to make lines CROPSIZE apart
@property cv::Mat Md, invMd;  // Scale matrix and inverse

@property cv::Mat small_img; // resized image, in color, RGB, unwarped
@property cv::Mat orig_small;     // orig resized
@property cv::Mat small_zoomed;  // small, zoomed into the board
@property cv::Mat gray;  // Grayscale version of small
@property cv::Mat gray_threshed;  // gray with inv_thresh and dilation
@property cv::Mat gray_zoomed;   // Grayscale version of small, zoomed into the board
@property Points stone_or_empty; // places where we suspect stones or empty
@property std::vector<cv::Vec2f> horizontal_lines;
@property std::vector<cv::Vec2f> vertical_lines;
@property std::vector<int> diagram; // The position we detected
@property Points2f corners;
@property Points2f corners_zoomed;
@property Points2f intersections;
@property Points2f intersections_zoomed;
// History of frames. The one at the button press is often shaky.
@property std::vector<cv::Mat> imgQ;
// NN models
@property nn_io *iomodel; // Keras model to get boardness per pixel
@property KerasBoardModel *boardModel; // wrapper around iomodel
@property nn_bew *bewmodel; // Keras model to classify intersections int B,W,E
@property KerasStoneModel *stoneModel; // wrapper around bewmodel
@property nn_score *scoreNN; // Keras model to get white prob for each intersection
@property KerasScoreModel *scoreModel; // wrapper around scoreNN

@end

@implementation CppInterface
//============================

//----------------------
- (instancetype)init
{
    // Test scoring 
//    int *pos_out;
//    double *wprobs = [KerasScoreModel test:&pos_out];
//    char *terrmap_out;
//    Scoring scoring;
//    auto [wpoints, bpoints] = scoring.score( pos_out, wprobs, BBLACK, terrmap_out);
    
    self = [super init];
    if (self) {
        g_docroot = [getFullPath(@"") UTF8String];
        // Load template files
        cv::Mat tmat;
        // The boardness model
        _iomodel = [nn_io new];
        _boardModel = [[KerasBoardModel alloc] initWithModel:_iomodel];
        // The stone model
        _bewmodel = [nn_bew new];
        _stoneModel = [[KerasStoneModel alloc] initWithModel:_bewmodel];
        // The scoring model
        _scoreNN = [nn_score new];
        _scoreModel = [[KerasScoreModel alloc] initWithModel:_scoreNN];
    }
    return self;
} // init()

//=== Misc Public ===
//===================

// Put a video frame into the image queue. The newest one is often shaky.
//-------------------------------------------------------------------------
- (void)qImg:(UIImage *)img
{
    cv::Mat m;
    UIImageToMat( img, m);
    resize( m, m, IMG_WIDTH);
    cv::cvtColor( m, m, cv::COLOR_RGBA2RGB);
    int keep_n_frames = 4;
    ringpush( _imgQ , m, keep_n_frames); // keep 4 frames
}

//-----------------
- (void)clearImgQ
{
    _imgQ.clear();
}

// Detect position on image and count errors
//------------------------------------------------------------
- (int) runTestImg:(UIImage *)img withSgf:(NSString *)sgf
{
    cv::Mat m;
    UIImageToMat( img, m);
    resize( m, m, IMG_WIDTH);
    cv::cvtColor( m, m, cv::COLOR_RGBA2RGB);
    if (![self recognize_position:m breakIfBad:NO]) {
        return -1;
    }
    auto correct_diagram = sgf2vec([sgf UTF8String]);
    auto &detected_diagram = _diagram;
    assert( SZ(detected_diagram) == SZ(correct_diagram));
    int errcount = 0;
    ISLOOP (correct_diagram) {
        if (correct_diagram[i] != detected_diagram[i]) {
            errcount++;
        }
    }
    return errcount;
} // runTestImg()

// Check for the debug mode trigger position to show right menu.
// A clump of 4 black stones in the top left corner.
//----------------------------------------------------------------
- (bool) check_debug_trigger
{
    std::vector<int> templ( SQR(BOARD_SZ), EEMPTY);
    templ[0] = BBLACK;
    templ[1] = BBLACK;
    templ[BOARD_SZ] = BBLACK;
    templ[BOARD_SZ+1] = BBLACK;
    bool res = templ == _diagram;
    return res;
} // check_debug_trigger()

//=== Debug Flow ===
//==================

// Find some intersections, blobs, verticals
//--------------------------------------------------
- (void) f00_dots_and_verticals
{
    // Normalize image
    //clahe( _orig_small, _orig_small, 2.0);
    clahe( _orig_small, _orig_small, 0.5);

    _vertical_lines.clear();
    _horizontal_lines.clear();
    // Find Blobs
    if (_orig_small.cols != IMG_WIDTH) {
        resize( _orig_small, _orig_small, IMG_WIDTH);
    }
    const cv::Size sz( _orig_small.cols, _orig_small.rows);
    cv::cvtColor( _orig_small, _orig_small, cv::COLOR_RGBA2RGB);
    _small_img = _orig_small.clone();
    cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
    thresh_dilate( _gray, _gray_threshed, 10 /*14*/);
    _stone_or_empty.clear();
    BlobFinder::find_empty_places( _gray_threshed, _stone_or_empty); // has to be first
    BlobFinder::find_stones( _gray, _stone_or_empty);
    //_stone_or_empty = BlobFinder::clean( _stone_or_empty);
    
    // Find lines
    rough_houghlines( _small_img, _stone_or_empty,
                     _vertical_lines, _horizontal_lines);

} // f00_dots_and_verticals()

// Debug wrapper for f00_dots_and_verticals
//--------------------------------------------
- (UIImage *) f00_dots_and_verticals_dbg
{
    g_app.mainVC.lbBottom.text = @"Tap the screen";
    NSString *fullfname;
    if ([g_app.menuVC demoMode]) {
        fullfname = findInBundle(@"demo", @".png");
    }
    else {
        NSString *fname = nsprintf( @"%@/%@", @TESTCASE_FOLDER, g_app.editTestCaseVC.selectedTestCase);
        fullfname = getFullPath( fname);
    }
    UIImage *img = [UIImage imageWithContentsOfFile:fullfname];
    UIImageToMat( img, _orig_small);
    [self f00_dots_and_verticals];
    
    cv::Mat drawing;
    drawing = _small_img.clone();
    // cv::cvtColor( _gray_threshed, drawing, cv::COLOR_GRAY2RGB);
    draw_points( _stone_or_empty, drawing, 2, cv::Scalar( 255,0,0));
    get_color(true);
    ISLOOP( _vertical_lines) {
        draw_polar_line( _vertical_lines[i], drawing, get_color());
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f00_dots_and_verticals_dbg()

// Make verticals parallel and really vertical
//----------------------------------------------
- (void) f02_warp
{
    //NSLog(@"f02");
    const cv::Size sz( _orig_small.cols, _orig_small.rows);
    
    // Straighten horizontals
    straight_rotation( sz, _horizontal_lines, _theta, _Ms, _invRot);
    cv::warpAffine( _small_img, _small_img, _Ms, sz);
    warp_plines( _vertical_lines, _Ms, _vertical_lines);
    
    // Unwarp verticals
    parallel_projection( sz, _vertical_lines, _phi, _Mp, _invProj);
    cv::warpPerspective( _small_img, _small_img, _Mp, sz);
    warp_plines( _vertical_lines, _Mp, _vertical_lines);

    // Find lines
    std::vector<cv::Vec2f> hlines, vlines;
    perp_houghlines( _small_img, _stone_or_empty,
                    vlines, hlines);
    dedup_verticals( vlines, _small_img);
    
    // Scale so line distance is CROPSIZE
    fix_vertical_distance( vlines, _small_img, _scale, _Md, _invMd);
    warp_plines( _vertical_lines, _Md, _vertical_lines);
    
    cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
} // f02_warp()

// Debug wrapper for f02_warp
//------------------------------------
- (UIImage *) f02_warp_dbg
{
    g_app.mainVC.lbBottom.text = @"Unwarp";
    [self f02_warp];

    cv::Mat drawing = _small_img.clone();
    get_color(true);
    ISLOOP( _vertical_lines) {
        draw_polar_line( _vertical_lines[i], drawing, get_color());
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f02_warp_dbg()

// Find lines after dewarp
//--------------------------------------------------
- (void) f03_houghlines
{
    //NSLog(@"f03");
    //_vertical_lines.clear();
    //_horizontal_lines.clear();
    //cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
    //thresh_dilate( _gray, _gray_threshed);
    
    // Warp the old points
    warp_points( _stone_or_empty, _Ms, _stone_or_empty);
    warp_points( _stone_or_empty, _Mp, _stone_or_empty);
    warp_points( _stone_or_empty, _Md, _stone_or_empty);
    auto old_points = _stone_or_empty;

    // Find blobs after dewarp
    _stone_or_empty.clear();
    _vertical_lines.clear();
    _horizontal_lines.clear();
    cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
    thresh_dilate( _gray, _gray_threshed, 3);
    BlobFinder::find_empty_places_perp ( _gray_threshed, _stone_or_empty); // has to be first
    BlobFinder::find_stones_perp( _gray, _stone_or_empty);
    vapp( _stone_or_empty, old_points);
    //_stone_or_empty = BlobFinder::clean( _stone_or_empty);

    // Find lines
    perp_houghlines( _small_img, _stone_or_empty,
                    _vertical_lines, _horizontal_lines);
} // f03_houghlines()

// Debug wrapper for f03_blobs
//-------------------------------
- (UIImage *) f03_houghlines_dbg
{
    g_app.mainVC.lbBottom.text = @"Stones and Intersections";
    [self f03_houghlines];
    
    // Show results
    cv::Mat drawing;
    drawing = _small_img.clone();
    //cv::cvtColor( _gray_threshed, drawing, cv::COLOR_GRAY2RGB);
    draw_points( _stone_or_empty, drawing, 3, cv::Scalar( 255,0,0));
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f03_houghlines_dbg()


// Find vertical grid lines
//----------------------------------
- (void) f04_vert_lines:(int)state
{
    //NSLog(@"f04");
    static std::vector<cv::Vec2f> all_vert_lines;
    switch (state) {
        case 0:
        {
            all_vert_lines = _vertical_lines;
            break;
        }
        case 1:
        {
            dedup_verticals( _vertical_lines, _gray);
            break;
        }
//        case 2:
//        {
//            // Distance between verticals should be CROPSIZE
//            //fix_vertical_distance( _vertical_lines, _small_img);
//            break;
//        }
        case 2:
        {
            const double x_thresh = CROPSIZE / 4.0; // 3.0; // / 2.0; // 4.0;
            fix_vertical_lines( _vertical_lines, all_vert_lines, _gray, x_thresh);
            break;
        }
        default:
            NSLog( @"f02_vert_lines(): bad state %d", state);
            return;
    } // switch
} // f04_vert_lines()

// Debug wrapper for f04_vert_lines
//-------------------------------------
- (UIImage *) f04_vert_lines_dbg
{
    static int state = 0;
    if (!SZ(_vertical_lines)) state = 0;
    cv::Mat drawing;
    
    switch (state) {
        case 0:
        {
            g_app.mainVC.lbBottom.text = @"Find verticals";
            [self f04_vert_lines:state];
            break;
        }
        case 1:
        {
            g_app.mainVC.lbBottom.text = @"Remove duplicates";
            [self f04_vert_lines:state];
            break;
        }
//        case 2:
//        {
//            g_app.mainVC.lbBottom.text = @"Filter";
//            [self f04_vert_lines:state];
//            break;
//        }
        case 2:
        {
            g_app.mainVC.lbBottom.text = @"Generate";
            [self f04_vert_lines:state];
            break;
        }
        default:
            state = 0;
            return NULL;
    } // switch
    state++;
    
    // Show results
    cv::cvtColor( _gray, drawing, cv::COLOR_GRAY2RGB);
    get_color(true);
    ISLOOP( _vertical_lines) {
        draw_polar_line( _vertical_lines[i], drawing, get_color());
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f04_vert_lines_dbg()


// Find horizontal grid lines
//-----------------------------
- (void) f05_horiz_lines:(int)state
{
    //NSLog(@"f05");
    static std::vector<cv::Vec2f> all_horiz_lines;
    switch (state) {
        case 0:
        {
            all_horiz_lines = _horizontal_lines;
            break;
        }
        case 1:
        {
            dedup_horizontals( _horizontal_lines, _gray);
            break;
        }
//        case 2:
//        {
//            //filter_lines( _horizontal_lines);
//            break;
//        }
        case 2:
        {
            const double y_thresh = CROPSIZE / 4.0; // 3.5; // 3.0; // 2.0; //4.0;
            fix_horizontal_lines( _horizontal_lines, all_horiz_lines, _gray, y_thresh);
            break;
        }
        default:
            NSLog( @"f03_horiz_lines(): bad state %d", state);
            return;
    } // switch
} // f05_horiz_lines()

// Debug wrapper for f05_horiz_lines
//--------------------------------------
- (UIImage *) f05_horiz_lines_dbg
{
    static int state = 0;
    if (!SZ(_horizontal_lines)) state = 0;
    cv::Mat drawing;
    switch (state) {
        case 0:
        {
            g_app.mainVC.lbBottom.text = @"Find horizontals";
            [self f05_horiz_lines:state];
            break;
        }
        case 1:
        {
            g_app.mainVC.lbBottom.text = @"Remove duplicates";
            [self f05_horiz_lines:state];
            break;
        }
//        case 2:
//        {
//            g_app.mainVC.lbBottom.text = @"Filter";
//            [self f05_horiz_lines:2];
//            break;
//        }
        case 2:
        {
            g_app.mainVC.lbBottom.text = @"Generate";
            [self f05_horiz_lines:state];
            break;
        }
        default:
            state = 0;
            return NULL;
    } // switch
    state++;
    
    // Show results
    cv::cvtColor( _gray, drawing, cv::COLOR_GRAY2RGB);
    get_color( true);
    ISLOOP (_horizontal_lines) {
        cv::Scalar col = get_color();
        draw_polar_line( _horizontal_lines[i], drawing, col);
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f05_horiz_lines_dbg()


// Find the corners
//----------------------------
- (void) f06_corners
{
    //NSLog(@"f06");
    _intersections = get_intersections( _horizontal_lines, _vertical_lines);
    _corners.clear();
    cv::Mat boardness;
    do {
        if (SZ( _horizontal_lines) > 55) break;
        if (SZ( _horizontal_lines) < 5) break;
        if (SZ( _vertical_lines) > 55) break;
        if (SZ( _vertical_lines) < 5) break;
        // Get boardness per pixel
        [self nn_boardness:_small_img dst:boardness];
        // Corners maximize boardness
        _corners = find_corners_from_score( _horizontal_lines, _vertical_lines, _intersections, boardness);
        // Intersections for only the board lines
        _intersections = get_intersections( _horizontal_lines, _vertical_lines);
    } while(0);
} // f06_corners()

// Debug wrapper for f06_corners
//--------------------------------
- (UIImage *) f06_corners_dbg
{
    g_app.mainVC.lbBottom.text = @"Find corners";
    [self f06_corners];
    cv::Mat disp = _small_img.clone();
    if (SZ( _corners) == 4) {
        int rad = 3;
        draw_point( _corners[0], disp, rad, cv::Scalar(255,0,0));
        draw_point( _corners[1], disp, rad, cv::Scalar(255,0,0));
        draw_point( _corners[2], disp, rad, cv::Scalar(255,0,0));
        draw_point( _corners[3], disp, rad, cv::Scalar(255,0,0));
    }
    UIImage *res = MatToUIImage( disp);
    return res;
} // f06_corners_dbg()

// Zoom in
//----------------------------
- (void) f07_zoom_in
{
    NSLog(@"f07");
    cv::Mat threshed;
    cv::Mat dst;
    if (SZ(_corners) == 4) {
        cv::Size sz( _orig_small.cols, _orig_small.rows);
        cv::Mat M;
        zoom_in( _corners, M);
        cv::perspectiveTransform( _corners, _corners_zoomed, M);
        cv::perspectiveTransform( _intersections, _intersections_zoomed, M);
        // Do the image zoom directly from source, to reduce loss through repeated transforms
        Points2f orig_corners;
        unwarp_points( _invProj, _invRot, _invMd, _corners, orig_corners);
        M = cv::getPerspectiveTransform( orig_corners, _corners_zoomed);
        cv::warpPerspective( _orig_small, _small_zoomed, M, sz);
        cv::cvtColor( _small_zoomed, _gray_zoomed, cv::COLOR_RGB2GRAY);
    }
} // f07_zoom_in()

// Debug wrapper for f07_zoom_in
//--------------------------------
- (UIImage *) f07_zoom_in_dbg
{
    g_app.mainVC.lbBottom.text = @"Perspective transform";
    [self f07_zoom_in];
    cv::Mat drawing = _small_zoomed.clone();
    ISLOOP (_intersections_zoomed) {
        Point2f p = _intersections_zoomed[i];
        draw_square( p, 3, drawing, cv::Scalar(255,0,0));
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f07_zoom_in_dbg()

// Classify intersections into black, white, empty
//-----------------------------------------------------------
- (void) f08_classify
{
    NSLog(@"f08");
    if (_small_zoomed.rows > 0) {
        [self nn_classify_intersections];
    }
    NSLog(@"f08 after classify");
    Points2f orig_intersections;
    unwarp_points( _invProj, _invRot, _invMd, _intersections, orig_intersections);
    NSLog(@"f08 after unwarp");
    fix_diagram( _diagram, orig_intersections, _orig_small); //_small_img);
    NSLog(@"f08 after fix");
} // f08_classify()

// Debug wrapper for f08_classify
//---------------------------------------
- (UIImage *) f08_classify_dbg
{
    g_app.mainVC.lbBottom.text = @"Classify";
    if (SZ(_corners_zoomed) != 4) { return MatToUIImage( _gray); }
    [self f08_classify];

    cv::Mat drawing;
    //cv::cvtColor( _gray_zoomed, drawing, cv::COLOR_GRAY2RGB);
    drawing = _small_zoomed.clone();
    
    Points2f dummy;
    double dxd, dyd;
    get_intersections_from_corners( _corners_zoomed, BOARD_SZ, dummy, dxd, dyd);
    //int dx = ROUND( dxd/4.0);
    //int dy = ROUND( dyd/4.0);
    ISLOOP (_diagram) {
        cv::Point p(ROUND(_intersections_zoomed[i].x), ROUND(_intersections_zoomed[i].y));
//        cv::Rect rect( p.x - dx,
//                      p.y - dy,
//                      2*dx + 1,
//                      2*dy + 1);
//        cv::rectangle( drawing, rect, cv::Scalar(0,0,255,255));
        if (_diagram[i] == BBLACK) {
            draw_point( p, drawing, 2, cv::Scalar(0,255,0,255));
        }
        else if (_diagram[i] == WWHITE) {
            draw_point( p, drawing, 3, cv::Scalar(255,0,0,255));
        }
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f08_classify_dbg()

// Try to score the detected diagram.
// Returns the number of Black points.
// All others are White.
// Populates _terrmap, _bpoints, _surepoints.
// Called from SaveDiscardVC.
//---------------------------------------------------
- (void) f09_score:(int)turn // in
           bpoints:(int *)bpoints // out
        surepoints:(int *)surepoints
           terrmap:(char**)terrmap 
{
    NSLog( @"f09 %d", (int)_diagram.size());
    int pos[BOARD_SZ * BOARD_SZ];
    ILOOP(BOARD_SZ * BOARD_SZ) {
        // The model thinks bottom to top. Mirror.
        int newidx = (BOARD_SZ - 1 - i/BOARD_SZ) * BOARD_SZ + i % BOARD_SZ;
        pos[newidx] = _diagram[i];
    }
    double *wprobs = [_scoreModel nnScorePos:pos turn:turn];
//    *surepoints = 0;
//    ILOOP(BOARD_SZ*BOARD_SZ) {
//        if (wprobs[i] < 1.0 / 20.0 || wprobs[i] > 19.0 / 20.0) { *surepoints += 1; }
//    }
    Scoring scoring;
    auto [wwpoints, bbpoints, dame] = scoring.score( pos, wprobs, turn, *terrmap);
    *bpoints = bbpoints;
    *surepoints = BOARD_SZ * BOARD_SZ - dame;
} // f09_score()

// Debug wrapper for f09_score
//---------------------------------------
- (UIImage *) f09_score_dbg
{
    g_app.mainVC.lbBottom.text = @"";
    char *terrmap;
    int bpoints, surepoints;
    NSString *sgf = [self get_sgf];
    [self f09_score:BBLACK bpoints:&bpoints surepoints:&surepoints terrmap:&terrmap];
    UIImage *scoreImg = [CppInterface scoreimg:sgf terrmap:terrmap];
    NSString *winner = @"B";
    if (bpoints < BOARD_SZ * BOARD_SZ / 2) { winner = @"W"; }
    g_app.mainVC.lbBottom.text = nsprintf( @"B:%d W:%d", bpoints, BOARD_SZ*BOARD_SZ - bpoints);
    return scoreImg;
} // f09_score_dbg()

//=== Production Flow ===
//=======================

// Try to find the board and the intersections.
// Return true on success.
//---------------------------------------------------------------
- (bool)find_board:(cv::Mat)small_img breakIfBad:(bool)breakIfBad
{
    bool success = false;
    do {
        _orig_small = small_img;
        [self f00_dots_and_verticals];
        if (breakIfBad && SZ( _vertical_lines) < 5) break;
        if (breakIfBad && SZ( _horizontal_lines) < 5) break;
        [self f02_warp];
        [self f03_houghlines];
        if (breakIfBad && SZ(_stone_or_empty) < 0.5 * SQR(BOARD_SZ)) break;
        [self f04_vert_lines:0];
        [self f04_vert_lines:1];
        [self f04_vert_lines:2];
        //[self f04_vert_lines:3];
        if (breakIfBad && SZ( _vertical_lines) > 55) break;
        if (breakIfBad && SZ( _vertical_lines) < 5) break;
        [self f05_horiz_lines:0];
        [self f05_horiz_lines:1];
        [self f05_horiz_lines:2];
        //[self f05_horiz_lines:3];
        if (breakIfBad && SZ( _horizontal_lines) > 55) break;
        if (breakIfBad && SZ( _horizontal_lines) < 5) break;
        [self f06_corners];
        success = true;
    } while(0);
    return success;
} // find_board()

// Recognize position in image. Result goes into _diagram.
// Returns true on success.
//---------------------------------------------------------------------------
- (bool)recognize_position:(cv::Mat)small_img breakIfBad:(bool)breakIfBad
{
    bool success = false;
    _diagram = std::vector<int> ( BOARD_SZ * BOARD_SZ, EEMPTY);
    do {
        success = [self find_board:small_img breakIfBad:breakIfBad];
        if (breakIfBad && !success) break;
        [self f07_zoom_in];
        [self f08_classify];
        success = true;
    } while(0);
    return success;
} // recognize_position()

// In video mode, draw the detected board on the image
// for every frame.
//--------------------------------------------------------
- (UIImage *) video_mode
{
    cv::Mat _small_img = _imgQ.back().clone();
    bool success = [self find_board:_small_img breakIfBad:YES];

    // Draw real time results on screen
    //------------------------------------
    cv::Mat canvas;
    canvas = _orig_small;
    
    if (success) {
        Points2f my_corners, my_intersections;
        unwarp_points( _invProj, _invRot, _invMd, _corners, my_corners);
        unwarp_points( _invProj, _invRot, _invMd, _intersections, my_intersections);
        if (SZ(my_corners) == 4) {
            draw_line( cv::Vec4f( my_corners[0].x, my_corners[0].y, my_corners[1].x, my_corners[1].y),
                      canvas, cv::Scalar( 255,0,0,255));
            draw_line( cv::Vec4f( my_corners[1].x, my_corners[1].y, my_corners[2].x, my_corners[2].y),
                      canvas, cv::Scalar( 255,0,0,255));
            draw_line( cv::Vec4f( my_corners[2].x, my_corners[2].y, my_corners[3].x, my_corners[3].y),
                      canvas, cv::Scalar( 255,0,0,255));
            draw_line( cv::Vec4f( my_corners[3].x, my_corners[3].y, my_corners[0].x, my_corners[0].y),
                      canvas, cv::Scalar( 255,0,0,255));
            
            ISLOOP (my_intersections) {
                draw_point( my_intersections[i], canvas, 2, cv::Scalar(0,0,255,255));
            }
        } // if (SZ(my_corners) == 4)
    }
    
    UIImage *res = MatToUIImage( canvas);
    return res;
} // video_mode()

// Find the best frame in the queue and process it.
// Called when the camera button is pressed.
//----------------------------------------------------
- (UIImage *) get_best_frame
{
    // Pick best frame from Q
    cv::Mat best;
    //Points2f bestCorners;
    int maxBlobs = -1E9;
    //int bestidx = -1;
    ILOOP (SZ(_imgQ)) { 
        _small_img = _imgQ[i];
        cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
        thresh_dilate( _gray, _gray_threshed, 10);
        _stone_or_empty.clear();
        BlobFinder::find_empty_places( _gray_threshed, _stone_or_empty); // has to be first
        BlobFinder::find_stones( _gray, _stone_or_empty);
        //_stone_or_empty = BlobFinder::clean( _stone_or_empty);
        if (SZ(_stone_or_empty) > maxBlobs) {
            maxBlobs = SZ(_stone_or_empty);
            best = _small_img;
            //bestCorners = _corners;
            //bestidx = i;
        }
    }
    UIImage *img = MatToUIImage( best);
    //[self recognize_position:best breakIfBad:NO];
    NSLog( @"recpos");
    [self recognize_position:best breakIfBad:YES];
    return img;
} // get_best_frame()


//=== Neural Network CoreML interface ===
//=======================================

// Make an MLMultiArray from a 3 channel cv::Mat with values 0..255
// cvMat will be converted to double and scaled to [-1,1]
// memId is a string used to find and reuse previously allocated memory.
// Same memId, same memory. Allocated only once, never released.
//------------------------------------------------------------------------------
- (MLMultiArray *) MultiArrayFromCVMat:(cv::Mat)cvMat memId:(NSString *)memId
{
    // Get target memory
    static NSMutableDictionary *memDict = [NSMutableDictionary new];
    if (memDict[memId] == nil) {
        int size = 3 * cvMat.rows * cvMat.cols * sizeof(double);
        size *= 2; // paranoia
        void *mem = malloc(size);
        memDict[memId] = [NSValue valueWithPointer:mem];
    }
    void *mem = [memDict[memId] pointerValue];

    // Split and normalize
    cv::Mat channels[3];
    cv::split( cvMat, channels);
    channels[0].convertTo( channels[0], CV_64FC1);
    channels[0] -= 128.0; channels[0] /= 128.0;
    channels[1].convertTo( channels[1], CV_64FC1);
    channels[1] -= 128.0; channels[1] /= 128.0;
    channels[2].convertTo( channels[2], CV_64FC1);
    channels[2] -= 128.0; channels[2] /= 128.0;
    
    // Make MLMultiArray
    NSArray *shape = @[@(3), @(cvMat.rows), @(cvMat.cols)];
    NSArray *strides = @[@(cvMat.cols*cvMat.rows), @(cvMat.cols), @(1)];
    MLMultiArray *res = [[MLMultiArray alloc] initWithDataPointer:mem
                                                            shape:shape
                                                         dataType:MLMultiArrayDataTypeDouble
                                                          strides:strides
                                                      deallocator:^(void * _Nonnull bytes) {}
                                                            error:nil];
    ILOOP(3) {
        memcpy( (double*)mem + i * cvMat.cols*cvMat.rows,
               channels[i].ptr<double>(0),
               sizeof(double) * cvMat.cols*cvMat.rows);
    }
    return res;
} // MultiArrayFromCVMat()

// Get one channel out of a MultiArray into a single channel float32 cv::Mat
//----------------------------------------------------------------------------------------
- (void) CVMatFromMultiArray:(MLMultiArray *)src channel:(int)channel dst:(cv::Mat &)dst
{
    int rows = [src.shape[1] intValue];
    int cols = [src.shape[2] intValue];
    int offset = rows*cols*sizeof(double) * channel;
    void *data = src.dataPointer;
    dst = cv::Mat( rows, cols, CV_64FC1, (char*)data + offset);
    dst.convertTo( dst, CV_32FC1);
} // CVMatFromMultiArray()

// Classify intersections with Keras Model
//--------------------------------------------
- (UIImage *) nn_classify_intersections
{
    UIImage *res;
    int r = CROPSIZE/2;

    std::vector<int> diagram( SZ(_intersections_zoomed), EEMPTY);
    ILOOP( _intersections_zoomed.size())
    {
        int x = _intersections_zoomed[i].x;
        int y = _intersections_zoomed[i].y;
        int clazz = EEMPTY;
        cv::Rect rect( x - r, y - r, 2*r+1, 2*r+1 );
        if (0 <= rect.x &&
            0 <= rect.width &&
            rect.x + rect.width <= _small_zoomed.cols &&
            0 <= rect.y &&
            0 <= rect.height &&
            rect.y + rect.height <= _small_zoomed.rows)
        {
            MLMultiArray *nn_bew_input = [self MultiArrayFromCVMat:_small_zoomed( rect) memId:@"bew_input"];
            clazz = [_stoneModel classify:nn_bew_input];
            diagram[i] = clazz;
        }
    } // ILOOP
    _diagram = diagram;
    return res;
} // nn_classify_intersections()

// Compute an image giving on-board probability per pixel.
// Use a convolutional network to do that.
//--------------------------------------------------------------
- (void) nn_boardness: (const cv::Mat&)src dst:(cv::Mat&)dst
{
    // Rescale img to 350x466
    cv::Mat src_resized;
    resize_transform( src, src_resized, IMG_WIDTH, IMG_HEIGHT);
    //  Feed it to the model
    MLMultiArray *nn_io_input = [self MultiArrayFromCVMat:src_resized memId:@"io_input"];
    MLMultiArray *featMap = [_boardModel featureMap:nn_io_input];
    // Back to cv::Mat
    cv::Mat feat_on, feat_off, feat;
    [self CVMatFromMultiArray:featMap channel:0 dst:feat_on];
    [self CVMatFromMultiArray:featMap channel:1 dst:feat_off];
    feat = feat_on - feat_off;
    //feat = feat_on; // prob to be inside the board
    // Scale to [0..255]
    double mmin, mmax;
    cv::minMaxLoc( feat, &mmin, &mmax);
    feat -= mmin;
    feat *= 255.0 / (mmax - mmin);
    // Resize to original size
    resize_transform( feat, dst, src.cols, src.rows);
    // Back to uint8
    dst.convertTo( dst, CV_8UC1);
} // nn_boardness()

//=== Sgf ===
//===========

// Save current diagram to file as sgf
//------------------------------------------------------------------------
- (void) save_current_sgf:(NSString *)fname overwrite:(bool)overwrite
{
    Points2f unwarped_intersections;
    unwarp_points( _invProj, _invRot, _invMd, _intersections, unwarped_intersections);
    std::string sgf_ = generate_sgf( "", _diagram, unwarped_intersections, _phi, _theta);
    NSString *sgf = [NSString stringWithUTF8String:sgf_.c_str()];
    
    NSString *oldsgf = [NSString stringWithContentsOfFile:fname encoding:NSUTF8StringEncoding error:NULL];
    // Just use the new GC tag, keep the old sgf
    if (oldsgf && !overwrite) {
        NSString *gc = [CppInterface get_sgf_tag:@"GC" sgf:sgf];
        sgf = [CppInterface set_sgf_tag:@"GC" sgf:oldsgf val:gc];
    }
    NSError *error;
    [sgf writeToFile:fname
          atomically:YES encoding:NSUTF8StringEncoding error:&error];
} // save_current_sgf()

// Get current diagram as sgf
//-----------------------------
- (NSString *) get_sgf
{
    Points2f unwarped_intersections;
    unwarp_points( _invProj, _invRot, _invMd, _intersections, unwarped_intersections);
    return @(generate_sgf( "", _diagram, unwarped_intersections, _phi, _theta).c_str());
} // get_sgf()

// Convert current diagram to a sequence of moves I can feed to a bot
//---------------------------------------------------------------------
- (NSArray *) get_bot_moves:(int)turn handicap:(int)handicap
{
    if (handicap == 0) { handicap = 1; }
    auto colchars = "ABCDEFGHJKLMNOPQRST";
    std::vector<std::string> wmoves;
    std::vector<std::string> bmoves;
    ISLOOP (_diagram) {
        int row = i / BOARD_SZ;
        int col = i % BOARD_SZ;
        char buf[10];
        sprintf( buf, "%c%d", colchars[col], BOARD_SZ-row);
        std::string movestr = buf;
        if (_diagram[i] == WWHITE) { wmoves.push_back( movestr); }
        else if (_diagram[i] == BBLACK) { bmoves.push_back( movestr); }
        else continue;
    }
    auto blen = SZ(bmoves); auto wlen = SZ(wmoves) + handicap - 1;
    auto maxlen = std::max( blen, wlen);
    NSMutableArray *res = [NSMutableArray new];
    int i_white = 0;
    ILOOP (maxlen) {
        i_white = i - handicap + 1; // Games starts with black handi stones and white passes
        if (i < blen) {
            [res addObject: @(bmoves[i].c_str())];
        } else {
            [res addObject: @("pass")];
        }
        if (i_white >= 0 && i_white < wlen) {
            [res addObject: @(wmoves[i_white].c_str())];
        }
        else {
            [res addObject: @("pass")];
        }
    } // ILOOP
    auto last_played = ([res count] % 2) ? BBLACK : WWHITE;
    if (last_played == turn) {
        [res addObject: @("pass")];
    }
    return res;
} // get_bot_moves()

// Get sgf for a UIImage
//-----------------------------------------------
- (NSString *) get_sgf_for_img: (UIImage *)img
{
    [self clearImgQ];
    [self qImg:img];
    [self get_best_frame];
    NSString *sgf = [self get_sgf];
    return sgf;
} // get_sgf_for_img()

// Get an empty sgf
//-------------------------
- (NSString *) empty_sgf
{
    return @(generate_sgf( "").c_str());
} // empty_sgf()

// Convert sgf string to UIImage
//----------------------------------------
+ (UIImage *) sgf2img:(NSString *)sgf
{
    if (!sgf) sgf = @"";
    cv::Mat m;
    draw_sgf( [sgf UTF8String], m, 1.5 * IMG_WIDTH);
    UIImage *res = MatToUIImage( m);
    return res;
} // sgf2img()

// Convert sgf + next move to UIImage
//----------------------------------------------------------------------------------------------------------
+ (UIImage *) nextmove2img:(NSString *)sgf coord:(NSString *)coord color:(int)color terrmap:(char *)terrmap
{
    if (!sgf) sgf = @"";
    cv::Mat m;
    draw_sgf( [sgf UTF8String], m,  1.5 * IMG_WIDTH);
    if (terrmap) { draw_score( m, terrmap); }
    draw_next_move( [coord UTF8String], color, m);
    UIImage *res = MatToUIImage( m);
    return res;
} // nextmove2img()

// Draw sgf and territory map
//----------------------------------------------------------------
+ (UIImage *) scoreimg:(NSString *)sgf terrmap:(char *)terrmap
{
    if (!sgf) sgf = @"";
    cv::Mat m;
    draw_sgf( [sgf UTF8String], m, 1.5 * IMG_WIDTH);
    draw_score( m, terrmap);
    UIImage *res = MatToUIImage( m);
    return res;
} // scoreimg()

//-----------------------------------------------------------------
+ (NSString *) get_sgf_tag:(NSString *)tag_ sgf:(NSString *)sgf_
{
    std::string sgf = [sgf_ UTF8String];
    std::string tag = [tag_ UTF8String];
    std::string val = get_sgf_tag( sgf, tag);
    // Remove backslashes
    std::regex re_back( "\\\\");
    val = std::regex_replace( val, re_back, "" );
    return [NSString stringWithUTF8String:val.c_str()];
} // get_sgf_tag()

//-------------------------------------------------------------------------------------
+ (NSString *) set_sgf_tag:(NSString *)tag_ sgf:(NSString *)sgf_ val:(NSString *)val_
{
    std::string sgf = [sgf_ UTF8String];
    std::string tag = [tag_ UTF8String];
    std::string val = [val_ UTF8String];
    std::string res = set_sgf_tag( sgf, tag, val);
    // Remove backslashes
    std::regex re_back( "\\\\");
    res = std::regex_replace( res, re_back, "" );
    return [NSString stringWithUTF8String:res.c_str()];
} // set_sgf_tag()


@end





























