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

// This class is the only place where Objective-C and C++ mix.
// All other files are either pure Obj-C or pure C++.

// Don't change the order of these two,
// and don't move them down
#import "Ocv.hpp"
#import <opencv2/imgcodecs/ios.h>

#import "Common.h"
#import "Globals.h"
#include "Helpers.hpp"

#import "AppDelegate.h"
#import "BlobFinder.hpp"
#import "Boardness.hpp"
#import "Clust1D.hpp"
#import "CppInterface.h"
#import "KerasBoardModel.h"
#import "Perspective.hpp"

extern cv::Mat mat_dbg;

@interface CppInterface()
//=======================
@property cv::Mat invProj; // Inverse projection matrix
@property cv::Mat invRot;  // Inverse rotation matrix
@property cv::Mat small_img; // resized image, in color, RGB, unwarped
@property cv::Mat orig_small;     // orig resized
@property cv::Mat small_zoomed;  // small, zoomed into the board
@property cv::Mat gray;  // Grayscale version of small
@property cv::Mat gray_threshed;  // gray with inv_thresh and dilation
@property cv::Mat gray_zoomed;   // Grayscale version of small, zoomed into the board
@property int board_sz; // board size, 9 or 19
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

@end

@implementation CppInterface
//=========================

//----------------------
- (instancetype)init
{
    self = [super init];
    if (self) {
        g_docroot = [getFullPath(@"") UTF8String];
        // Load template files
        cv::Mat tmat;
        // The io model
        _iomodel = [nn_io new];
        _boardModel = [[KerasBoardModel alloc] initWithModel:_iomodel];
    }
    return self;
}

//=== Misc Public ===
//===================

// Queue image frames. The newest one is often shaky.
//-----------------------------------------------------
- (void)qImg:(UIImage *)img
{
    cv::Mat m;
    UIImageToMat( img, m);
    resize( m, m, IMG_WIDTH);
    cv::cvtColor( m, m, CV_RGBA2RGB);
    int keep_n_frames = 4;
    ringpush( _imgQ , m, keep_n_frames); // keep 4 frames
}

// Detect position on image and count erros
//------------------------------------------------------------
- (int) runTestImg:(UIImage *)img withSgf:(NSString *)sgf
{
    cv::Mat m;
    UIImageToMat( img, m);
    resize( m, m, IMG_WIDTH);
    cv::cvtColor( m, m, CV_RGBA2RGB);
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
    std::vector<int> templ( SQR(_board_sz), EEMPTY);
    templ[0] = BBLACK;
    templ[1] = BBLACK;
    templ[_board_sz] = BBLACK;
    templ[_board_sz+1] = BBLACK;
    bool res = templ == _diagram;
    return res;
} // check_debug_trigger()

//=== Debug Flow ===
//==================

// Make verticals parallel and really vertical
//----------------------------------------------
- (void) f00_warp
{
    _board_sz=19;
    _vertical_lines.clear();
    _horizontal_lines.clear();
    // Find Blobs
    if (_orig_small.cols != IMG_WIDTH) {
        resize( _orig_small, _orig_small, IMG_WIDTH);
    }
    const cv::Size sz( _orig_small.cols, _orig_small.rows);
    cv::cvtColor( _orig_small, _small_img, CV_RGBA2RGB);
    cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
    thresh_dilate( _gray, _gray_threshed);
    _stone_or_empty.clear();
    BlobFinder::find_empty_places( _gray_threshed, _stone_or_empty); // has to be first
    BlobFinder::find_stones( _gray, _stone_or_empty);
    _stone_or_empty = BlobFinder::clean( _stone_or_empty);
    
    // Find lines
    houghlines( _small_img, _stone_or_empty,
               _vertical_lines, _horizontal_lines);
    
    // Straighten horizontals
    float theta; cv::Mat Ms;
    straight_rotation( sz, _horizontal_lines, theta, Ms, _invRot);
    cv::warpAffine( _small_img, _small_img, Ms, sz);
    warp_plines( _vertical_lines, Ms, _vertical_lines);
    
    // Unwarp verticals
    float phi; cv::Mat Mp;
    parallel_projection( sz, _vertical_lines, phi, Mp, _invProj);
    cv::warpPerspective( _small_img, _small_img, Mp, sz);
    warp_plines( _vertical_lines, Mp, _vertical_lines);
} // f00_warp()

// Debug wrapper for f00_warp
//------------------------------------
- (UIImage *) f00_warp_dbg
{
    _board_sz=19;
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
    [self f00_warp];

    cv::Mat drawing = _small_img.clone();
    get_color(true);
    ISLOOP( _vertical_lines) {
        draw_polar_line( _vertical_lines[i], drawing, get_color());
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f00_warp()

// Roughly guess intersections, stones, and lines
//--------------------------------------------------
- (void) f01_blobs
{
    _vertical_lines.clear();
    _horizontal_lines.clear();
    cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
    thresh_dilate( _gray, _gray_threshed);
    _stone_or_empty.clear();
    BlobFinder::find_empty_places( _gray_threshed, _stone_or_empty); // has to be first
    BlobFinder::find_stones( _gray, _stone_or_empty);
    _stone_or_empty = BlobFinder::clean( _stone_or_empty);
    // Find lines
    houghlines( _small_img, _stone_or_empty,
               _vertical_lines, _horizontal_lines);
    
} // f01_blobs()

// Debug wrapper for f01_blobs
//-------------------------------
- (UIImage *) f01_blobs_dbg
{
    g_app.mainVC.lbBottom.text = @"Stones and Intersections";
    [self f01_blobs];
    
    // Show results
    cv::Mat drawing = _small_img.clone();
    draw_points( _stone_or_empty, drawing, 2, cv::Scalar( 255,0,0));
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f01_blobs_dbg()


// Find vertical grid lines
//----------------------------------
- (void) f02_vert_lines:(int)state
{
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
        case 2:
        {
            filter_lines( _vertical_lines);
            break;
        }
        case 3:
        {
            const double x_thresh = 8.0;
            fix_vertical_lines( _vertical_lines, all_vert_lines, _gray, x_thresh);
            break;
        }
        default:
            NSLog( @"f02_vert_lines(): bad state %d", state);
            return;
    } // switch
} // f02_vert_lines()

// Debug wrapper for f02_vert_lines
//-------------------------------------
- (UIImage *) f02_vert_lines_dbg
{
    static int state = 0;
    if (!SZ(_vertical_lines)) state = 0;
    cv::Mat drawing;
    
    switch (state) {
        case 0:
        {
            g_app.mainVC.lbBottom.text = @"Find verticals";
            [self f02_vert_lines:state];
            break;
        }
        case 1:
        {
            g_app.mainVC.lbBottom.text = @"Remove duplicates";
            [self f02_vert_lines:state];
            break;
        }
        case 2:
        {
            g_app.mainVC.lbBottom.text = @"Filter";
            [self f02_vert_lines:state];
            break;
        }
        case 3:
        {
            g_app.mainVC.lbBottom.text = @"Generate";
            [self f02_vert_lines:state];
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
} // f02_vert_lines_dbg()


// Find horizontal grid lines
//-----------------------------
- (void) f03_horiz_lines:(int)state
{
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
        case 2:
        {
            filter_lines( _horizontal_lines);
            break;
        }
        case 3:
        {
            const double y_thresh = 8.0;
            fix_horizontal_lines( _horizontal_lines, all_horiz_lines, _gray, y_thresh);
            break;
        }
        default:
            NSLog( @"f03_horiz_lines(): bad state %d", state);
            return;
    } // switch
} // f03_horiz_lines()

// Debug wrapper for f03_horiz_lines
//--------------------------------------
- (UIImage *) f03_horiz_lines_dbg
{
    static int state = 0;
    if (!SZ(_horizontal_lines)) state = 0;
    cv::Mat drawing;
    switch (state) {
        case 0:
        {
            g_app.mainVC.lbBottom.text = @"Find horizontals";
            [self f03_horiz_lines:0];
            break;
        }
        case 1:
        {
            g_app.mainVC.lbBottom.text = @"Remove duplicates";
            [self f03_horiz_lines:1];
            break;
        }
        case 2:
        {
            g_app.mainVC.lbBottom.text = @"Filter";
            [self f03_horiz_lines:2];
            break;
        }
        case 3:
        {
            g_app.mainVC.lbBottom.text = @"Generate";
            [self f03_horiz_lines:3];
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
} // f03_horiz_lines_dbg()


// Find the corners
//----------------------------
- (void) f04_corners
{
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
} // f04_corners()

// Debug wrapper for f04_corners
//--------------------------------
- (UIImage *) f04_corners_dbg
{
    g_app.mainVC.lbBottom.text = @"Find corners";
    [self f04_corners];
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
} // f04_corners_dbg()

// Zoom in
//----------------------------
- (void) f05_zoom_in
{
    cv::Mat threshed;
    cv::Mat dst;
    if (SZ(_corners) == 4) {
        cv::Mat M;
        zoom_in( _gray,  _corners, _gray_zoomed, M);
        zoom_in( _small_img, _corners, _small_zoomed, M);
        cv::perspectiveTransform( _corners, _corners_zoomed, M);
        cv::perspectiveTransform( _intersections, _intersections_zoomed, M);
        fill_outside_with_average_gray( _gray_zoomed, _corners_zoomed);
        fill_outside_with_average_rgb( _small_zoomed, _corners_zoomed);
    }
} // f05_zoom_in()

// Debug wrapper for f05_zoom_in
//--------------------------------
- (UIImage *) f05_zoom_in_dbg
{
    g_app.mainVC.lbBottom.text = @"Perspective transform";
    [self f05_zoom_in];
    cv::Mat drawing = _small_zoomed.clone();
    ISLOOP (_intersections_zoomed) {
        Point2f p = _intersections_zoomed[i];
        draw_square( p, 3, drawing, cv::Scalar(255,0,0));
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f05_zoom_in_dbg()

// Classify intersections into black, white, empty
//-----------------------------------------------------------
- (void) f06_classify
{
    if (_small_zoomed.rows > 0) {
        [self nn_classify_intersections];
    }
    fix_diagram( _diagram, _intersections, _small_img);
} // f06_classify()

// Debug wrapper for f06_classify
//---------------------------------------
- (UIImage *) f06_classify_dbg
{
    g_app.mainVC.lbBottom.text = @"Classify";
    if (SZ(_corners_zoomed) != 4) { return MatToUIImage( _gray); }
    [self f06_classify];

    cv::Mat drawing;
    cv::cvtColor( _gray_zoomed, drawing, cv::COLOR_GRAY2RGB);
    
    Points2f dummy;
    double dxd, dyd;
    get_intersections_from_corners( _corners_zoomed, _board_sz, dummy, dxd, dyd);
    int dx = ROUND( dxd/4.0);
    int dy = ROUND( dyd/4.0);
    ISLOOP (_diagram) {
        cv::Point p(ROUND(_intersections_zoomed[i].x), ROUND(_intersections_zoomed[i].y));
        cv::Rect rect( p.x - dx,
                      p.y - dy,
                      2*dx + 1,
                      2*dy + 1);
        cv::rectangle( drawing, rect, cv::Scalar(0,0,255,255));
        if (_diagram[i] == BBLACK) {
            draw_point( p, drawing, 2, cv::Scalar(0,255,0,255));
        }
        else if (_diagram[i] == WWHITE) {
            draw_point( p, drawing, 5, cv::Scalar(255,0,0,255));
        }
    }
    UIImage *res = MatToUIImage( drawing);
    return res;
} // f06_classify_dbg()

//=== Production Flow ===
//=======================

// Try to find the board and the intersections.
// Return true on success.
//---------------------------------------------------------------
- (bool)find_board:(cv::Mat)small_img breakIfBad:(bool)breakIfBad
{
    _board_sz = 19;
    bool success = false;
    do {
        _orig_small = small_img;
        [self f00_warp];
        [self f01_blobs];
        if (breakIfBad && SZ(_stone_or_empty) < 0.8 * SQR(_board_sz)) break;
        [self f02_vert_lines:0];
        [self f02_vert_lines:1];
        [self f02_vert_lines:2];
        [self f02_vert_lines:3];
        if (breakIfBad && SZ( _vertical_lines) > 55) break;
        if (breakIfBad && SZ( _vertical_lines) < 5) break;
        [self f03_horiz_lines:0];
        [self f03_horiz_lines:1];
        [self f03_horiz_lines:2];
        [self f03_horiz_lines:3];
        if (breakIfBad && SZ( _horizontal_lines) > 55) break;
        if (breakIfBad && SZ( _horizontal_lines) < 5) break;
        [self f04_corners];
        success = true;
    } while(0);
    return success;
} // find_board()

// Recognize position in image. Result goes into _diagram.
// Returns true on success.
//---------------------------------------------------------------------------
- (bool)recognize_position:(cv::Mat)small_img breakIfBad:(bool)breakIfBad
{
    _board_sz = 19;
    bool success = false;
    do {
        success = [self find_board:small_img breakIfBad:breakIfBad];
        if (breakIfBad && !success) break;
        [self f05_zoom_in];
        [self f06_classify];
        success = true;
    } while(0);
    return success;
} // recognize_position()

// Entry point for video mode, on each frame
//--------------------------------------------
- (UIImage *) video_mode
{
    cv::Mat _small_img = _imgQ.back().clone();
    bool success = [self find_board:_small_img breakIfBad:YES];

    // Draw real time results on screen
    //------------------------------------
    cv::Mat canvas;
    canvas = _orig_small;
    
    static std::vector<cv::Vec2f> old_hlines, old_vlines;
    static Points2f old_corners, old_intersections;
    if (!success) {
        _horizontal_lines = old_hlines;
        _vertical_lines = old_vlines;
        _corners = old_corners;
        _intersections = old_intersections;
    }
    else {
        old_hlines = _horizontal_lines;
        old_vlines = _vertical_lines;
        old_corners = _corners;
        old_intersections = _intersections;
    }
    
    Points2f my_corners, my_intersections;
    unwarp_points( _invProj, _invRot, _corners, my_corners);
    unwarp_points( _invProj, _invRot, _intersections, my_intersections);
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
    
    UIImage *res = MatToUIImage( canvas);
    return res;
} // video_mode()

// Photo Mode. Find the best frame in the queue and process it.
//--------------------------------------------------------------
- (UIImage *) photo_mode
{
    // Pick best frame from Q
    cv::Mat best;
    Points2f bestCorners;
    int maxBlobs = -1E9;
    int bestidx = -1;
    ILOOP (SZ(_imgQ) - 1) { // ignore newest frame
        _small_img = _imgQ[i];
        cv::cvtColor( _small_img, _gray, cv::COLOR_RGB2GRAY);
        thresh_dilate( _gray, _gray_threshed);
        _stone_or_empty.clear();
        BlobFinder::find_empty_places( _gray_threshed, _stone_or_empty); // has to be first
        BlobFinder::find_stones( _gray, _stone_or_empty);
        _stone_or_empty = BlobFinder::clean( _stone_or_empty);
        if (SZ(_stone_or_empty) > maxBlobs) {
            maxBlobs = SZ(_stone_or_empty);
            best = _small_img;
            bestCorners = _corners;
            bestidx = i;
        }
    }
    [self recognize_position:best breakIfBad:NO];
    UIImage *img = MatToUIImage( best);
    return img;
} // photo_mode()


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
            clazz = [g_app.stoneModel classify:nn_bew_input];
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
//-----------------------------------------------------------------------
- (bool) save_current_sgf:(NSString *)fname withTitle:(NSString *)title
{
    auto sgf = generate_sgf( [title UTF8String], _diagram, _intersections);
    std::ofstream ofs;
    ofs.open( [fname UTF8String]);
    ofs << sgf;
    ofs.close();
    return ofs.good();
}


// Get current diagram as sgf
//----------------------------------
- (NSString *) get_sgf
{
    Points2f my_intersections;
    unwarp_points(_invProj, _invRot, _intersections, my_intersections);
    return @(generate_sgf( "", _diagram, my_intersections).c_str());
}

// Convert sgf string to UIImage
//----------------------------------------
+ (UIImage *) sgf2img:(NSString *)sgf
{
    if (!sgf) sgf = @"";
    cv::Mat m;
    draw_sgf( [sgf UTF8String], m, IMG_WIDTH);
    UIImage *res = MatToUIImage( m);
    return res;
}

// Return the four corner coords as an array of 4 pairs [[x0,y0],[x1,y1],...]
// Ordered clockwise tl,tr,br,bl
//-----------------------------------------------------------------------------
+ (NSArray *) corners_from_sgf:(NSString *)sgf_
{
    std::string sgf = [sgf_ UTF8String];
    NSMutableArray *res = [NSMutableArray new];
    std::string gc = get_sgf_tag( sgf, "GC");
    std::regex re( ".*:(\\(.*\\))");
    std::string tstr = std::regex_replace( gc, re, "$1" );
    // Turn it into json
    std::regex re1( "\\(");
    tstr = std::regex_replace( tstr, re1, "[" );
    std::regex re2( "\\)");
    tstr = std::regex_replace( tstr, re2, "]" );
    // Parse it
    NSArray *points = parseJSON( @(tstr.c_str()));
    long len = [points count];
    int boardsz = 19;
    if (len == 13*13) boardsz = 13;
    else if (len == 9*9) boardsz = 9;
    [res addObject:points[0]];
    [res addObject:points[boardsz-1]];
    [res addObject:points[boardsz*boardsz-1]];
    [res addObject:points[boardsz*boardsz-boardsz]];
    return res;
} // corners_from_sgf()



@end





























