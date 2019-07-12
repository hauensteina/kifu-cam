//
//  KerasScoreModel
//  KifuCam
//
//  Created by Andreas Hauenstein on 2019-07-09.
//  Copyright © 2019 AHN. All rights reserved.
//

// A convenience wrapper around a Keras Neural Network Model to
// score a Go position.

#import "KerasScoreModel.h"
#import "Globals.h"
//#import <Vision/Vision.h>

@interface KerasScoreModel()
//================================
@property nn_score *model;
@end

@implementation KerasScoreModel

//--------------------------------------------------------------------
- (nonnull instancetype)initWithModel:(nn_score *)kerasModel
{
    self = [super init];
    if (self) {
        _model = kerasModel;
    } // if (self)
    return self;
} // initWithModel()

// Return a one channel MLMultiArray of size 361 with probabilities that this
// intersection is colored white.
// Input array of size 361, 0~Black, 1~Empty, 2~White
//-----------------------------------------------------------------------------
- (double *) nnScorePos:(int[])pos turn:(int)turn
{
    static double wprobs[361];
    MLMultiArray *input = [self MultiArrayFromPos:pos turn:turn];
    nn_scoreInput *nn_input = [[nn_scoreInput alloc] initWithInput1:input];
    NSError *err;
    nn_scoreOutput *nnoutput = [_model predictionFromFeatures:nn_input error:&err];
    MLMultiArray *out1 = nnoutput.output1;
    double *darr = (double *)out1.dataPointer;
    memcpy( wprobs, darr, 361 * sizeof(double));
    return wprobs;
} // nnScorePos()

// Make an MLMultiArray from an array of size 361, 0~Black, 1~Empty, 2~White.
// Channel 0 == 1 for black stones, channel 1 == 1 for white stones.
// Channel 2 is the turn, all 0 for black turn, all 1 for white turn.
//------------------------------------------------------------------------------
- (MLMultiArray *) MultiArrayFromPos:(int[])pos turn:(int)turn
{
    const int BBLACK = 0;
    const int WWHITE = 2;
    
    // Get input memory
    static double *input_mem = NULL;
    if (input_mem == NULL) {
        int input_size = 3 * 361 * sizeof(double);
        input_mem = malloc( input_size);
    }

    // Make input MLMultiArray
    NSArray *shape = @[@(3), @(BOARD_SZ), @(BOARD_SZ)];
    NSArray *strides = @[@(BOARD_SZ * BOARD_SZ), @(BOARD_SZ), @(1)];
    MLMultiArray *res = [[MLMultiArray alloc] initWithDataPointer:input_mem
                                                            shape:shape
                                                         dataType:MLMultiArrayDataTypeDouble
                                                          strides:strides
                                                      deallocator:^(void * _Nonnull bytes) {}
                                                            error:nil];

    // Black stones
    ILOOP( 361) {
        input_mem[i] = (pos[i] == BBLACK) ? 1.0 : 0.0;
    }
    // White stones
    ILOOP( 361) {
        input_mem[361 + i] = (pos[i] == WWHITE) ? 1.0 : 0.0;
    }
    // Turn
    ILOOP( 361) {
        input_mem[2 * 361 + i] = turn?1.0:0.0;
    }
    return res;
} // MultiArrayFromPos()

//------------------------------------
+ (double *) test:(int**)pos_out
{
    static int pos[] = {
        2,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,0
    };
    KerasScoreModel *model = [[KerasScoreModel alloc] initWithModel: [nn_score new]];
    double *wprobs = [model nnScorePos:pos turn:0];
    *pos_out = pos;
    return wprobs;
} // test()
@end

