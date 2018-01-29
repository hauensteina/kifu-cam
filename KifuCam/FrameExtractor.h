//
//  FrameExtractor.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-10-20.
//  Copyright © 2017 AHN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//==================================
@protocol FrameExtractorDelegate
- (void)captured:(UIImage *)image;
@end

//====================================================================================
@interface FrameExtractor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property id<FrameExtractorDelegate> delegate;
@property CGRect imgExtent;
@property (readonly) bool suspended;

- (void) suspend; // Suspend capturing frames
- (void) resume;  // Resume capturing frames

@end
