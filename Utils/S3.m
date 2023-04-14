//
//  S3.m
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

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import <AWSS3/AWSS3.h>
#import "Common.h"

#define BUCKET_NAME @"kifu-cam"
static AWSCognitoCredentialsProvider *s_credentialsProvider = nil;
static AWSServiceConfiguration *s_configuration = nil;

// Authenticate with AWS for access to kifu-cam bucket
//-------------------------------------------------------
void S3_login(void)
{
    if (s_credentialsProvider) return;
    s_credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                             initWithRegionType:AWSRegionUSWest2
                             identityPoolId:@"us-west-2:86844471-fec8-4356-a48d-2cb7c620b97a"];
    
    s_configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2 credentialsProvider:s_credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = s_configuration;
} // S3_login()

// Upload a file to kifu-cam bucket
//---------------------------------------------------------
void S3_upload_file( NSString *fname, NSString *target,
                    void(^completion)(NSError *err))
{
    S3_login();
    NSString *fullfname = getFullPath( fname);
    NSURL *uploadingFileURL = [NSURL fileURLWithPath: fullfname];
    NSString *ext = [uploadingFileURL pathExtension];
    
    NSString *content_type = @"text/plain";
    if ([ext isEqualToString:@"png"]) {
        content_type = @"image/png";
    }
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    [[transferUtility uploadFile:uploadingFileURL
                         bucket:BUCKET_NAME
                            key:target
                    contentType:content_type
                     expression:nil
              completionHandler:nil]
    continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            NSLog(@"Error: %@", task.error);
        }
        if (task.result) {
            // success
            //AWSS3TransferUtilityUploadTask *uploadTask = task.result;
        }
        completion( task.error);
        return nil;
    }];
} // S3_upload_file()


// List files in kifu-cam bucket. Filter by prefix and extension.
// Returns at most 1000 keys.
//--------------------------------------------------------------------------------------------------
void S3_glob( NSString *prefix, NSString *ext, NSMutableArray *res, void(^completion)(NSError *err))
{
    S3_login();
    [AWSS3 registerS3WithConfiguration:s_configuration forKey:@"defaultKey"];
    AWSS3 *s3 = [AWSS3 S3ForKey:@"defaultKey"];
    AWSS3ListObjectsV2Request *req = [AWSS3ListObjectsV2Request new];
    req.bucket = BUCKET_NAME;
    req.prefix = prefix;
    [[s3 listObjectsV2:req] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            //popup( nsprintf( @"S3_glob failed: %@", task.error), @"Error");
        }
        else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            for (AWSS3Object *s3Object in listObjectsOutput.contents) {
                NSString *fname = s3Object.key;
                NSString *fext = nscat( @".", [fname pathExtension]);
                if (![ext isEqualToString:fext]) continue;
                [res addObject: fname];
            } // for
        } // else
        completion( task.error);
        return nil;
    }]; // [[s3 listObjectsV2
} // S3_glob()

// Download the object at key into local fname
//---------------------------------------------------------------------------------------
void S3_download_file( NSString *key, NSString *fname, void(^completion)(NSError *err))
{
    NSString *fullfname = getFullPath( fname);
    NSURL *downloadingFileURL = [NSURL fileURLWithPath:fullfname];
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    [[transferUtility downloadToURL:downloadingFileURL
                             bucket:BUCKET_NAME
                                key:key
                         expression:nil
                  completionHandler:nil]
     continueWithBlock:^id(AWSTask *task) {
        if (task.error){
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                        
                    default:
                        NSLog(@"Error: %@", task.error);
                        //popup( nsprintf( @"S3 downl failed for %@. Error:%@", downloadRequest.key, task.error), @"Error");
                        break;
                }
            }
            else {
                // Unknown error.
                //popup( nsprintf( @"S3 download failed for %@. Error:%@", downloadRequest.key, task.error), @"Error");
                NSLog(@"Error: %@", task.error);
            }
        } // if (task.error)
        if (task.result) {
            // Success
            //AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
        }
        completion( task.error);
        return nil;
    }];
} // S3_download_file()

