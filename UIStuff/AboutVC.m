//
//  AboutVC.m
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
        @"About"
        "\n======\n"
        "\nUse Kifu Cam to take a photo of a Go board.\n"
        "\nKifu Cam will give you the winning probability according to Katago, "
        "\nand good next moves. You will also get the Katago score and a territory"
        "\nvisualization. You can save and export the position in sgf format."
        "\n"
        "\nPlease send comments and suggestions to \nhauensteina@gmail.com."
        "\n"
        "\nSource Code"
        "\n============\n"
        "https://github.com/hauensteina/kifu-cam.git"
        "\n"
        "\nCredits"
        "\n=======\n"
        "\nKataGo, by David J. Wu, is here:"
        "\nhttps://github.com/lightvector/KataGo"
        "\n"
        "\nNeural networks for board detection and stone classification "
        "were trained using Keras and Tensorflow."
        "\n"
        "\nThe camera icon by Daniel Bruce was taken from "
        "\nhttps://www.flaticon.com/free-icon/photo-camera_3901"
        "\n"
        "\nThe sliding menu is done with LGSideMenuController, by Grigory Lutkov"
        "\nhttps://github.com/Friend-LGA/LGSideMenuController"
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
        "\nAuthor"
        "\n=========\n"
        "Andreas Hauenstein, 2020"
        "\n"
        "\nBuild Date"
        "\n=========\n"
        "2020-10-10"
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
