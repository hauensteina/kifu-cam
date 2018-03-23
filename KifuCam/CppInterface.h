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

@interface CppInterface : NSObject

// Individual steps for debugging
//---------------------------------
- (UIImage *) f00_dots_and_verticals_dbg;
- (UIImage *) f02_warp_dbg;
- (UIImage *) f03_blobs_dbg;
- (UIImage *) f04_vert_lines_dbg;
- (UIImage *) f05_horiz_lines_dbg;
- (UIImage *) f06_corners_dbg;
- (UIImage *) f07_zoom_in_dbg;
- (UIImage *) f08_classify_dbg;

- (UIImage *) video_mode;
- (UIImage *) photo_mode;

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

// Save the cuurently detected position to sgf
- (bool) save_current_sgf:(NSString *)fname withTitle:(NSString *)title;
// get current diagram as sgf
- (NSString *) get_sgf;

// Make a diagram from sgf
+ (UIImage *) sgf2img:(NSString *)sgf;
// Get the corner coords fom GC tag of sgf
+ (NSArray *) corners_from_sgf:(NSString *)sgf;


@end
