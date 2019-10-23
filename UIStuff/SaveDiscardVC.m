//
//  SaveDiscardVC.m
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

#import "SaveDiscardVC.h"
#import "Common.h"
#import "S3.h"
#import "Globals.h"
#import "ImagesVC.h"
#import <Crashlytics/Crashlytics.h>


@interface SaveDiscardVC ()
@property UIImage *sgfImg;
@property UIImage *scoreImg;
@property UIImageView *sgfView;
//@property UIImageView *photoView;
@property UIButton *btnSave;
@property UIButton *btnDiscard;
@property UIButton *btnB2Play;
@property UIButton *btnW2Play;
@property UILabel *lbInfo;
@property UILabel *lbInfo2;
@property UILabel *lbInfo3;
@end

@implementation SaveDiscardVC
//-----------------------------
- (id) init
{
    self = [super init];
    if (self) {
        self.view = [UIView new];
        UIView *v = self.view;
        v.autoresizesSubviews = NO;
        v.opaque = YES;
        v.backgroundColor = BGCOLOR;
        
        // Image View for sgf
        _sgfView = [UIImageView new];
        _sgfView.contentMode = UIViewContentModeScaleAspectFit;
        [v addSubview:_sgfView];
        
        // Info labels
        UILabel *l = [UILabel new];
        l.text = @"";
        l.backgroundColor = BGCOLOR;
        l.textColor = UIColor.blackColor;
        [v addSubview:l];
        self.lbInfo = l;
        
        UILabel *l2 = [UILabel new];
        l2.text = @"";
        l2.backgroundColor = BGCOLOR;
        l2.textColor = UIColor.blackColor;
        [v addSubview:l2];
        self.lbInfo2 = l2;
        
        UILabel *l3 = [UILabel new];
        l3.text = @"";
        l3.backgroundColor = BGCOLOR;
        l3.textColor = UIColor.blackColor;
        [v addSubview:l3];
        self.lbInfo3 = l3;
        
        // Buttons
        //=========
        // Black to play
        _btnB2Play = [UIButton new];
        [_btnB2Play setTitle:@"Black to play" forState:UIControlStateNormal];
        [_btnB2Play.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:30.0]];
        [_btnB2Play sizeToFit];
        [_btnB2Play addTarget:self action:@selector(btnB2Play:) forControlEvents: UIControlEventTouchUpInside];
        [v addSubview:_btnB2Play];
        // White to play
        _btnW2Play = [UIButton new];
        [_btnW2Play setTitle:@"White to play" forState:UIControlStateNormal];
        [_btnW2Play.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:30.0]];
        [_btnW2Play sizeToFit];
        [_btnW2Play addTarget:self action:@selector(btnW2Play:) forControlEvents: UIControlEventTouchUpInside];
        [v addSubview:_btnW2Play];
        // Save
        _btnSave = [UIButton new];
        [_btnSave setTitle:@"Save" forState:UIControlStateNormal];
        [_btnSave.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:30.0]];
        [_btnSave sizeToFit];
        [_btnSave addTarget:self action:@selector(btnSave:) forControlEvents: UIControlEventTouchUpInside];
        [v addSubview:_btnSave];
        // Discard
        _btnDiscard = [UIButton new];
        [_btnDiscard setTitle:@"Discard" forState:UIControlStateNormal];
        [_btnDiscard.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:30.0]];
        [_btnDiscard sizeToFit];
        [_btnDiscard addTarget:self action:@selector(btnDiscard:) forControlEvents: UIControlEventTouchUpInside];
        [v addSubview:_btnDiscard];
    }
    return self;
} // init()

//----------------------
- (void) viewDidLoad
{
    [super viewDidLoad];
}

 //----------------------------------------
 - (void) viewDidAppear: (BOOL) animated
 {
     [super viewDidAppear: animated];
     [self doLayout];
     if (_turn == BBLACK) {
         [self btnB2Play:nil];
     }
     else if (_turn == WWHITE) {
         [self btnW2Play:nil];
     }
 }

//----------------------------------
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

// Helpers
//============

// Save photo and sgf
//------------------------------
- (NSString*) savePhotoAndSgf 
{
    // Make filename from date
    NSString *fname = nscat( tstampFname(), @".png");
    fname = nsprintf( @"%@/%@", @SAVED_FOLDER, fname);
    fname = getFullPath( fname);
    // Save img
    [UIImagePNGRepresentation( _photo) writeToFile:fname atomically:YES];
    // Save sgf
    fname = changeExtension( fname, @".sgf");
    NSError *error;
    [_sgf writeToFile:fname
           atomically:YES encoding:NSUTF8StringEncoding error:&error];
    return fname;
} // savePhotoAndSgf()

// Upload image and sgf to S3
//------------------------------------
+ (void) uploadToS3:(NSString*)fname
{
    if (![g_app.settingsVC uploadEnabled]) return;
    
    NSString *uuid = nsprintf( @"%@", [UIDevice currentDevice].identifierForVendor);
    NSArray *parts = [uuid componentsSeparatedByString:@"-"];
    NSString *s3name;
    NSString *tstamp = tstampFname();
    // Photo
    fname = changeExtension( fname, @".png");
    s3name = nsprintf( @"%@/%@-%@.png", @S3_UPLOAD_FOLDER, parts[0], tstamp);
    S3_upload_file( fname, s3name , ^(NSError *err) {});
    // Sgf
    fname = changeExtension( fname, @".sgf");
    s3name = nsprintf( @"%@/%@-%@.sgf", @S3_UPLOAD_FOLDER, parts[0], tstamp);
    S3_upload_file( fname, s3name , ^(NSError *err) {});
} // uploadToS3()

// Score position and display result.
//--------------------------------------------------
- (void) displayResult:(int)turn {
    CppInterface *cpp = g_app.mainVC.cppInterface;
    int bpoints, surepoints;
    char *terrmap;
    [cpp f09_score:turn bpoints:&bpoints surepoints:&surepoints terrmap:&terrmap];
    if (surepoints < 250) {
        _lbInfo.text = @"Too early to score";
        [self askLeela:turn terrmap:NULL];
        return;
    }
    _scoreImg = [CppInterface scoreimg:_sgf terrmap:terrmap];
    [_sgfView setImage:_scoreImg];
    [self askLeela:turn terrmap:terrmap];
    NSString *winner = @"B";
    if (bpoints < BOARD_SZ*BOARD_SZ / 2) { winner = @"W"; }
    int delta = abs( bpoints - (BOARD_SZ*BOARD_SZ - bpoints));
    _lbInfo.text = nsprintf( @"B:%d W:%d", bpoints, BOARD_SZ*BOARD_SZ - bpoints);
    _lbInfo2.text = nsprintf( @"%@+%d before komi and handicap", winner, delta);
} // displayResult()

// Ask Leela about this position
//------------------------------------------------------
- (void) askLeela:(int)turn terrmap:(char *)terrmap { //@@@
    _lbInfo3.text = @"Leela is thinking ...";
    const int timeout = 15;
    static NSTimer* timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                            repeats:false
                                              block:^(NSTimer * _Nonnull timer) {
        _lbInfo3.text = @"Leela timed out";
    }];
    
    NSString *urlstr = @"https://ahaux.com/leela_server/select-move/leela_gtp_bot";
    NSArray *leelaMoves = [g_app.mainVC.cppInterface get_leela_moves:turn];
    NSDictionary *parms =
    @{@"board_size":@(19), @"moves":leelaMoves,
      @"config":@{@"randomness": @"-1.0", @"playouts":@"1000" } };
    NSError *err;
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:parms options:kNilOptions error:&err];
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    request.HTTPMethod = @"POST";
    
    [request setURL:[NSURL URLWithString:urlstr]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:jsonBodyData];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    config.timeoutIntervalForRequest = timeout+1;
                      
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData * _Nullable data,
                                   NSURLResponse * _Nullable response,
                                   NSError * _Nullable error) {
        [timer invalidate];
        // The endpoint comes back with resp
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *) response;
        if (resp.statusCode == 200) {
            NSLog(@"The response is: %@", resp);
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:nil];
            NSString *bot_move = json[@"bot_move"];
            _sgfImg = [CppInterface nextmove2img:_sgf
                                           coord:bot_move
                                           color:turn
                                         terrmap:terrmap
                       ];
            [_sgfView setImage:_sgfImg];
            float pbwins = [json[@"diagnostics"][@"winprob"] floatValue];
            _lbInfo3.text = nsprintf( @"P(B wins) = %.2f", pbwins);
        }
        else {
            if ([_lbInfo3.text containsString:@"timed out"]) {
                _lbInfo3.text = @"Leela timed out";
            } else {
                _lbInfo3.text = @"Error contacting Leela";
            }
        }
    }]; // [session ...
    [task resume];
} // askLeela()

// Button Callbacks
//======================

//-----------------------------
- (void) btnB2Play:(id)sender
{
    // [[Crashlytics sharedInstance] crash];
    [self displayResult:BBLACK];
    // Regex to insert PL[B] right after the SZ tag
    NSString *re = @"(.*SZ\\[[0-9]+\\])(.*)";
    NSString *templ = @"$1 PL[B] $2";
    _sgf = replaceRegex( re, _sgf, templ);
    _btnSave.hidden = NO;
    _btnDiscard.hidden = NO;
    _btnB2Play.hidden = YES;
    _btnW2Play.hidden = YES;
} // btnB2Play()

//-----------------------------
- (void) btnW2Play:(id)sender
{
    [self displayResult:WWHITE];
    // Regex to insert PL[W] rigth after the SZ tag
    NSString *re = @"(.*SZ\\[[0-9]+\\])(.*)";
    NSString *templ = @"$1 PL[W] $2";
    _sgf = replaceRegex( re, _sgf, templ);
    _btnSave.hidden = NO;
    _btnDiscard.hidden = NO;
    _btnB2Play.hidden = YES;
    _btnW2Play.hidden = YES;
} // btnW2Play()

//------------------------------
- (void) btnDiscard:(id)sender
{
    [g_app.navVC popViewControllerAnimated:YES];
} // btnDiscard()

//------------------------------
- (void) btnSave:(id)sender
{
    NSString *fname = [self savePhotoAndSgf];
    [SaveDiscardVC uploadToS3:fname];
    
    // Show saved images
    [g_app.navVC popViewControllerAnimated:NO];
    [g_app.navVC pushViewController:g_app.imagesVC animated:YES];
} // btnSave()

// Layout
//==========

// Put UI elements into the right place
//---------------------------------------
- (void) doLayout
{
    float W = SCREEN_WIDTH;
    float topmarg = g_app.navVC.navigationBar.frame.size.height;
    float marg = W/20;
    float imgWidth = (W  - 2*marg);
    
    // Sgf View
    _sgfView.hidden = NO;
    _sgfView.frame = CGRectMake( marg, topmarg + 40, imgWidth , imgWidth);
    if (_sgf) {
        _sgfImg = [CppInterface sgf2img:_sgf];
        [_sgfView setImage:_sgfImg];
    }
    
    // Info labels
    int lw = SCREEN_WIDTH;
    int lmarg = (SCREEN_WIDTH - lw) / 2;
    int y = topmarg + 40 + imgWidth + 10;
    _lbInfo.frame = CGRectMake( lmarg, y, lw, 0.04 * SCREEN_HEIGHT);
    _lbInfo.textAlignment = NSTextAlignmentCenter;
    _lbInfo.text = @"";
    
    y = topmarg + 40 + imgWidth + 40;
    _lbInfo2.frame = CGRectMake( lmarg, y, lw, 0.04 * SCREEN_HEIGHT);
    _lbInfo2.textAlignment = NSTextAlignmentCenter;
    _lbInfo2.text = @"";
    
    y = topmarg + 40 + imgWidth + 70;
    _lbInfo3.frame = CGRectMake( lmarg, y, lw, 0.04 * SCREEN_HEIGHT);
    _lbInfo3.textAlignment = NSTextAlignmentCenter;
    _lbInfo3.text = @"";
    
    // Buttons
    float btnWidth, btnHeight;
    y = topmarg + 40 + imgWidth + 50;
    
    _btnB2Play.hidden = NO;
    [_btnB2Play setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    btnWidth = _btnB2Play.frame.size.width;
    btnHeight = _btnB2Play.frame.size.height;
    _btnB2Play.frame = CGRectMake( W/2 - btnWidth/2, y, btnWidth, btnHeight);
    
    y += btnHeight * 1.3;
    _btnW2Play.hidden = NO;
    [_btnW2Play setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    btnWidth = _btnW2Play.frame.size.width;
    btnHeight = _btnW2Play.frame.size.height;
    _btnW2Play.frame = CGRectMake( W/2 - btnWidth/2, y, btnWidth, btnHeight);
    
    y += btnHeight * 1.3;

    _btnSave.hidden = YES;
    [_btnSave setTitleColor:DARKGREEN forState:UIControlStateNormal];
    btnWidth = _btnSave.frame.size.width;
    btnHeight = _btnSave.frame.size.height;
    _btnSave.frame = CGRectMake( W/2 - btnWidth - W/20 - 0.04 * W, y, btnWidth, btnHeight);

    _btnDiscard.hidden = YES;
    [_btnDiscard setTitleColor:RED forState:UIControlStateNormal];
    btnWidth = _btnDiscard.frame.size.width;
    btnHeight = _btnDiscard.frame.size.height;
    _btnDiscard.frame = CGRectMake( W/2 + W/20 - 0.04 * W, y, btnWidth, btnHeight);
} // doLayout()

@end




































