//
//  Common.hpp
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

// Generally useful convenience funcs to be included by Obj-C and Obj-C++ files.
// Pure C++ files should not include this

#import <UIKit/UIKit.h>
#import "Common.hpp"

#pragma clang diagnostic ignored "-Wunguarded-availability"

#ifdef __cplusplus
extern "C" {
#endif

    //=========
    // System
    //=========
    // Get device platform, eg @"iPhone8,1" or @"iPad4,8"
    NSString* platform(void);
    // @"iPhone8,1" -> 8, @"iPad4,8" -> 0
    int iPhoneVersion(void);
    
    // Drawing
    //==========
    // Draw a massive rectangle on a view
    void drawRect( UIView *view, UIColor *color, int x, int y, int width, int height);

    // Strings
    //==========
    // Shorten NSString NStringWithFormat
    NSString *nsprintf (NSString *format, ...);
    // Concatenate any two objects into one string
    NSString *nscat (id a, id b);
    // Replace regular expression
    NSString* replaceRegex( NSString *re, NSString *str, NSString *newStr);

    // Date
    //=========
    // Get current local date as yyyy-mm-dd
    NSString *localDateStamp(void);
    // Get current local time as yyyy-mm-dd-hhmmss
    NSString *localTimeStamp(void);
    // Get current local timestamp in a dictionary
    NSDictionary* dateAsDict(void);
    // Make a filename from current date and time
    NSString* tstampFname(void);

    // Files
    //=========
    // Prepend path to documents folder
    NSString* getFullPath( NSString *fname);
    // Change filename extension
    NSString* changeExtension( NSString *fname, NSString *ext);
    // Find a file in the main bundle
    NSString* findInBundle( NSString *basename, NSString *ext);
    // List files in folder, filter by extension and prefix, sort
    NSArray* globFiles( NSString *path, NSString *prefix, NSString *ext);
    // Make a folder below the document dir
    void makeDir( NSString *dir);
    // Remove file below document dir
    void rmFile( NSString *fname);
    // Check whether folder exists
    bool dirExists( NSString *path);
    // Check whether file exists
    bool fileExists( NSString *path);
    // Copy file
    void copyFile( NSString *source, NSString *target);

    // User Interface
    //==================
    // Popup notification
    void popup (NSString *msg, NSString *title);
    // Alert with several choices
    void choicePopup (NSArray *choices, NSString *title, void(^callback)(UIAlertAction *));
    // Make a text label clickable
    void makeLabelClickable (UILabel *lb, id target, SEL action);

    // Persisted settings
    //=====================
    // Set a string property in the user defaults
    void setProp( NSString *key, NSString *value);
    // Get a string property in the user defaults.
    NSString* getProp( NSString *key, NSString *defaultVal);
    
    // Json
    //=========
    // Parse Json into an NSObject
    id parseJSON( NSString *json);

#ifdef __cplusplus
}
#endif





