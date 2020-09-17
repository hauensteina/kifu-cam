//
//  Common.m
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

// Generally useful convenience funcs

#import <UIKit/UIKit.h>
#import "Common.h"

#include <sys/types.h>
#include <sys/sysctl.h>

//=========
// System
//=========

// Get device platform, eg @"iPhone8,1" or @"iPad4,8"
//----------------------------------------------------
NSString* platform()
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

// @"iPhone8,1" -> 8, @"iPad4,8" -> 0
//-------------------------------------
int iPhoneVersion()
{
    NSString *platf = platform();
    if (![platf hasPrefix:@"iPhone"]) {
        return 0;
    }
    NSString *tstr = replaceRegex( @"[a-zA-Z]*", platf, @"");
    tstr = replaceRegex( @",.*", tstr, @"");
    int res = atoi([tstr UTF8String]);
    return res;
} // iPhoneVersion()

// @"iPad6,12" -> 6, @"iPhone4,8" -> 0
//-------------------------------------
int iPadVersion()
{
    NSString *platf = platform();
    if (![platf hasPrefix:@"iPad"]) {
        return 0;
    }
    NSString *tstr = replaceRegex( @"[a-zA-Z]*", platf, @"");
    tstr = replaceRegex( @",.*", tstr, @"");
    int res = atoi([tstr UTF8String]);
    return res;
} // iPadVersion()

//==========
// Math
//==========
int sign(double f) { return (f < 0) ? -1 : 1; }

//==========
// Drawing
//==========
// Draw a massive rectangle on a view
//--------------------------------------------------------------------------------
void drawRect( UIView *view, UIColor *color, int x, int y, int width, int height)
{
    UIView *myBox  = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    myBox.backgroundColor = color;
    [view addSubview:myBox];
}

// Draw a filled circle on a UIImage. On main thread because using UIKit
//-------------------------------------------------------------------------------
UIImage* drawCircleOnImg( UIImage *image, int x, int y, int d, UIColor *col)
{
    // begin a graphics context of sufficient size
    UIGraphicsBeginImageContext(image.size);
    // draw original image into the context
    [image drawAtPoint:CGPointZero];
    // get the context for CoreGraphics
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    // set stroking color and draw circle
    [col setStroke];
    CGRect circleRect = CGRectMake( x - d/2, y - d/2,
                                   d, d);
    //circleRect = CGRectInset(circleRect, x, y);
    // draw filled circle
    CGContextSetFillColorWithColor(ctx, col.CGColor);
    CGContextFillEllipseInRect(ctx, circleRect);
    // make image out of bitmap context
    UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
    // free the context
    UIGraphicsEndImageContext();
    
    return retImage;
} // drawCircleOnImg()

//==========
// Strings
//==========

// Replacement for annoying [NSString stringWithFormat ...
//---------------------------------------------------------
NSString* nsprintf (NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *msg =[[NSString alloc] initWithFormat:format
                                          arguments:args];
    return msg;
}

// Concatenate two NSStrings
//-----------------------------
NSString *nscat (id a, id b)
{
    return [NSString stringWithFormat:@"%@%@",a,b];
}

// Replace substring target with repl in source
//---------------------------------------------------------------------------
NSString* replaceStr( NSString *target, NSString *repl, NSString *source)
{
    NSString *res = [source stringByReplacingOccurrencesOfString:target
                                                      withString:repl];
    return res;
} // replaceStr()

// Replace regular expression
//----------------------------------------------------------------------
NSString* replaceRegex( NSString *re, NSString *str, NSString *newStr)
{
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:re
                                  options:0
                                  error:nil];
    NSString *res = [regex stringByReplacingMatchesInString:str
                                                    options:0
                                                      range:NSMakeRange(0, [str length])
                                               withTemplate:newStr];
    return res;
} // replaceRegex()


//=========
// Date
//=========

// Get current local date as yyyy-mm-dd
//----------------------------------------------
NSString *localDateStamp()
{
    time_t rawtime;
    struct tm *info;
    rawtime = time(NULL);
    info = localtime( &rawtime );
    NSString *res = nsprintf( @"%04d-%02d-%02d", info->tm_year + 1900, info->tm_mon + 1, info->tm_mday);
    return res;
} // localDateStamp()

// Get current local time as yyyy-mm-dd-hhmmss
//----------------------------------------------
NSString *localTimeStamp()
{
    time_t rawtime;
    struct tm *info;
    rawtime = time(NULL);
    info = localtime( &rawtime );
    NSString *res = nsprintf( @"%04d-%02d-%02d-%02d%02d%02d",
                             info->tm_year + 1900, info->tm_mon + 1, info->tm_mday,
                             info->tm_hour, info->tm_min, info->tm_sec);
    return res;
} // localTimeStamp()

// Get current local timestamp in a dictionary
//----------------------------------------------
NSDictionary* dateAsDict()
{
    time_t rawtime;
    struct tm *info;
    rawtime = time(NULL);
    info = localtime( &rawtime );
    return @{@"year":@(info->tm_year + 1900)
             ,@"month":@(info->tm_mon + 1)
             ,@"day":@(info->tm_mday)
             ,@"hour":@(info->tm_hour)
             ,@"minute":@(info->tm_min)
             ,@"second":@(info->tm_sec)
             };
} // dateAsDict()

// Make a filename from current date and time
//-----------------------------------------------
NSString *tstampFname()
{
    NSDictionary *tstamp = dateAsDict();
    NSString *fname = nsprintf( @"%4d%02d%02d-%02d%02d%02d",
                               [tstamp[@"year"] intValue],
                               [tstamp[@"month"] intValue],
                               [tstamp[@"day"] intValue],
                               [tstamp[@"hour"] intValue],
                               [tstamp[@"minute"] intValue],
                               [tstamp[@"second"] intValue]);
    return fname;
}

//=============
// UI Helpers
//=============

// Popup with message and OK button
//-----------------------------------------------
void popup (NSString *msg, NSString *title)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:title
                                    message:msg
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"OK"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
        }];
        [alert addAction:yesButton];
    
        UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [vc presentViewController:alert animated:YES completion:nil];
    });
} // popup()

// Alert with several choices
//---------------------------------------------------------------------------------------
void choicePopup (NSArray *choices, NSString *title, void(^callback)(UIAlertAction *))
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:title
                                    message:@""
                                    preferredStyle:UIAlertControllerStyleAlert];
        for (NSString *str in choices) {
            UIAlertAction *button =  [UIAlertAction
                                      actionWithTitle:str
                                      style:UIAlertActionStyleDefault
                                      handler:callback];
            [alert addAction:button];
        }
        
        UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [vc presentViewController:alert animated:YES completion:nil];
    });
} // choicePopup()

// Make a text label clickable
//-----------------------------------------------------------
void makeLabelClickable (UILabel *lb, id target, SEL action)
{
    UITapGestureRecognizer* gesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    // if labelView is not set userInteractionEnabled, you must do so
    [lb setUserInteractionEnabled:YES];
    [lb addGestureRecognizer:gesture];
}

//=============
// File Stuff
//=============

// Prepend path to documents folder
//---------------------------------------------
NSString* getFullPath( NSString *fname)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = fname;
    if (![fname hasPrefix:documentsDirectory]) {
        filePath = [documentsDirectory stringByAppendingPathComponent:fname];
    }
    return filePath;
}

// Change filename extension
//----------------------------------------------------------
NSString* changeExtension( NSString *fname, NSString *ext)
{
    NSString *res = [fname stringByDeletingPathExtension];
    res = nscat( res, ext);
    return res;
}

// Find a file in the main bundle
//----------------------------------
NSString* findInBundle( NSString *basename, NSString *ext)
{
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* path = [myBundle pathForResource:basename ofType:ext];
    return path;
}

// List files in folder, filter by extension, sort
//------------------------------------------------------------------------
NSArray* globFiles( NSString *path_, NSString *prefix, NSString *ext)
{
    id fm = [NSFileManager defaultManager];
    NSString *path = getFullPath( path_);
    NSArray *files =
    [fm contentsOfDirectoryAtPath:path error:nil];
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"SELF like[c] %@", nsprintf( @"%@*%@", prefix, ext)];
    files = [files filteredArrayUsingPredicate:predicate];
    files = [files sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return files;
} // globFiles()

// Make a folder below the document dir
//----------------------------------------
void makeDir( NSString *dir)
{
    NSString *path = getFullPath( dir);
    [[NSFileManager defaultManager] createDirectoryAtPath: path
                              withIntermediateDirectories: YES
                                               attributes: nil
                                                    error: nil];
}

// Remove file below document dir
//--------------------------------
void rmFile( NSString *fname)
{
    NSString *fullfname = getFullPath( fname);
    NSError *error;
    [[NSFileManager defaultManager]  removeItemAtPath:fullfname error:&error];
}

// Copy file
//---------------------------------------------------
void copyFile( NSString *source_, NSString *target_)
{
    NSString *source = getFullPath( source_);
    NSString *target = getFullPath( target_);
    NSError *error;
    rmFile( target_);
    [[NSFileManager defaultManager] copyItemAtPath:source toPath:target error:&error];
} // copyFile()

// Check whether folder exists
//-----------------------------------
bool dirExists( NSString *path_)
{
    NSString *path = getFullPath( path_);
    BOOL isDir;
    BOOL fileExists = [[NSFileManager defaultManager]  fileExistsAtPath:path isDirectory:&isDir];
    return (fileExists && isDir);
}

// Check whether file exists
//-----------------------------------
bool fileExists( NSString *path_)
{
    NSString *path = getFullPath( path_);
    BOOL isDir;
    BOOL fileExists = [[NSFileManager defaultManager]  fileExistsAtPath:path isDirectory:&isDir];
    return (fileExists && !isDir);
}

//=====================
// Persisted settings
//=====================

// Set a string property in the user defaults
//-----------------------------------------------------------------------
void setProp( NSString *key, NSString *value)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
} // setProp()

// Get a string property in the user defaults.
// Return default if not found.
//-----------------------------------------------------------------------
NSString* getProp( NSString *key, NSString *defaultVal)
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *val = [defaults objectForKey:key];
    if (!val) {
        return defaultVal;
    }
    return val;
} // getProp()

//=====================
// JSON
//=====================

// Parse Json into an NSObject
//-----------------------------------------
id parseJSON( NSString *json)
{
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    id objFromJson = [NSJSONSerialization JSONObjectWithData:data
                                                     options:0
                                                       error:&err];
    if (!objFromJson) {
        NSLog( @"Error parsing JSON: %@", json);
    }
    return objFromJson;
} // parseJSON()

//========
// Misc
//========

// Convert terrmap in NSArray of NSNumber into double array
//------------------------------------------------------------
double* cterrmap( NSArray *terrmap_in)
{
    static double terrmap_out[19 * 19];
    int i = 0;
    for (NSNumber *p in terrmap_in) {
        terrmap_out[i++] = [p doubleValue];
    } // for
    return terrmap_out;
} // cterrmap()




























