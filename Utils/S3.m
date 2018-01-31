//
//  S3.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2018-01-21.
//  Copyright © 2018 AHN. All rights reserved.
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
void S3_login()
{
    if (s_credentialsProvider) return;
    s_credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                             initWithRegionType:AWSRegionUSWest2
                             identityPoolId:@"us-west-2:86844471-fec8-4356-a48d-2cb7c620b97a"];
    
    s_configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2 credentialsProvider:s_credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = s_configuration;
} // S3_login()

// Upload a file to kifu-cam bucket
//-----------------------------------------------------------------------------------------
void S3_upload_file( NSString *fname, NSString *target, void(^completion)(NSError *err))
{
    S3_login();
    NSString *fullfname = getFullPath( fname);
    NSURL *uploadingFileURL = [NSURL fileURLWithPath: fullfname];
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    
    uploadRequest.bucket = BUCKET_NAME;
    uploadRequest.key = target;
    uploadRequest.body = uploadingFileURL;
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager upload:uploadRequest]
     continueWithExecutor:[AWSExecutor mainThreadExecutor]
     withBlock:^id(AWSTask *task) {
         if (task.error) {
             if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                 switch (task.error.code) {
                     case AWSS3TransferManagerErrorCancelled:
                     case AWSS3TransferManagerErrorPaused:
                         break;
                     default:
                         NSLog(@"Error: %@", task.error);
                         //popup( nsprintf( @"S3 upload failed for %@. Error:%@", uploadRequest.key, task.error), @"Error");
                         break;
                 }
             }
             else {
                 // Unknown error.
                 //popup( nsprintf( @"S3 upload failed for %@. Error:%@", uploadRequest.key, task.error), @"Error");
                 NSLog(@"Error: %@", task.error);
             }
         } // if (task.error)
         
         if (task.result) {
             // Success
             //AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
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
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    
    downloadRequest.bucket = BUCKET_NAME;
    downloadRequest.key = key;
    downloadRequest.downloadingFileURL = downloadingFileURL;
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager download:downloadRequest ]
     continueWithExecutor:[AWSExecutor mainThreadExecutor]
     withBlock:^id(AWSTask *task) {
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

