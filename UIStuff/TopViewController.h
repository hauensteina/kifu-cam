//
//  TopViewController.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-14.
//  Copyright © 2017 AHN. All rights reserved.
//

#import "LGSideMenuController.h"

@interface TopViewController : LGSideMenuController

// Only show left menu
- (void)setupLeftOnly;
// Also show debug menu on the right
- (void)setupLeftAndRight;


@end
