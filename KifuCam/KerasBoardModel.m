//
//  KerasBoardModel.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-03-08.
//  Copyright © 2018 AHN. All rights reserved.
//

// A convenience wrapper around a Keras Neural Network Model to
// assign an on-board score to each pixel

#import "KerasBoardModel.h"
#import "Globals.h"
#import <Vision/Vision.h>

@interface KerasBoardModel()
//================================
@property nn_io *model;
// Swap out the image data between calls to featureMap()
@property MLMultiArray *image;
@end

@implementation KerasBoardModel

//--------------------------------------------------------------------
- (nonnull instancetype)initWithModel:(nn_io *)kerasModel
{
    self = [super init];
    if (self) {
        _model = kerasModel;
    } // if (self)
    return self;
} // initWithModel()

// Return a two channel MLMultiArray. Channel 0 has the on-board convolutional
// layer, channel 1 has the off-board convolutional layer.
//-------------------------------------------------------------------------------
- (MLMultiArray *) featureMap:(MLMultiArray *)img
{
    nn_ioInput *nn_input = [[nn_ioInput alloc] initWithImage:img];
    NSError *err;
    nn_ioOutput *nnoutput = [_model predictionFromFeatures:nn_input error:&err];
    MLMultiArray *res = nnoutput.Identity;
    return res;
    //return [MLMultiArray new];
} // featureMap()

@end

