//
//  MainVC.h
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


#import "Common.h"
#import "CppInterface.h"
#import "FrameExtractor.h"
#import "UIViewController+LGSideMenuController.h"

@interface MainVC : UIViewController <FrameExtractorDelegate>
// Entry point to core app functionality.
@property CppInterface *cppInterface;
// The frame extractor dealing with all things video
@property FrameExtractor *frameExtractor;

// Text label for various information
@property UILabel *lbBottom;
// Small label for numbers and such
@property UILabel *lbSmall;
// Camera button
@property UIButton *btnCam;


// Slider for test purposes
//@property UISlider *sldDbg;

// Other
//=======
// Redraw main screen
- (void) doLayout;
// Debugging helper, shows individual processing stages
- (void) debugFlow:(bool)reset;
// Process image and go to SaveDiscardVC
- (void) processImg:(UIImage*)img;

@end
