//
//  KerasStoneModel.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-02-19.
//  Copyright © 2018 AHN. All rights reserved.
//

// A convenience wrapper around a Keras Neural Network Model to classify
// stones into Bleck, Empty, White

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <UIKit/UIImage.h>
#import "nn_bew.h"

#pragma clang diagnostic ignored "-Wunguarded-availability"

@interface KerasStoneModel : NSObject
@property (nullable) UIImage *dbgimg;

- (nonnull instancetype)initWithModel:(nullable nn_bew*) kerasModel;

// Classify a crop with one intersection at the center
// Returns one of BBLACK, EEMPTY, WWHITE
//------------------------------------------------------
- (int) classify: (nullable MLMultiArray *)image;

@end

