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

//------------------------------------------------------------
- (nonnull instancetype)initWithModel:(nn_bew *)kerasModel
{
    self = [super init];
    if (self) {
        _model = kerasModel;
    } // if (self)
    return self;
} // initWithModel()

//-----------------------------------------------------------
- (UIImage *) pixbuf2UIImg:(CVPixelBufferRef)pixelBuffer
{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(pixelBuffer),
                                                 CVPixelBufferGetHeight(pixelBuffer))];
    
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return uiImage;
} // pixbuf2UIImg()

//---------------------------------------------------
- (CVPixelBufferRef) img2pixbuf:(CIImage *)img
{
    CVPixelBufferRef res = NULL;
    CVReturn status = CVPixelBufferCreate( kCFAllocatorDefault,
                                          img.extent.size.width,
                                          img.extent.size.height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) @{(__bridge NSString *) kCVPixelBufferIOSurfacePropertiesKey: @{}},
                                          &res);
    
    if (status != kCVReturnSuccess) {
        NSLog( @"failed to make pixelbuf. Status: %d", status);
        return nil;
    }
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    [ciContext render:img toCVPixelBuffer:res];
    return res;
}

// Classify a crop with one intersection at the center
//---------------------------------------------------------
- (int) classify: (MLMultiArray *)image
{
    //CVPixelBufferRef pixbuf = [self img2pixbuf:image];
    //(void)(pixbuf);
    //_dbgimg = [self pixbuf2UIImg:pixbuf];
    nn_bewInput *nninput = [[nn_bewInput alloc] initWithInput1:image];
    //(void)(nninput);
    NSError *err;
    nn_bewOutput *nnoutput = [_model predictionFromFeatures:nninput error:&err];
    //CVPixelBufferRelease( pixbuf);
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
