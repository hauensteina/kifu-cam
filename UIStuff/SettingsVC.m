//
//  SettingsVC.m
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

#import "SettingsVC.h"
#import "Globals.h"

@interface SettingsVC ()
@property UIImage *imgChecked;
@property UIImage *imgUnChecked;

// Upload
@property UIButton *btnUploadYes;
@property UILabel *lbUploadYes;

@property UIButton *btnUploadNo;
@property UILabel *lbUploadNo;

// Photo/Video
@property UISwitch *btnShowDetectedBoard;
@property UILabel *lbShowDetectedBoard;

@end

@implementation SettingsVC
//-----------------------
- (id)init
{
    self = [super init];
    if (self) {
        //CGRect frame = self.view.bounds;
        self.title = @"Settings";
        self.view.backgroundColor = BGCOLOR;
    }
    return self;
} // init()

// Allocate UI elements.
//---------------------------
- (void) loadView
{
    self.view = [UIView new];
    UIView *v = self.view;
    v.autoresizesSubviews = NO;
    v.opaque = YES;
    v.backgroundColor = BGCOLOR;

    // Instantiate stuff
    _imgChecked = [UIImage imageNamed:@"radio_on.png"];
    _imgUnChecked = [UIImage imageNamed:@"radio_off.png"];
    //
    _btnUploadYes = [UIButton new];
    _btnUploadNo = [UIButton new];
    _lbUploadYes = [UILabel new];
    _lbUploadNo = [UILabel new];
    //
    _btnShowDetectedBoard = [UISwitch new];
    _lbShowDetectedBoard = [UILabel new];
    
    // Config upload radio button
    [_btnUploadYes setImage:_imgUnChecked forState:UIControlStateNormal];
    [_btnUploadYes setImage:_imgChecked forState:UIControlStateSelected];
    [_btnUploadNo setImage:_imgUnChecked forState:UIControlStateNormal];
    [_btnUploadNo setImage:_imgChecked forState:UIControlStateSelected];
    _lbUploadYes.text = @"Upload images to help developers";
    _lbUploadNo.text = @"I don't want to help";
    [_btnUploadYes addTarget:self action:@selector(btnUploadYes:) forControlEvents: UIControlEventTouchUpInside];
    [_btnUploadNo addTarget:self action:@selector(btnUploadNo:) forControlEvents: UIControlEventTouchUpInside];
    makeLabelClickable( _lbUploadYes, self, @selector(btnUploadYes:));
    makeLabelClickable( _lbUploadNo, self, @selector(btnUploadNo:));

    [_btnShowDetectedBoard addTarget:self action:@selector(btnShowDetectedBoard:) forControlEvents:UIControlEventValueChanged];
    _lbShowDetectedBoard.text = @"Show detected board";

    // Add controls as subviews
    [v addSubview: _btnUploadYes];
    [v addSubview: _btnUploadNo];
    [v addSubview: _lbUploadYes];
    [v addSubview: _lbUploadNo];
    //
    [v addSubview: _btnShowDetectedBoard];
    [v addSubview: _lbShowDetectedBoard];
} // loadView

//------------------------------------------
- (void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear: animated];
    [self doLayout];
}

//----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
}

 //----------------------------------------
 - (void) viewDidAppear: (BOOL) animated
 {
     [super viewDidAppear: animated];
 }

//----------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// Layout
//=========

// Put UI elements into the right place
//----------------------------------------
- (void) doLayout
{
    // Set button states accordingly
    if ([self defaultToVideo]) {
        [_btnShowDetectedBoard setOn:YES];
    }
    else {
        [_btnShowDetectedBoard setOn:NO];
    }
    if ([self uploadEnabled]) {
        _btnUploadYes.selected = YES;
        _btnUploadNo.selected = NO;
    }
    else {
        _btnUploadYes.selected = NO;
        _btnUploadNo.selected = YES;
    }

    // Layout
    float H = SCREEN_HEIGHT;
    float W = SCREEN_WIDTH;
    UIView *v = self.view;
    CGRect bounds = v.bounds;
    bounds.origin.y = g_app.navVC.navigationBar.frame.size.height;
    bounds.size.height = H - bounds.origin.y;
    v.bounds = bounds;
    
    int checkBoxSize = 30;
    float y = H * 0.3;
    int lmarg = W * 0.1;
    
    // Upload option
    _btnUploadYes.frame = CGRectMake( lmarg, y, checkBoxSize, checkBoxSize);
    _lbUploadYes.frame = CGRectMake( lmarg + checkBoxSize*1.5, y, W - lmarg, checkBoxSize);
    y += checkBoxSize * 1.5;
    _btnUploadNo.frame = CGRectMake( lmarg, y, checkBoxSize, checkBoxSize);
    _lbUploadNo.frame = CGRectMake( lmarg + checkBoxSize*1.5, y, W - lmarg, checkBoxSize);

    // Show detected board or not
    y += checkBoxSize * 3;
    _btnShowDetectedBoard.frame = CGRectMake( lmarg, y, checkBoxSize, checkBoxSize);
    _lbShowDetectedBoard.frame = CGRectMake( lmarg + checkBoxSize*2.3, y, W - lmarg, checkBoxSize);
} // doLayout()

// Button Callbacks
//====================

//--------------------------------
- (void) btnUploadYes:(id)sender
{
    _btnUploadYes.selected = YES;
    _btnUploadNo.selected = NO;
    setProp( @"opt_upload", @"yes");
} // btnUploadYes()

//-------------------------------
- (void) btnUploadNo:(id)sender
{
    _btnUploadYes.selected = NO;
    _btnUploadNo.selected = YES;
    setProp( @"opt_upload", @"no");
} // btnUploadNo()

//-----------------------------------
- (void) btnShowDetectedBoard:(id)sender
{
    if ([_btnShowDetectedBoard isOn]) {
        setProp( @"opt_mode", @"video");
        [g_app.menuVC gotoVideoMode];
    }
    else {
        setProp( @"opt_mode", @"photo");
        [g_app.menuVC gotoPhotoMode];
    }
} // btnShowDetectedBoard()

//=========
// Public
//=========

//------------------------
- (bool) defaultToVideo
{
    NSString *optMode =  getProp( @"opt_mode", @"photo");
    bool res = [optMode isEqualToString:@"video"];
    return res;
}

//----------------------
- (bool) uploadEnabled
{
    NSString *optUpload =  getProp( @"opt_upload", @"yes");
    bool res = [optUpload isEqualToString:@"yes"];
    return res;
}

@end





























