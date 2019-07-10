
//
//  KerasScoreModel
//  KifuCam
//
//  Created by Andreas Hauenstein on 2019-07-9.
//  Copyright © 2018 AHN. All rights reserved.
//

// A convenience wrapper around a Keras Neural Network Model to
// score a Go position.

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <UIKit/UIImage.h>
#import "nn_score.h"

#pragma clang diagnostic ignored "-Wunguarded-availability"

@interface KerasScoreModel : NSObject

- (nonnull instancetype)initWithModel:(nullable nn_score *)kerasModel;
- (nullable double *) nnScorePos:(int[_Nonnull])pos turn:(int)turn;
- (MLMultiArray *_Nonnull) MultiArrayFromPos:(int[_Nonnull])pos turn:(int)turn;
+ (double *_Nonnull) test:(int*_Nonnull*_Nonnull)pos_out;

@end

