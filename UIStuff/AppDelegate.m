//
//  AppDelegate.m
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

#import <AWSS3/AWSS3.h>

#import "AppDelegate.h"
#import "Globals.h"
#import "MainVC.h"
#import "TopViewController.h"
#import "NavigationController.h"
#import "Firebase.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

//------------------------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    setProp( @"opt_debug", @"off");
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor =  [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.95];
        
    g_app = self;
        
    self.mainVC = [MainVC new];
    self.settingsVC = [SettingsVC new]; // don't move this

    // Left and right side menu with Navigation underneath
    self.navVC = [[NavigationController alloc] initWithRootViewController:self.mainVC];
    self.topVC = [TopViewController new];
    //self.topVC.leftViewSwipeGestureEnabled = NO;
    self.topVC.rootViewController = self.navVC;
    [self.topVC setupLeftOnly];
    self.menuVC  = (LeftMenuController *) self.topVC.leftViewController;
    self.rightVC = (RightViewController *) self.topVC.rightViewController;
    [self enableDebugMenu];
    
    // Other view controllers
    self.editTestCaseVC = [EditTestCaseVC new];
    self.testResultsVC = [TestResultsVC new];
    self.saveDiscardVC = [SaveDiscardVC new];

    self.imagesVC = [ImagesVC new];
    self.aboutVC = [AboutVC new];
    self.window.rootViewController = self.topVC;

    [self.window makeKeyAndVisible];
    
    // Folder for test cases
    if (!dirExists( @TESTCASE_FOLDER)) {
        makeDir( @TESTCASE_FOLDER);
    }
    // Folder for saved images
    if (!dirExists( @SAVED_FOLDER)) {
        makeDir( @SAVED_FOLDER);
    }
    [FIRApp configure];
    return YES;
} // didFinishLaunchingWithOptions()

// Enable right side debug menu
//-------------------------------
- (void) enableDebugMenu
{
    setProp( @"opt_debug", @"on");
    [_topVC setupLeftAndRight];
    _menuVC  = (LeftMenuController *) _topVC.leftViewController;
    _rightVC = (RightViewController *) _topVC.rightViewController;
    _mainVC.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Dbg"
                                     style:UIBarButtonItemStylePlain
                                    target:_mainVC
                                    action:@selector(showRightView)];
} // enableDebugMenu()

// Black magic for background AWS S3 uploads
//-----------------------------------------------------------------------------------------------------------
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    //  Store the completion handler.
    [AWSS3TransferUtility interceptApplication:application
           handleEventsForBackgroundURLSession:identifier
                             completionHandler:completionHandler];
} // handleEventsForBackgroundURLSession()

@end

