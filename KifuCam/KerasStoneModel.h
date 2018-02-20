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
#import "nn_bew.h"

#pragma clang diagnostic ignored "-Wunguarded-availability"

@interface KerasStoneModel : NSObject

- (nonnull instancetype)initWithModel:(nullable MLModel *) kerasModel;
// Classify a crop with one intersection at the center
- (void) classify: (nullable CIImage *)image;

@end

