//
//  Globals.h
//  KifuCam
//
//  Created by Andreas Hauenstein on 2017-11-15.
//  Copyright © 2017 AHN. All rights reserved.
//

// App specific pervasive global stuff

#ifndef Globals_h
#define Globals_h

#ifdef __OBJC__
//----------------
#include "AppDelegate.h"
extern AppDelegate *g_app;
#endif


#ifdef __cplusplus
//---------------------
#include "Ocv.hpp"
extern std::string g_docroot;
extern cv::Mat mat_dbg;
#endif

// Always
//---------------
enum { BBLACK=0, EEMPTY=1, WWHITE=2, DDONTKNOW=3 };
#define TESTCASE_PREFIX "testcase_"
#define TESTCASE_FOLDER "testcases"
#define SAVED_FOLDER "saved"
#define S3_UPLOAD_FOLDER "uploads"
#define IMG_WIDTH 350

#endif /* Globals_h */
