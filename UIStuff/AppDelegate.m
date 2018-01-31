//
//  AppDelegate.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-10-20.
//  Copyright © 2017 AHN. All rights reserved.
//

#import "AppDelegate.h"
#import "Globals.h"
#import "MainVC.h"
#import "TopViewController.h"
#import "NavigationController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

//------------------------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor =  [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.95];
        
    g_app = self;
        
    self.mainVC = [MainVC new];
    self.settingsVC = [SettingsVC new]; // don't move this

    // Left and right side menu with Navigation underneath
    self.navVC = [[NavigationController alloc] initWithRootViewController:self.mainVC];
    self.topVC = [TopViewController new];
    self.topVC.rootViewController = self.navVC;
    [self.topVC setupLeftOnly];
    self.menuVC  = (LeftMenuController *) self.topVC.leftViewController;
    self.rightVC = (RightViewController *) self.topVC.rightViewController;
    
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
    return YES;
} // didFinishLaunchingWithOptions()

// Enable right side debug menu
//-------------------------------
- (void) enableDebugMenu
{
    [_topVC setupLeftAndRight];
    _menuVC  = (LeftMenuController *) _topVC.leftViewController;
    _rightVC = (RightViewController *) _topVC.rightViewController;
}


@end
