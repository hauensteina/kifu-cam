//
//  LeftViewController.h
//  LGSideMenuControllerDemo
//

#import <UIKit/UIKit.h>

@interface LeftMenuController : UITableViewController
// Getters for mode
- (bool) videoMode;
- (bool) photoMode;
- (bool) debugMode;
- (bool) demoMode;

- (void) gotoDebugMode;

@end
