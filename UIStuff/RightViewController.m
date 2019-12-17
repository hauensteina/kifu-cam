//
//  RightViewController.m
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
#import "RightViewController.h"
#import "RightViewCell.h"
#import "S3.h"
#import "TopViewController.h"
#import "UIViewController+LGSideMenuController.h"

enum {ITEM_NOT_SELECTED=0, ITEM_SELECTED=1};

@interface RightViewController ()

@property (strong, nonatomic) NSMutableArray *titlesArray;
@property UIFont *normalFont;
@property UIFont *selectedFont;
@property NSMutableArray *s3_testcase_imgfiles;
@property NSMutableArray *s3_testcase_sgffiles;
//@property dispatch_queue_t testQ;

@end

@implementation RightViewController

//----------
- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _selectedFont = [UIFont fontWithName:@"Verdana-Bold" size:16 ];
        _normalFont = [UIFont fontWithName:@"Verdana" size:16 ];
        NSArray *d = @[
                       @{ @"txt": @"Edit Test Cases", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Add Test Case", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Run Test Cases", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Overwrite Test Cases", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Upload Test Cases", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Download Test Casess", @"state": @(ITEM_NOT_SELECTED) }
                       ];
        _titlesArray = [NSMutableArray new];
        for (NSDictionary *x in d) { [_titlesArray addObject:[x mutableCopy]]; }

        self.view.backgroundColor = [UIColor clearColor];

        [self.tableView registerClass:[RightViewCell class] forCellReuseIdentifier:@"cell"];
        self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
        self.tableView.contentInset = UIEdgeInsetsMake(44.0, 0.0, 44.0, 0.0);
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    //self.testQ = dispatch_queue_create( "com.ahaux.testQ", DISPATCH_QUEUE_SERIAL);
    return self;
} // init()

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titlesArray.count;
}

//-------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RightViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
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

//------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

//--------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopViewController *topViewController = (TopViewController *)self.sideMenuController;
    NSString *menuItem = _titlesArray[indexPath.row][@"txt"];
    
    do {
        if ([menuItem hasPrefix:@"Edit Test Cases"]) {
            [self mnuEditTestCases];
        }
        else if ([menuItem hasPrefix:@"Add Test Case"]) {
            [self mnuAddTestCase];
        }
        else if ([menuItem hasPrefix:@"Run Test Cases"]) {
            dispatch_async( dispatch_get_main_queue(), ^{ [self mnuRunTestCases:NO]; });
        }
        else if ([menuItem hasPrefix:@"Overwrite Test Cases"]) {
            dispatch_async( dispatch_get_main_queue(), ^{ [self mnuRunTestCases:YES]; });
        }
        else if ([menuItem hasPrefix:@"Upload Test Cases"]) {
            [self mnuUploadTestCases];
        }
        else if ([menuItem hasPrefix:@"Download Test Cases"]) {
            [self mnuDownloadTestCases_0];
        }
        [self.tableView reloadData];
    } while(0);
    [topViewController hideRightViewAnimated:YES completionHandler:nil];
} // didSelectRowAtIndexPath

//============================
// Handlers for menu choices
//============================

// Save current image and board position as png and sgf.
// Filenames are testcase_nnnnn.png|sgf.
// The new nnnnn is one higher than the largest one found in the
// file systm.
//---------------------------
- (void)mnuAddTestCase 
{    
    // Get selected file from ImagesVC
    NSString *selFile = [g_app.imagesVC selectedFname];
    // Copy image
    NSString *source = nsprintf( @"%@/%@", @SAVED_FOLDER, selFile);
    NSString *fname = nscat( @TESTCASE_PREFIX, selFile);
    NSString *target = nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname);
    copyFile( source, target);
    // Copy sgf
    source = changeExtension( source, @".sgf");
    target = changeExtension( target, @".sgf");
    copyFile( source, target);
    
    //[g_app.editTestCaseVC refresh];
    popup( nsprintf( @"Added %@", fname), @"");
} // mnuAddTestCase()

// Show test cases from filesystem in a tableview, pick one.
//-------------------------------------------------------------
- (void) mnuEditTestCases
{
    [g_app.navVC pushViewController:g_app.editTestCaseVC animated:YES];
} // mnuSetCurrentTestCase()

// Run all test cases
//---------------------------------------
- (void)mnuRunTestCases:(bool)overwrite
{
    NSArray *testfiles = globFiles(@TESTCASE_FOLDER , @TESTCASE_PREFIX, @"*.png");
    NSMutableArray *errCounts = [NSMutableArray new];
    int idx = -1;
    for (id fname in testfiles ) {
        idx++;
        NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname));
        UIImage *img;
        @autoreleasepool {
            // Load the image
            img = nil;
            img = [UIImage imageWithContentsOfFile:fullfname];
            // Load the sgf
            fullfname = changeExtension( fullfname, @".sgf");
            NSString *sgf = [NSString stringWithContentsOfFile:fullfname encoding:NSUTF8StringEncoding error:NULL];
            // Classify
            int nerrs = [g_app.mainVC.cppInterface runTestImg:img withSgf: sgf];
            if (overwrite) {
                if ([getProp( @"opt_overwrite_sgf", @"off") isEqualToString:@"on"]) {
                    [g_app.mainVC.cppInterface save_current_sgf:fullfname overwrite:YES];
                }
                else {
                    [g_app.mainVC.cppInterface save_current_sgf:fullfname overwrite:NO];
                }
            }
            [errCounts addObject:@(nerrs)];
        } // @autoreleasepool
    } // for
    
    // Show error counts in a separate view controller
    int i = -1;
    int totErrs = 0;
    for (id fname in testfiles) {
        (void)fname;
        i++;
        totErrs += [errCounts[i] integerValue];
    }
    NSMutableString *msg = [NSMutableString new];
    [msg appendString: nsprintf( @"Total Errors:%d\n", totErrs)];
    [msg appendString:@"Error Count by File\n"];
    [msg appendString:@"===================\n\n"];

    i = -1;
    for (id fname in testfiles) {
        i++;
        long count = [errCounts[i] integerValue];
        NSString *line = nsprintf( @"%@:\t%5ld\n", fname, count);
        [msg appendString:line];
    } // for

    UITextView *tv = g_app.testResultsVC.tv;
    tv.text = msg;
    [g_app.navVC pushViewController:g_app.testResultsVC animated:YES];
} // mnuRunTestCases()

// Upload test cases to S3
//----------------------------
- (void)mnuUploadTestCases
{
    int idx;
    NSArray *testfiles;
    
    testfiles = globFiles(@TESTCASE_FOLDER, @TESTCASE_PREFIX, @"*.png");
    idx = -1;
    for (id fname in testfiles ) {
        idx++;
        NSString *fullfname = nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname);
        S3_upload_file( fullfname, fullfname, ^(NSError *err) {});
    } // for
    testfiles = globFiles(@TESTCASE_FOLDER, @TESTCASE_PREFIX, @"*.sgf");
    NSInteger fcount = [testfiles count];
    idx = -1;
    for (id fname in testfiles ) {
        idx++;
        NSString *fullfname = nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname);
        S3_upload_file( fullfname, fullfname,
                       ^(NSError *err) {
                           if (idx == fcount - 1) {
                               popup( @"Testcases uploaded", @"");
                           }
                       });
    } // for
} // mnuUploadTestCases()

// Download test cases from S3
//===============================

// Get list of png files
//--------------------------------
- (void)mnuDownloadTestCases_0
{
    _s3_testcase_imgfiles = [NSMutableArray new];
    S3_glob( nsprintf( @"%@/%@", @TESTCASE_FOLDER, @TESTCASE_PREFIX), @".png", _s3_testcase_imgfiles,
            ^(NSError *err) {
                if (err) {
                    popup( @"Failed to get S3 keys for img files", @"");
                }
                else {
                    [self mnuDownloadTestCases_1];
                }
            });
} // mnuDownloadTestCases_0()

// Get list of sgf files
//-------------------------------
- (void)mnuDownloadTestCases_1
{
    _s3_testcase_sgffiles = [NSMutableArray new];
    S3_glob( nsprintf( @"%@/%@", @TESTCASE_FOLDER, @TESTCASE_PREFIX), @".sgf", _s3_testcase_sgffiles,
            ^(NSError *err) {
                if (err) {
                    popup( @"Failed to get S3 keys for sgf files", @"");
                }
                else {
                    [self mnuDownloadTestCases_2];
                }
            });
} // mnuDownloadTestCases_1()

// Download image files
//-------------------------------
- (void)mnuDownloadTestCases_2
{
    int idx = -1;
    NSInteger fcount = [_s3_testcase_imgfiles count];
    if (!fcount) {
        popup( @"No testcases found.", @"");
        return;
    }
    for (id fname in _s3_testcase_imgfiles ) {
        idx++;
        NSString *tstr = nsprintf( @"%d / %d", idx+1, _s3_testcase_imgfiles.count);
        dispatch_async( dispatch_get_main_queue(), ^{ g_app.mainVC.lbSmall.text = tstr; });
        S3_download_file( fname, fname,
                         ^(NSError *err) {
                             if (idx == fcount - 1) {
                                 [self mnuDownloadTestCases_3];
                             }
                         });
    } // for
} // mnuDownloadTestCases_2()

// Download sgf files
//-------------------------------
- (void)mnuDownloadTestCases_3
{
    int idx = -1;
//    NSInteger fcount = [_s3_testcase_sgffiles count];
//    if (!fcount) {
//        popup( @"No sgf files found.", @"");
//        return;
//    }
    for (id fname in _s3_testcase_sgffiles ) {
        idx++;
        S3_download_file( fname, fname,
                         ^(NSError *err) {
                             if ([fname isEqualToString:[_s3_testcase_sgffiles lastObject]]) {
                                 popup( @"Testcases downloaded", @"");
                                 dispatch_async( dispatch_get_main_queue(), ^{ g_app.mainVC.lbSmall.text = @""; });
                             }
                         });
    } // for
} // mnuDownloadTestCases_3()

@end
