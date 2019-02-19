//
//  LeftViewController.m
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


#import "Globals.h"
#import "CppInterface.h"
#import "LeftMenuController.h"
#import "LeftMenuCell.h"
#import "S3.h"
#import "TopViewController.h"
#import "UIViewController+LGSideMenuController.h"

enum {ITEM_NOT_SELECTED=0, ITEM_SELECTED=1};
enum {VIDEO_MODE=0, PHOTO_MODE=1, DEBUG_MODE=2, DEMO_MODE=3};

@interface LeftMenuController ()
@property (strong, nonatomic) NSMutableArray *titlesArray;
@property UIFont *normalFont;
@property UIFont *selectedFont;
@property int mode; // debug, video, photo mode
@end

@implementation LeftMenuController

// Initialize left menu
//-----------------------
- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _selectedFont = [UIFont fontWithName:@"Verdana-Bold" size:16 ];
        _normalFont = [UIFont fontWithName:@"Verdana" size:16 ];
        NSArray *d = @[
                       // @{ @"txt": @"Video Mode", @"state": @(_mode == VIDEO_MODE) },
                       @{ @"txt": @"Photo Mode", @"state": @(_mode == PHOTO_MODE) },
                       @{ @"txt": @"Demo Mode", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Saved Images", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Import Photo", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"", @"state": @(ITEM_NOT_SELECTED) },
                       //@{ @"txt": @"Settings", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"About", @"state": @(ITEM_NOT_SELECTED) },
                       ];
        _titlesArray = [NSMutableArray new];
        for (NSDictionary *x in d) { [_titlesArray addObject:[x mutableCopy]]; }
        
        self.view.backgroundColor = [UIColor clearColor];

        [self.tableView registerClass:[LeftMenuCell class] forCellReuseIdentifier:@"cell"];
        self.tableView.separatorStyle =  UITableViewCellSeparatorStyleNone;
        self.tableView.contentInset = UIEdgeInsetsMake(44.0, 0.0, 44.0, 0.0);
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.backgroundColor = [UIColor clearColor];
        
        setProp( @"opt_mode", @"photo");
        if (iPhoneVersion() >= 8 || iPadVersion() >= 6) { setProp( @"opt_mode", @"video"); }
        if ([g_app.settingsVC defaultToVideo] && (iPhoneVersion() >= 8 || iPadVersion() >= 6)) {
            [self gotoVideoMode];
        }
        else {
            [self gotoPhotoMode];
        }
        [self unselectAll];
        [self setState:ITEM_SELECTED forMenuItem:@"Photo Mode"];
    }
    return self;
} // init()

//----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
}

//-------------------------------
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
//--------------------------------------------
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}
//-----------------------------------------------------------
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark - UITableViewDataSource
//-----------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
//------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titlesArray.count;
}
//------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LeftMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.titlesArray[indexPath.row][@"txt"];
    if ([_titlesArray[indexPath.row][@"state"] intValue] == ITEM_SELECTED) {
        [cell.textLabel setFont:_selectedFont];
    }
    else {
        [cell.textLabel setFont:_normalFont];
    }
    return cell;
} // cellForRowAtIndexPath()

#pragma mark - UITableViewDelegate
//-----------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

// Unselect all menu Items
//---------------------------
- (void)unselectAll
{
    for (id x in _titlesArray) { x[@"state"] = @(ITEM_NOT_SELECTED); }
}

// Select or unselect one menu item by row
//-------------------------------------------------
- (void)setState:(int)state forRow:(NSInteger)row
{
    _titlesArray[row][@"state"] = @(state);
} // setState: forRow:

// Select or unselect one menu item by title
//-------------------------------------------------
- (void)setState:(int)state forMenuItem:(NSString *)txt
{
    int idx = -1;
    for (NSDictionary *d in _titlesArray) {
        idx++;
        if ([d[@"txt"] hasPrefix:txt]) {
            _titlesArray[idx][@"state"] = @(state);
            break;
        }
    }
} // setState: forMenuItem:

- (bool) videoMode {
    return _mode == VIDEO_MODE; }
- (bool) photoMode {
    return _mode == PHOTO_MODE; }
- (bool) debugMode {
    return _mode == DEBUG_MODE; }
- (bool) demoMode  {
    return _mode == DEMO_MODE; }

// Handle left menu choice
//--------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopViewController *topViewController = (TopViewController *)self.sideMenuController;
    NSString *menuItem = _titlesArray[indexPath.row][@"txt"];

    do {
        if ([menuItem hasPrefix:@"Photo Mode"]) {
            if ([g_app.settingsVC defaultToVideo]) {
                [self gotoVideoMode];
            }
            else {
                [self gotoPhotoMode];
            }
        }
        else if ([menuItem hasPrefix:@"Demo Mode"]) {
            if (_mode == DEBUG_MODE) break;
            [self gotoDemoMode];
        }
        else if ([menuItem hasPrefix:@"Saved Images"]) {
            [g_app.navVC pushViewController:g_app.imagesVC animated:YES];
        }
        else if ([menuItem hasPrefix:@"Import Photo"]) {
            [self importPhoto];
        }
        else if ([menuItem hasPrefix:@"About"]) {
            [g_app.navVC pushViewController:g_app.aboutVC animated:YES];
        }
        else if ([menuItem hasPrefix:@"Settings"]) {
            [g_app.navVC pushViewController:g_app.settingsVC animated:YES];
        }
        [self.tableView reloadData];
    } while(0);
    [topViewController hideLeftViewAnimated:YES completionHandler:nil];
} // didSelectRowAtIndexPath()

//---------------------
- (void)gotoPhotoMode
{
    if (_mode == PHOTO_MODE) return;
    [self unselectAll];
    [self setState:ITEM_SELECTED forMenuItem:@"Photo Mode"];
    _mode = PHOTO_MODE;
    g_app.mainVC.btnCam.hidden = NO;
    [g_app.mainVC.frameExtractor resume];
    g_app.mainVC.lbBottom.text = @"Take a photo of a Go board";
    [g_app.mainVC doLayout];
} // gotoPhotoMode()

//---------------------
- (void)gotoVideoMode
{
    if (_mode == VIDEO_MODE) return;
    if (iPhoneVersion() < 8 && iPadVersion() < 6) {
        popup( @"Your device is too slow for video mode", @"Sorry");
        return;
    }
    [self unselectAll];
    [self setState:ITEM_SELECTED forMenuItem:@"Photo Mode"];
    _mode = VIDEO_MODE;
    g_app.mainVC.btnCam.hidden = NO;
    [g_app.mainVC.frameExtractor resume];
    g_app.mainVC.lbBottom.text = @"Point the camera at a Go board";
    [g_app.mainVC doLayout];
} // gotoVideoMode()

//---------------------
- (void)gotoDebugMode
{
    _mode = DEBUG_MODE;
    g_app.mainVC.btnCam.hidden = YES;
    [g_app.mainVC doLayout];
    [g_app.mainVC debugFlow:true];
    [self.tableView reloadData];
} // gotoDebugMode()

//---------------------
- (void)gotoDemoMode
{
    [self unselectAll];
    [self setState:ITEM_SELECTED forMenuItem:@"Demo Mode"];
    _mode = DEMO_MODE;
    g_app.mainVC.btnCam.hidden = YES;
    [g_app.mainVC doLayout];
    [g_app.mainVC debugFlow:true];
    [self.tableView reloadData];
} // gotoDemoMode()

//---------------------------
- (void)importPhoto
{
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
} // importPhoto()

// Image picker delegate methods
//================================

// This method is called when an image has been chosen from the library.
//-----------------------------------------------------------------------
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSString *fname = nscat( tstampFname(), @".png");
    fname = nsprintf( @"%@/%@", @SAVED_FOLDER, fname);
    fname = getFullPath( fname);
    
    // Maybe image orientation needs fixing.
    if ([img imageOrientation] != UIImageOrientationUp) {
        UIGraphicsBeginImageContext( img.size);
        CGRect imageRect = (CGRect){.origin = CGPointZero, .size = img.size};
        [img drawInRect:imageRect];
        img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    [picker dismissViewControllerAnimated:YES
                               completion:^{
                                   choicePopup( @[@"OK"], @"Photo Imported",
                                               ^(UIAlertAction *action) {
                                                   [g_app.mainVC processImg:img];
                                               });
                               }];
} // didFinishPickingMediaWithInfo()


@end

































































