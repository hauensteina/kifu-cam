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

//----------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor =  [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.95];
        
    g_app = self;
        
    self.mainVC = [MainVC new];
    
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
    
    // CLean up garbage in the file system
//    NSArray *files = glob_files(@"", @"", @"jpg");
//    for (NSString *f in files) {
//        rm_file( f);
//    }
//    files = glob_files(@"", @"", @"jpg");
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
