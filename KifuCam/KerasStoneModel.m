//
//  KerasStoneModel.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-02-19.
//  Copyright © 2018 AHN. All rights reserved.
//

// A convenience wrapper around a Keras Neural Network Model to classify
// stones into Bleck, Empty, White

#import "KerasStoneModel.h"
#import "Globals.h"
#import <Vision/Vision.h>

@interface KerasStoneModel()
//================================
@property nn_bew *model;
@end

@implementation KerasStoneModel
{
    nn_bewInput *m_nninput;
}

//------------------------------------------------------------
- (nonnull instancetype)initWithModel:(nn_bew *)kerasModel
{
    self = [super init];
    if (self) {
        _model = kerasModel;
    } // if (self)
    return self;
} // initWithModel()

// Classify a crop with one intersection at the center
//---------------------------------------------------------
- (int) classify: (MLMultiArray *)image
{
    if (!m_nninput) {
        m_nninput = [[nn_bewInput alloc] initWithInput1:image];
    }
    NSError *err;
    nn_bewOutput *nnoutput = [_model predictionFromFeatures:m_nninput error:&err];
    NSString *clazz = nnoutput.bew;
    int res = DDONTKNOW;
    if ([clazz isEqualToString:@"b"]) {
        res = BBLACK;
    }
    else if ([clazz isEqualToString:@"e"]) {
        res = EEMPTY;
    }
    else if ([clazz isEqualToString:@"w"]) {
        res = WWHITE;
    }
    return res;
} // classify()

@end
