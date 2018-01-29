//
//  EditTestCaseVC.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-17.
//  Copyright © 2018 AHN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditTestCaseVC : UITableViewController
- (void)refresh;
@property NSString *selectedTestCase;
@end

@interface EditTestCaseCell : UITableViewCell
//@property (strong, nonatomic) UIView *separatorView;
@end

