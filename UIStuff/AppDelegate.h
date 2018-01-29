//
//  AppDelegate.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-10-20.
//  Copyright © 2017 AHN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TopViewController.h"
#import "MainVC.h"
#import "LeftMenuController.h"
#import "RightViewController.h"
#import "NavigationController.h"
#import "EditTestCaseVC.h"
#import "ImagesVC.h"
#import "TestResultsVC.h"
#import "SaveDiscardVC.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// TopVC contains MainVC, LeftVC, RightVC
@property (nonatomic,strong)  TopViewController *topVC;
@property (nonatomic,strong)  NavigationController *navVC;

// Center, Left Menu, Right Menu
@property (nonatomic, strong) MainVC *mainVC;
@property (nonatomic, strong) LeftMenuController *menuVC;
@property (nonatomic, strong) RightViewController *rightVC;

// Other screens
@property (nonatomic, strong) EditTestCaseVC *editTestCaseVC;
@property (nonatomic, strong) TestResultsVC *testResultsVC;
@property (nonatomic, strong) SaveDiscardVC *saveDiscardVC;
@property (nonatomic, strong) ImagesVC *imagesVC;

@end

