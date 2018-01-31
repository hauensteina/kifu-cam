//
//  Common.m
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-10-22.
//  Copyright © 2017 AHN. All rights reserved.
//

// Generally useful convenience funcs

#import <UIKit/UIKit.h>
#import "Common.h"

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
//---------------------------------------------------------------
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
    UIAlertController * alert = [UIAlertController
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
} // popup()

// Alert with several choices
//---------------------------------------------------------------------------------------
void choicePopup (NSArray *choices, NSString *title, void(^callback)(UIAlertAction *))
{
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
} // choicePopup()

//=============
// File Stuff
//=============

// Prepend path to documents folder
//---------------------------------------------
NSString* getFullPath( NSString *fname)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fname];
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


































