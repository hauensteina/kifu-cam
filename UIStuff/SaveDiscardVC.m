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
#import "KifuCam-Swift.h"
//#import <Crashlytics/Crashlytics.h>


@interface SaveDiscardVC ()
@property UIImage *sgfImg;
@property UIImage *scoreImg;
@property UIImageView *sgfView;
@property UIButton *btnSave;
@property UIButton *btnDiscard;
@property UIButton *btnB2Play;
@property UIButton *btnW2Play;
@property UILabel *lbInfo;
@property UILabel *lbTurn;
@property UILabel *lbHandiKomi;

// Komi
@property UILabel *lbKomi;
@property UITextField *tfKomi;
@property AXPicker *pickKomi;

// Handicap
@property UILabel *lbHandi;
@property UITextField *tfHandi;
@property AXPicker *pickHandi;

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
        
        // Info label
        UILabel *l = [UILabel new];
        l.text = @"";
        l.backgroundColor = BGCOLOR;
        l.textColor = UIColor.blackColor;
        [v addSubview:l];
        self.lbInfo = l;

        // Handicap and Komi label
        UILabel *h = [UILabel new];
        h.text = @"";
        h.backgroundColor = BGCOLOR;
        h.textColor = UIColor.blackColor;
        [v addSubview:h];
        self.lbHandiKomi = h;

        // Turn label
        UILabel *t = [UILabel new];
        t.text = @"";
        t.backgroundColor = BGCOLOR;
        t.textColor = UIColor.blackColor;
        [v addSubview:t];
        self.lbTurn = t;

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
        
        // Dropdowns
        //============
        // Komi
        _lbKomi = [UILabel new];
        [_lbKomi setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0]];
        _lbKomi.textAlignment = NSTextAlignmentCenter;
        _lbKomi.text = @"Komi";
        [_lbKomi sizeToFit];
        [v addSubview: _lbKomi];
        _tfKomi = [UITextField new];
        [_tfKomi setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0]];
        _tfKomi.textAlignment = NSTextAlignmentCenter;
        [_tfKomi setText:@"7.5"];
        _pickKomi = [[AXPicker new] initWithVC:self
                                            tf:_tfKomi
                                       choices:@[@"7.5",@"6.5",@"5.5",@"0.5"
                                                 ,@"0"
                                                 ,@"-0.5",@"-5.5",@"-6.5",@"-7.5"]];
        [v addSubview:_tfKomi];

        // Handicap
        _lbHandi = [UILabel new];
        [_lbHandi setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0]];
        _lbHandi.textAlignment = NSTextAlignmentCenter;
        _lbHandi.text = @"Handicap";
        [_lbHandi sizeToFit];
        [v addSubview: _lbHandi];
        _tfHandi = [UITextField new];
        [_tfHandi setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0]];
        _tfHandi.textAlignment = NSTextAlignmentCenter;
        [_tfHandi setText:@"0"];
        _pickHandi = [[AXPicker new] initWithVC:self
                                             tf:_tfHandi
                                        choices:@[@"0",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"]];
        [v addSubview:_tfHandi];
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
     // @[][1]; // Force a crash
     if (_turn == BBLACK) { // coming from handleRerun()
         _tfHandi.text = _parm_handicap;
         _tfKomi.text = _parm_komi;
         [self btnB2Play:nil];
     }
     else if (_turn == WWHITE) { // coming from handleRerun()
         _tfHandi.text = _parm_handicap;
         _tfKomi.text = _parm_komi;
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
//--------------------------------------
- (void) displayResult:(int)turn {
    // Store komi and handicap in sgf
    _sgf = replaceStr( @"KM[0]", nsprintf( @"KM[%.1f]", [_tfKomi.text doubleValue]), _sgf);
    _sgf = replaceStr( @"HA[0]", nsprintf( @"HA[%d]", [_tfHandi.text intValue]), _sgf);
    // Set self.terrmap from remote bot
    [self askRemoteBotTerr:turn
                      komi:[_tfKomi.text doubleValue]
                  handicap:[_tfHandi.text intValue]
                completion:^{
        // Get next move and score from remote bot
        [self askRemoteBotMove:turn
                          komi:[_tfKomi.text doubleValue]
                      handicap:[_tfHandi.text intValue]
                    completion:^{
            NSString *tstr = nsprintf( @"P(B wins)=%.2f", self.winprob);
            if (self.score > 0) {
                tstr = nsprintf( @" %@ B+%.1f", tstr, fabs(self.score));
            } else {
                tstr = nsprintf( @" %@ W+%.1f", tstr, fabs(self.score));
            }
            _lbInfo.text = tstr;
            _lbTurn.text = @"Black to Move";
            _lbHandiKomi.text = nsprintf( @"Handicap:%d Komi:%.1f",
                                         [_tfHandi.text intValue], [_tfKomi.text doubleValue]);
            if (turn == WWHITE) { _lbTurn.text = @"White to Move"; }
            double *terrmap = cterrmap( self.terrmap);
            _scoreImg = [CppInterface nextmove2img:_sgf
                                            coords:self.best_ten_moves
                                             color:turn
                                           terrmap:terrmap
                         ];
            [_sgfView setImage:_scoreImg];
        }]; // askRemoteBotMove
    }]; // askRemoteBotTerr
} // displayResult()

// Ask remote bot for territory map. 
//--------------------------------------------------------------------
- (void) askRemoteBotTerr:(int)turn komi:(double)komi
                 handicap:(int)handicap
               completion:(SDCompletionHandler)completion {
    _lbInfo.text = @"Katago is counting ...";
    const int timeout = 15;
    static NSTimer* timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                            repeats:false
                                              block:^(NSTimer * _Nonnull timer) {
        _lbInfo.text = @"Katago timed out";
    }];
    
    NSString *urlstr = @"https://katagui.baduk.club/score/katago_gtp_bot";
    NSString *uniq = nsprintf( @"%d", rand());
    urlstr = nsprintf( @"%@?tt=%@",urlstr,uniq);
    NSArray *botMoves = [g_app.mainVC.cppInterface get_bot_moves:turn
                                                        handicap:[_tfHandi.text intValue]];
    NSDictionary *parms =
    @{@"board_size":@(19), @"moves":botMoves,
      @"config":@{@"komi": @(komi), @"client":@"kifucam"}};
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
            //NSLog(@"The response is:\n%@", resp);
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:nil];
            self.botmove = json[@"diagnostics"][@"bot_move"];
            NSArray *probs = json[@"probs"];
            self.terrmap = [NSMutableArray new];
            ILOOP (BOARD_SZ * BOARD_SZ) {
                [self.terrmap addObject: @([(NSString *)(probs[i]) doubleValue])];
            } // ILOOP
            _lbInfo.text = @"";
            completion();
        }
        else {
            if ([_lbInfo.text containsString:@"timed out"]) {
                _lbInfo.text = @"Katago scoring timed out";
            } else {
                _lbInfo.text = @"Error contacting Katago";
            }
        }
    }]; // [session ...
    [task resume];
} // askRemoteBotTerr()

// Ask remote bot for move and winprob
//-------------------------------------------------------------
- (void) askRemoteBotMove:(int)turn komi:(double)komi
                 handicap:(int)handicap
               completion:(SDCompletionHandler)completion {
    _lbInfo.text = @"Katago is thinking ...";
    const int timeout = 15;
    static NSTimer* timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                            repeats:false
                                              block:^(NSTimer * _Nonnull timer) {
        _lbInfo.text = @"Katago timed out";
    }];
    
    NSString *urlstr = @"https://katagui.baduk.club/select-move-x/katago_gtp_bot";
    NSString *uniq = nsprintf( @"%d", rand());
    urlstr = nsprintf( @"%@?tt=%@",urlstr,uniq);
    NSArray *botMoves = [g_app.mainVC.cppInterface get_bot_moves:turn
                                                        handicap:[_tfHandi.text intValue]];
    NSDictionary *parms =
    @{@"board_size":@(19), @"moves":botMoves,
      @"config":@{@"komi": @(komi), @"client":@"kifucam"}};
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
            // NSLog(@"The response is:\n%@", resp);
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:nil];
            self.botmove = json[@"diagnostics"][@"bot_move"];
            self.best_ten_moves = json[@"diagnostics"][@"best_ten"];
            NSLog(@"Score:\n%@", json[@"diagnostics"][@"score"]);
            self.score = [(NSNumber *)(json[@"diagnostics"][@"score"]) doubleValue];
            
            if (komi == floor(komi)) { // whole number komi
                self.score = sign(self.score) * ((int)(fabs(self.score) + 0.5)); // 2.1 -> 2.0,  2.9 -> 3.0
            } else { // x.5 komi
                self.score = sign(self.score) * ((int)(fabs(self.score)) + 0.5);  // 2.1 -> 2.5 2.9 -> 2.5
            }
            //self.score = sign(self.score) * (int)(2 * fabs(self.score) + 0.5) / 2.0; // round to 0.5
            self.winprob = [(NSNumber *)(json[@"diagnostics"][@"winprob"]) doubleValue];
            _lbInfo.text = @"";
            completion();
        }
        else {
            if ([_lbInfo.text containsString:@"timed out"]) {
                _lbInfo.text = @"Katago timed out";
            } else {
                _lbInfo.text = @"Error contacting Katago";
            }
        }
    }]; // [session ...
    [task resume];
} // askRemoteBotMove()


// Button Callbacks
//======================

//-----------------------------
- (void) btnB2Play:(id)sender
{
    [self displayResult:BBLACK];
    // Regex to insert PL[B] right after the SZ tag
    NSString *re = @"(.*SZ\\[[0-9]+\\])(.*)";
    NSString *templ = @"$1 PL[B] $2";
    _sgf = replaceRegex( re, _sgf, templ);
    _btnSave.hidden = NO;
    _btnDiscard.hidden = NO;
    _btnB2Play.hidden = YES;
    _btnW2Play.hidden = YES;
    _lbKomi.hidden = YES;
    _tfKomi.hidden = YES;
    _lbHandi.hidden = YES;
    _tfHandi.hidden = YES;
} // btnB2Play()

//-----------------------------
- (void) btnW2Play:(id)sender
{
    [self displayResult:WWHITE];
    // Regex to insert PL[W] right after the SZ tag
    NSString *re = @"(.*SZ\\[[0-9]+\\])(.*)";
    NSString *templ = @"$1 PL[W] $2";
    _sgf = replaceRegex( re, _sgf, templ);
    _btnSave.hidden = NO;
    _btnDiscard.hidden = NO;
    _btnB2Play.hidden = YES;
    _btnW2Play.hidden = YES;
    _lbKomi.hidden = YES;
    _tfKomi.hidden = YES;
    _lbHandi.hidden = YES;
    _tfHandi.hidden = YES;
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
    const float W = SCREEN_WIDTH;
    const float H = SCREEN_HEIGHT;
    float topmarg = g_app.navVC.navigationBar.frame.size.height;
    //float marg = W/20;
    //float imgWidth = (W  - 2*marg);
    
    const float boardWidth = MIN( W, H * 0.5);
    
    int y = topmarg + 50;
    // Sgf View
    _sgfView.hidden = NO;
    _sgfView.frame = CGRectMake( 0, y, W , boardWidth);
    if (_sgf) {
        _sgfImg = [CppInterface sgf2img:_sgf];
        [_sgfView setImage:_sgfImg];
    }
    
    // Info label
    y += boardWidth + 10;
    _lbInfo.frame = CGRectMake( 0, y, W, 0.03 * H);
    _lbInfo.textAlignment = NSTextAlignmentCenter;
    _lbInfo.text = @"";

    // Handicap and Komi label
    y += 30;
    _lbHandiKomi.frame = CGRectMake( 0, y, W, 0.03 * H);
    _lbHandiKomi.textAlignment = NSTextAlignmentCenter;
    _lbHandiKomi.text = @"";

    // Turn label
    y += 30;
    _lbTurn.frame = CGRectMake( 0, y, W, 0.03 * H);
    _lbTurn.textAlignment = NSTextAlignmentCenter;
    _lbTurn.text = @"";

    // Buttons
    float btnWidth, btnHeight;
    //y = topmarg + 40 + boardWidth + H*0.1;
    float d = H*0.04;
    y = CGRectGetMaxY( _sgfView.frame) + d;

    // Black to play
    _btnB2Play.hidden = NO;
    [_btnB2Play setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    // Keep size (auto), change origin
    btnWidth = _btnB2Play.frame.size.width;
    btnHeight = _btnB2Play.frame.size.height;
    _btnB2Play.frame = CGRectMake( W/2 - btnWidth/2, y, btnWidth, btnHeight);
    
    // White to play
    y = CGRectGetMaxY( _btnB2Play.frame);
    _btnW2Play.hidden = NO;
    [_btnW2Play setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    btnWidth = _btnW2Play.frame.size.width;
    btnHeight = _btnW2Play.frame.size.height;
    _btnW2Play.frame = CGRectMake( W/2 - btnWidth/2, y, btnWidth, btnHeight);
    
    // Save
    y += btnHeight * 1.3;
    _btnSave.hidden = YES;
    [_btnSave setTitleColor:DARKGREEN forState:UIControlStateNormal];
    btnWidth = _btnSave.frame.size.width;
    btnHeight = _btnSave.frame.size.height;
    _btnSave.frame = CGRectMake( W/2 - btnWidth - W/20 - 0.04 * W, y, btnWidth, btnHeight);

    // Discard
    _btnDiscard.hidden = YES;
    [_btnDiscard setTitleColor:RED forState:UIControlStateNormal];
    btnWidth = _btnDiscard.frame.size.width;
    btnHeight = _btnDiscard.frame.size.height;
    _btnDiscard.frame = CGRectMake( W/2 + W/20 - 0.04 * W, y, btnWidth, btnHeight);

    // Dropdowns
    y = CGRectGetMaxY( _btnW2Play.frame);
    int lrmarg = 0.33 * W;
    
    // Komi Heading
    _lbKomi.hidden = NO;
    [_lbKomi setTextColor:UIColor.blackColor];
    _lbKomi.frame = CGRectMake( lrmarg - 0.5 * _lbKomi.frame.size.width, y,
                               _lbKomi.frame.size.width, _btnW2Play.frame.size.height);

    // Handicap Heading
    _lbHandi.hidden = NO;
    [_lbHandi setTextColor:UIColor.blackColor];
    _lbHandi.frame = CGRectMake( W - lrmarg - 0.5 * _lbHandi.frame.size.width, y,
                                _lbHandi.frame.size.width, _btnW2Play.frame.size.height);

    // Komi Dropdown
    y += _btnW2Play.frame.size.height;
    int ddw = 0.33 * W;

    _tfKomi.hidden = NO;
    _tfKomi.frame = CGRectMake( lrmarg - 0.5 * ddw, y,
                               ddw, _btnW2Play.frame.size.height);
    
    // Handicap Dropdown
    _tfHandi.hidden = NO;
    _tfHandi.frame = CGRectMake( W - lrmarg - 0.5 * ddw, y,
                                ddw, _btnW2Play.frame.size.height);
    
} // doLayout()


@end




































