//
//  SaveDiscardVC.h
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

#import <UIKit/UIKit.h>

typedef void (^SDCompletionHandler)(void);

@interface SaveDiscardVC : UIViewController 
// Upload image and sgf to S3
+ (void) uploadToS3:(NSString*)fname;
// Get territory map from remote Katago
- (void) askRemoteBotTerr:(int)turn
                     komi:(double)komi
                 handicap:(int)handicap
               completion:(SDCompletionHandler)completion;
- (void) askRemoteBotMove:(int)turn
                     komi:(double)komi
                 handicap:(int)handicap
               completion:(SDCompletionHandler)completion;

// Set this before pushing VC
@property NSString *sgf;
@property UIImage *photo;
@property int turn;
@property double score;
@property NSMutableArray *terrmap;
@property NSString *botmove;
@property double winprob;
@property NSArray *best_ten_moves;

@end
