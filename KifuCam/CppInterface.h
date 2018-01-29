//
//  CppInterface.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-10-21.
//  Copyright © 2017 AHN. All rights reserved.
//

// This class is the only place where Objective-C and C++ mix.
// All other files are either pure Obj-C or pure C++.

#import <Foundation/Foundation.h>

@interface CppInterface : NSObject

// Individual steps for debugging
//---------------------------------
- (UIImage *) f00_blobs;
- (UIImage *) f01_vert_lines;
- (UIImage *) f02_horiz_lines;
- (UIImage *) f03_corners;
- (UIImage *) f04_zoom_in;
- (UIImage *) f05_dark_places;
- (UIImage *) f06_mask_dark;
- (UIImage *) f07_white_holes;
- (UIImage *) f08_features;
- (UIImage *) f09_classify;

- (UIImage *) video_mode:(UIImage *)img;
- (UIImage *) photo_mode;

// Methods for the Obj-C View Controllers
//=============================================
// Detect position on img and count the errors
- (int) runTestImg:(UIImage *)img withSgf:(NSString *)sgf;
// Save resized image to png. Fname must have .png extension.
- (bool) save_small_img:(NSString *)fname;
// Save the cuurently detected position to sgf
- (bool) save_current_sgf:(NSString *)fname withTitle:(NSString *)title;
// Put an image into a buffer q. We pick the best one later.
- (void) qImg:(UIImage *)img;
// Make a diagram from sgf
+ (UIImage *) sgf2img:(NSString *)sgf;
// get current diagram as sgf
- (NSString *) get_sgf;
// Get most recent video frame with a Go board
- (UIImage *) get_last_frame_with_board;


@end
