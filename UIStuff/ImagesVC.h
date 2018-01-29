//
//  ImagesVC.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-17.
//  Copyright © 2018 AHN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagesVC : UITableViewController
- (void)refresh;
// Name of selected png file
- (NSString *)selectedFname;
@end

@interface ImagesCell : UITableViewCell
@end

