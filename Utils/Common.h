//
//  Common.hpp
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-10-21.
//  Copyright © 2017 AHN. All rights reserved.
//

// Generally useful convenience funcs to be included by Obj-C and Obj-C++ files.
// Pure C++ files should not include this

#import <UIKit/UIKit.h>
#import "Common.hpp"

#ifdef __cplusplus
extern "C" {
#endif
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
    // Get current local timestamp in a dictionary
    NSDictionary* dateAsDict(void);
    // Make a filename from current date and time
    NSString *tstampFname(void);

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
    
    // Persisted settings
    //=====================
    // Set a string property in the user defaults
    void setProp( NSString *key, NSString *value);
    // Get a string property in the user defaults.
    NSString* getProp( NSString *key, NSString *defaultVal);

#ifdef __cplusplus
}
#endif





