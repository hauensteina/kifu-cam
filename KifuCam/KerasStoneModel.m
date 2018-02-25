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
@property MLModel *model;
@property VNCoreMLModel *m;    // The Vision framework wrapper for Keras model
@property VNCoreMLRequest *rq; // The request to the classifier
@property int classification_result;
@end

@implementation KerasStoneModel

//------------------------------------------------------------
- (nonnull instancetype)initWithModel:(MLModel *)kerasModel
{
    self = [super init];
    if (self) {
        _model = kerasModel;
        _m = [VNCoreMLModel modelForMLModel: _model error:nil];
        _rq = [[VNCoreMLRequest alloc] initWithModel: _m
                                   completionHandler:
               (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error)
               {
                   NSArray *results = request.results; // [request.results copy];
                   VNClassificationObservation *topResult = ((VNClassificationObservation *)(results[0]));
                   NSString *identifier = topResult.identifier;
                   char class = [identifier characterAtIndex:0];
                   if (class == 'b') _classification_result = BBLACK;
                   else if (class == 'e') _classification_result = EEMPTY;
                   else if (class == 'w') _classification_result = WWHITE;
                   else _classification_result = DDONTKNOW;
                   NSLog( @"req completed id:%@", identifier);
               }];
    } // if (self)
    return self;
} // initWithModel()

// Classify a crop with one intersection at the center
//---------------------------------------------------------
- (int) classify: (CIImage *)image
{
    NSArray *a = @[_rq];
    NSDictionary *d = [[NSDictionary alloc] init];
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:image options:d];
    NSLog( @"request");
    [handler performRequests:a error:nil];
    return _classification_result;
} // classify()

@end
