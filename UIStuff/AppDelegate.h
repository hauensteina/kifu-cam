//
//  AppDelegate.h
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
#import "AboutVC.h"
#import "SettingsVC.h"
#import "nn_bew.h"
#import "nn_io.h"
#import "KerasStoneModel.h"

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
@property (nonatomic, strong) AboutVC *aboutVC;
@property (nonatomic, strong) SettingsVC *settingsVC;

// NN models
@property nn_bew *bewmodel; // Keras model to classifiy intersections as Black, White, Empty
@property KerasStoneModel *stoneModel; // wrapper around bewmodel

- (void) enableDebugMenu;

@end

