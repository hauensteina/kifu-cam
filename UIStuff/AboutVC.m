//
//  AboutVC.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-19.
//  Copyright © 2018 AHN. All rights reserved.
//

#import "AboutVC.h"

@interface AboutVC ()

@end

@implementation AboutVC
//-----------------------
- (id)init
{
    self = [super init];
    if (self) {
        CGRect frame = self.view.bounds;
        _tv = [[UITextView alloc] initWithFrame:frame];
        [_tv setFont:[UIFont fontWithName:@"HelveticaNeue" size:12 ]];
        _tv.editable = NO ;
        
        NSString *msg =
        @"\n"
        "About"
        "\n======\n"
        "\nUse Kifu Cam to take photos of Go boards and export the position to other apps."
        "\n"
        "\nExporting to programs like CrazyStone is discouraged, as that would be cheating."
        "\n"
        "\nPlease send comments and suggestions to \nkifu-cam@gmail.com."
        "\n"
        "\nSource Code"
        "\n============\n"
        "\nhttps://github.com/hauensteina/kifu-cam.git"
        "\n"
        "\nCredits"
        "\n======="
        "\n"
        "\nThe camera icon by Daniel Bruce was taken from "
        "\nhttps://www.flaticon.com/free-icon/photo-camera_3901"
        "\n"
        "\nAll image processing was done with OpenCV 3"
        "\nhttps://opencv.org/opencv-3-3.html"
        "\n"
        "\nThe FrameExtractor class is by Boris Ohayon"
        "\nhttps://medium.com/ios-os-x-development/ios-camera-frames-extraction-d2c0f80ed05a"
        "\n"
        "\nThanks to Adrian Rosebrock for his great tutorials on"
        "\nwww.pyimagesearch.com"
        "\n"
        "\nThanks to Mike Wallstedt for doing the same thing on Android."
        "\n"
        "\n"
        "\nBuild Date"
        "\n========="
        "\n\n2018-01-30"
        "\n"
        "\n"
        "\n=== The End ==="
        "\n";


        _tv.text = msg;
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
