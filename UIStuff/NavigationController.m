//
//  NavigationController.m
//  LGSideMenuControllerDemo
//

#import "NavigationController.h"
#import "UIViewController+LGSideMenuController.h"

@implementation NavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.translucent = YES;
    self.navigationBar.barTintColor =  [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.95];
    
    self.navigationBar.titleTextAttributes = @{
                                               NSForegroundColorAttributeName: [UIColor blackColor],
                                               NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:18 ]
                                               //NSFontAttributeName: [UIFont fontWithName:@"Avenir" size: 18]
                                               };
    
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation) && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.sideMenuController.isRightViewVisible ? UIStatusBarAnimationSlide : UIStatusBarAnimationFade;
}

@end
