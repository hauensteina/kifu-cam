//
//  Globals.h
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
