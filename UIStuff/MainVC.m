//
//  MainVC.m
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


#import "MainVC.h"
#import "UIViewController+LGSideMenuController.h"

#import "Globals.h"
#import "CppInterface.h"

//==========================
@interface MainVC ()
@property UIImageView *cameraView;
// Data
@property UIImage *img; // The current image

@property UIImage *imgVideoBtn;
@property UIImage *imgPhotoBtn;

// State
@property int debugstate;
@end

//=========================
@implementation MainVC

//----------------
- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Kifu Cam";
        self.view.backgroundColor = BGCOLOR;
        self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Menu"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(showLeftView)];
    }
    return self;
} // init()

//----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.frameExtractor = [FrameExtractor new];
    self.cppInterface = [CppInterface new];
    self.frameExtractor.delegate = self;
    //self.frame_grabber_on = YES;
    self.debugstate = 0;
}

//----------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// Allocate UI elements.
//----------------------------------------------------------------------
- (void) loadView
{
    self.view = [UIView new];
    UIView *v = self.view;
    v.autoresizesSubviews = NO;
    v.opaque = YES;
    v.backgroundColor = BGCOLOR;

    // Camera View
    self.cameraView = [UIImageView new];
    self.cameraView.contentMode = UIViewContentModeScaleAspectFit;
    [v addSubview:self.cameraView];
    
    // Label for various info
    UILabel *l = [UILabel new];
    l.hidden = false;
    l.text = @"";
    l.backgroundColor = BGCOLOR;
    [v addSubview:l];
    self.lbBottom = l;
    
    // Small label for numbers and such
    UILabel *sl = [UILabel new];
    sl.hidden = false;
    sl.text = @"";
    sl.backgroundColor = BGCOLOR;
    [v addSubview:sl];
    self.lbSmall = sl;
    
//    // Debug slider
//    UISlider *s = [UISlider new];
//    self.sldDbg = s;
//    s.minimumValue = 0;
//    s.maximumValue = 16;
//    [s addTarget:self action:@selector(sldDbg:) forControlEvents:UIControlEventValueChanged];
//    s.backgroundColor = RGB (0xf0f0f0);
//    [v addSubview:s];
//    self.sldDbg.hidden = false;
    
    // Button for video or image
    self.btnCam = [self addButtonWithTitle:@"" callback:@selector(btnCam:)];
    self.imgPhotoBtn = [UIImage imageNamed:@"photo_icon.png"];
    self.imgVideoBtn = [UIImage imageNamed:@"video_icon.png"];
    [self.btnCam setBackgroundImage:self.imgVideoBtn forState:UIControlStateNormal];
    self.lbBottom.text = @"Point the camera at a Go board";
} // loadView()

//------------------------------------------
- (void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear: animated];
    [self doLayout];
}

//-----------------------------------------
- (void) viewDidAppear:(BOOL) animated
{
    [super viewDidAppear: animated];
    [self.frameExtractor resume];
}

//-----------------------------------------
- (void) viewWillDisappear:(BOOL) animated
{
    [self.frameExtractor suspend];
}

//-------------------------------
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Layout
//=========

// Put UI elements into the right place
//----------------------------------------
- (void) doLayout
{
    //float W = SCREEN_WIDTH;
    float H = SCREEN_HEIGHT;
    UIView *v = self.view;
    CGRect bounds = v.bounds;
    bounds.origin.y = g_app.navVC.navigationBar.frame.size.height;
    bounds.size.height = H - bounds.origin.y;
    v.bounds = bounds;

    CGRect camFrame = v.bounds;
    camFrame.origin.y = 0.12 * H; // 2 * g_app.navVC.navigationBar.frame.size.height;
    camFrame.size.height = 0.85 * H;
    self.cameraView.frame = camFrame;
    self.cameraView.hidden = NO;
    //int bottomOfCam = camFrame.origin.y + camFrame.size.height;

    // Camera button
    [self.btnCam setBackgroundImage:self.imgPhotoBtn forState:UIControlStateNormal];
    if ([g_app.menuVC videoMode]) {
        [self.btnCam setBackgroundImage:self.imgVideoBtn forState:UIControlStateNormal];
    }
    // Info Label
    self.lbBottom.textAlignment = NSTextAlignmentCenter;

    // Small Label
    self.lbSmall.textAlignment = NSTextAlignmentLeft;
    
    [self.view setNeedsDisplay];
} // doLayout

// Position camera button and labels when first image comes in.
// We don't know the image size until we get one.
//---------------------------------------------------------------
- (void) positionButtonAndLabels
{
    static bool called = false;
    if (called) return;
    called = true;
    
    // Get lower edge of image
    float W = self.view.frame.size.width;
    float H = self.view.frame.size.height;
    CGRect imgRect = AVMakeRectWithAspectRatioInsideRect(_cameraView.image.size, _cameraView.bounds);
    int bottomOfImg = _cameraView.frame.origin.y + imgRect.origin.y + imgRect.size.height;
    
    // Position camera button
    int r = 70;
    self.btnCam.frame = CGRectMake( W/2 - r/2, bottomOfImg - 1.1 * r, r , r);
    CALayer *layer = self.btnCam.layer;
    layer.backgroundColor = [[UIColor clearColor] CGColor];
    layer.borderColor = [[UIColor clearColor] CGColor];
    
    // Info label
    int lbHeight = 55;
    int lbY = bottomOfImg + (H - bottomOfImg)/2.0;
    self.lbBottom.frame = CGRectMake( 0, lbY, W , lbHeight);
    
    // Small label
    int slbHeight = 35;
    self.lbSmall.frame = CGRectMake( W/100, bottomOfImg, W/3 , slbHeight);
    
} // showCameraButton

//---------------------------------------------------
- (UIButton*) addButtonWithTitle: (NSString *) title
                        callback: (SEL) callback
{
    UIView *parent = self.view;
    id target = self;
    
    UIButton *b = [[UIButton alloc] init];
    [b.layer setBorderWidth:1.0];
    [b.layer setBorderColor:[RGB (0x202020) CGColor]];
    b.backgroundColor = RGB (0xf0f0f0);
    b.frame = CGRectMake(0, 0, 72, 44);
    [b setTitle: title forState: UIControlStateNormal];
    [b setTitleColor: WHITE forState: UIControlStateNormal];
    [b addTarget:target action:callback forControlEvents: UIControlEventTouchUpInside];
    [parent addSubview: b];
    return b;
} // addButtonWithTitle

// Button etc callbacks
//=========================

// Tapping on the screen
//----------------------------------------------------------------
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if ([g_app.menuVC debugMode]) {
        [self debugFlow:false];
    }
    if ([g_app.menuVC demoMode]) {
        [self debugFlow:false];
    }
    else if ([g_app.menuVC videoMode]) {
        [self btnCam:nil];
    }
} // touchesBegan()

//// Slider for Debugging
////-----------------------------------
//- (void) sldDbg:(id) sender
//{
//    int tt = [self.sldDbg value];
//    self.lbDbg.text = nsprintf( @"%d", tt);
//}

//----------------------
- (void) processImgQ
{
    g_app.saveDiscardVC.photo = [_cppInterface photo_mode];
    g_app.saveDiscardVC.sgf = [g_app.mainVC.cppInterface get_sgf];
    [g_app.navVC pushViewController:g_app.saveDiscardVC animated:YES];
}

// Process one image, e.g. from photo import
//---------------------------------------------
- (void) processImg:(UIImage*)img
{
    [self.frameExtractor suspend];
    [_cppInterface clearImgQ];
    [_cppInterface qImg:img];
    [self processImgQ];
} // processImg()

// Camera button press
//-----------------------------
- (void) btnCam:(id)sender
{
    if ([g_app.menuVC photoMode] || [g_app.menuVC videoMode]) {
        [self.frameExtractor suspend];
        [self processImgQ];
    }
    // Enable debug menu on the right if trigger position seen
    if ([_cppInterface check_debug_trigger]) {
        [g_app enableDebugMenu];
    }
} // btnCam

// FrameExtractorDelegate protocol
//=====================================

// Called on each video frame. Behave differently depending on active mode.
//---------------------------------------------------------------------------
- (void)captured:(UIImage *)image
{
    if ([g_app.menuVC debugMode]) {
        //self.frame_grabber_on = NO;
        [self.frameExtractor suspend];
        return;
    } // debugMode
    else if ([g_app.menuVC photoMode]) {
        [self.frameExtractor suspend];
        [self.cameraView setImage:image];
        _img = image;
        [_cppInterface qImg:_img];
        [self.frameExtractor resume];
    } // photoMode
    else if ([g_app.menuVC videoMode]) {
        [self.frameExtractor suspend];
        _img = image;
        [_cppInterface qImg:_img];
        UIImage *processedImg = [self.cppInterface video_mode];
        self.img = processedImg;
        [self.cameraView setImage:self.img];
        if (self.view.window) {
            [self.frameExtractor resume];
        }
    } // videoMode
    [self positionButtonAndLabels];
} // captured()

// LGSideMenuController Callbacks
//==================================

//---------------------
- (void)showLeftView
{
    [self.sideMenuController showLeftViewAnimated:YES completionHandler:nil];
}

//------------------------
- (void)showRightView
{
    [self.sideMenuController showRightViewAnimated:YES completionHandler:nil];
}

// Other
//============


// Demo mode and debugging helper to show individual processing stages.
// Called when entering demo mode, and in secret debug mode.
//---------------------------------------------------------------------
- (void) debugFlow:(bool)reset
{
    if (reset) _debugstate = 0;
    UIImage *img;
    while(1) {
        switch (_debugstate) {
            case 0:
                _debugstate=2;
                [self.frameExtractor suspend];
                img = [self.cppInterface f00_dots_and_verticals_dbg];
                [self.cameraView setImage:img];
                break;
            case 1:
                _debugstate++;
                //img = [self.cppInterface f02_warp_dbg];
                [self.cameraView setImage:img];
                break;
            case 2:
                _debugstate++;
                img = [self.cppInterface f02_warp_dbg];
                [self.cameraView setImage:img];
                break;
            case 3:
                _debugstate++;
                img = [self.cppInterface f03_houghlines_dbg];
                [self.cameraView setImage:img];
                break;
            case 4:
                img = [self.cppInterface f04_vert_lines_dbg];
                if (!img) { _debugstate++; continue; }
                [self.cameraView setImage:img];
                break;
            case 5:
                img = [self.cppInterface f05_horiz_lines_dbg];
                if (!img) { _debugstate++; continue; }
                [self.cameraView setImage:img];
                break;
            case 6:
                _debugstate++;
                img = [self.cppInterface f06_corners_dbg];
                [self.cameraView setImage:img];
                break;
            case 7:
                _debugstate++;
                img = [self.cppInterface f07_zoom_in_dbg];
                [self.cameraView setImage:img];
                break;
            case 8:
                _debugstate++;
                img = [self.cppInterface f08_classify_dbg];
                [self.cameraView setImage:img];
                break;
            default:
                _debugstate=0;
                continue;
        } // switch
        break;
    } // while(1)
} // debugFlow()


@end
