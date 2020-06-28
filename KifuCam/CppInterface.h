//
//  CppInterface.h 
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

#import <Foundation/Foundation.h>

typedef void (^CICompletionHandler)(UIImage *img);

@interface CppInterface : NSObject

// Individual steps for debugging
//---------------------------------
- (UIImage *) f00_dots_and_verticals_dbg;
- (UIImage *) f02_warp_dbg;
- (UIImage *) f03_houghlines_dbg;
- (UIImage *) f04_vert_lines_dbg;
- (UIImage *) f05_horiz_lines_dbg;
- (UIImage *) f06_corners_dbg;
- (UIImage *) f07_zoom_in_dbg;
- (UIImage *) f08_classify_dbg;
- (void) f09_score_dbg:(CICompletionHandler)completion;

- (void) f00_dots_and_verticals;
- (void) f02_warp;
- (void) f03_houghlines;
- (void) f04_vert_lines:(int)state;
- (void) f05_horiz_lines:(int)state;
- (void) f06_corners;
- (void) f07_zoom_in;

- (UIImage *) video_mode;
- (UIImage *) get_best_frame;

// Methods for the Obj-C View Controllers
//=============================================
// Detect position on img and count the errors
- (int) runTestImg:(UIImage *)img withSgf:(NSString *)sgf;
// Put an image into a buffer q. We pick the best one later.
- (void) qImg:(UIImage *)img;
// Clear the image q.
- (void) clearImgQ;

// Check for the debug mode trigger position to show right menu.
- (bool) check_debug_trigger;

// Save current diagram to file as sgf
- (void) save_current_sgf:(NSString *)fname overwrite:(bool)overwrite;
// Get current diagram as sgf
- (NSString *) get_sgf;
// Convert diagram to a sequence of bot moves
- (NSArray *) get_bot_moves:(int)turn handicap:(int)handicap;
// Get sgf for a UIImage
- (NSString *) get_sgf_for_img: (UIImage *)img;
// Get an empty sgf
- (NSString *) empty_sgf;

// Make a diagram from sgf
+ (UIImage *) sgf2img:(NSString *)sgf;
// Make a diagram with the next move
+ (UIImage *) nextmove2img:(NSString *)sgf coords:(NSArray *)coords color:(int)color terrmap:(double *)terrmap;
// Draw scoring map on sgf img
+ (UIImage *) scoreimg:(NSString *)sgf terrmap:(double *)terrmap;
// Extract an sgf tag
+ (NSString *) get_sgf_tag:(NSString *)tag sgf:(NSString *)sgf;
// Set an sgf tag. Do not try to set the SZ tag.
+ (NSString *) set_sgf_tag:(NSString *)tag sgf:(NSString *)sgf val:(NSString *)val;


@end
