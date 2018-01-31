//
//  SettingsVC.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-30.
//  Copyright © 2018 AHN. All rights reserved.
//

#import "SettingsVC.h"

@interface SettingsVC ()

@end

@implementation SettingsVC
//-----------------------
- (id)init
{
    self = [super init];
    if (self) {
        CGRect frame = self.view.bounds;
        _tv = [[UITextView alloc] initWithFrame:frame];
        [_tv setFont:[UIFont fontWithName:@"HelveticaNeue" size:12 ]];
        _tv.editable = NO ;
        [self.view addSubview:_tv];

    }
    return self;
} // init()

//----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
}

 //----------------------------------------
 - (void) viewDidAppear: (BOOL) animated
 {
     [super viewDidAppear: animated];
 }

//----------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end
