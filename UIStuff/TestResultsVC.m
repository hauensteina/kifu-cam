//
//  TestResultsVC.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-19.
//  Copyright © 2018 AHN. All rights reserved.
//

#import "TestResultsVC.h"

@interface TestResultsVC ()

@end

@implementation TestResultsVC
//-----------------------
- (id)init
{
    self = [super init];
    if (self) {
        CGRect frame = self.view.bounds;
        _tv = [[UITextView alloc] initWithFrame:frame];
        [_tv setFont:[UIFont fontWithName:@"CourierNewPS-BoldMT" size:16 ]];
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
