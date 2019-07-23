//
//  FrameExtractor.m
//  KifuCam
//
// The MIT License (MIT)
//
// Copyright (c) 2018 Andreas Hauenstein <hauensteina@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

//  Adapted from Boris Ohayon: IOS Camera Frames Extraction

#import "FrameExtractor.h"

//==============================
@interface FrameExtractor()
@property AVCaptureDevicePosition position;
@property AVCaptureSessionPreset quality;
@property AVCaptureSession *captureSession;
@property bool permissionGranted;
@property dispatch_queue_t sessionQ;
@property dispatch_queue_t bufferQ;

@end

//===============================
@implementation FrameExtractor

//---------------------
- (instancetype)init
{
    self = [super init];
    if (self) {
        _suspended = false;
        self.permissionGranted = false;
        self.position = AVCaptureDevicePositionFront;
        self.quality = AVCaptureSessionPresetMedium;
        self.captureSession = [AVCaptureSession new];
        self.sessionQ = dispatch_queue_create("com.ahaux.sessionQ", DISPATCH_QUEUE_SERIAL);
        self.bufferQ  = dispatch_queue_create("com.ahaux.bufferQ",  DISPATCH_QUEUE_SERIAL);
        [self checkPermission];
        dispatch_async(self.sessionQ, ^{
            [self configureSession];
            [self.captureSession startRunning];
        });
    }
    return self;
}

#pragma mark - AVSession config
//--------------------------
- (void)checkPermission
{
    switch( [AVCaptureDevice authorizationStatusForMediaType: AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            self.permissionGranted = true;
            break;
        case AVAuthorizationStatusNotDetermined:
            dispatch_suspend(self.sessionQ);
            [self requestPermission];
            break;
        default:
            self.permissionGranted = false;
    }
} // checkPermission()

//----------------------------
- (void)requestPermission
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler: ^(BOOL granted) {
                                 self.permissionGranted = granted;
                                 dispatch_resume(self.sessionQ);
                             }];
}

//--------------------------
- (void)configureSession
{
    if (!self.permissionGranted) return;
    [self.captureSession setSessionPreset:self.quality];
    AVCaptureDevice *captureDevice = [self selectCaptureDevice];
        
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    if (![self.captureSession canAddInput:captureDeviceInput]) {
        return;
    }
    [self.captureSession addInput:captureDeviceInput];
    AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
    [videoOutput setSampleBufferDelegate:self queue:self.bufferQ];
    if (![self.captureSession canAddOutput:videoOutput]) {
        return;
    }
    [self.captureSession addOutput:videoOutput];
    AVCaptureConnection *connection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeStandard;
}

//-----------------------------------------
- (AVCaptureDevice *)selectCaptureDevice
{
    AVCaptureDevice *res = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    return res;
}

// Stop capturing frames while we're busy
//-------------------------------------------
- (void) suspend
{
    if (_suspended) return;
    _suspended = true;
    dispatch_suspend( self.bufferQ);
}

// Resume capturing frames
//--------------------------
- (void) resume
{
    if (!_suspended) return;
    dispatch_resume( self.bufferQ);
    _suspended = false;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
//------------------------------------------------------------
- (void) captureOutput:(AVCaptureOutput * ) captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef ) sampleBuffer
        fromConnection:(AVCaptureConnection * ) connection
{
    static bool s_suspended = false;
    if (sampleBuffer == NULL) return;
    if (_suspended || s_suspended) return;
    s_suspended = true;
    [self suspend];

    // UIImage from samplebuffer. Bullshit Nonsense Nightmare.
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress( imageBuffer,0);
    if (imageBuffer == NULL) return;
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
    if (ciImage == NULL) return;
    CIContext *context = [[CIContext alloc] initWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CVPixelBufferUnlockBaseAddress( imageBuffer,0);
    if (uiImage == NULL) return;
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
//                       CGImageRef newCgIm = CGImageCreateCopy( uiImage.CGImage);
//                       UIImage *imgCopy = [UIImage imageWithCGImage:newCgIm scale:uiImage.scale orientation:uiImage.imageOrientation];
                       if (uiImage != NULL) {
                           [self.delegate captured:uiImage];
                       }
//                       CGImageRelease( newCgIm);
                       CFRelease(cgImage);
                       s_suspended = false;
                   });
}

@end





