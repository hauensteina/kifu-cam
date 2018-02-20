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
#import <Vision/Vision.h>

@interface KerasStoneModel()
//================================
@property MLModel *model;
@property VNCoreMLModel *m;    // The Vision framework wrapper for Keras model
@property VNCoreMLRequest *rq; // The request to the classifier
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
                   dispatch_async(dispatch_get_main_queue(), ^{
                       //NSTimeInterval start, stop;
                       //stop = [[NSDate date] timeIntervalSince1970];
                       //start = [[startTimes objectAtIndex: 0] doubleValue];
                       //[startTimes removeObjectAtIndex: 0];
                       // NSLog(@"diff: %ld, %f\n", [startTimes count], (stop - start) * 1000);
                       //self.messageLabel.text = @"done";
                       //self.numberOfResults = request.results.count;
                       NSArray *results = [request.results copy];
                       VNClassificationObservation *topResult = ((VNClassificationObservation *)(results[0]));
                       int tt = 42;
                   });
               }];
    } // if (self)
    return self;
} // initWithModel()

// Classify a crop with one intersection at the center
//---------------------------------------------------------
- (void) classify: (CIImage *)image
{
    //NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    //[startTimes addObject: [NSNumber numberWithDouble: start]];
    NSArray *a = @[_rq];
    NSDictionary *d = [[NSDictionary alloc] init];
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:image options:d];
    //dispatch_sync(dispatch_get_main_queue(), ^{
        [handler performRequests:a error:nil];
    //});
    int tt = 42;
} // classify()

@end
