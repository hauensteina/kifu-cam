//
//  KerasBoardModel.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-03-8.
//  Copyright © 2018 AHN. All rights reserved.
//

// A convenience wrapper around a Keras Neural Network Model to
// assign an on-board score to each pixel

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <UIKit/UIImage.h>
#import "nn_io.h"

#pragma clang diagnostic ignored "-Wunguarded-availability"

@interface KerasBoardModel : NSObject
@property (nullable) UIImage *dbgimg;

- (nonnull instancetype)initWithModel:(nullable nn_io *)kerasModel;

// Return a two channel MLMultiArray. Channel 0 has the on-board convolutional
// layer, channel 1 has the off-board convolutional layer
//-------------------------------------------------------------------------------
- (nullable MLMultiArray *) featureMap:(nullable MLMultiArray *)img;

@end

