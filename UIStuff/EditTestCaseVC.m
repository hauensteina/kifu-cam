//
//  EditTestCaseVC.m
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

// View Controller to edit/run/upload/download test cases


#import "Globals.h"
#import "EditTestCaseVC.h"
#import "CppInterface.h"

#define IMGWIDTH SCREEN_WIDTH/3
#define ROWHEIGHT IMGWIDTH*1.5

// Table View Cell
//=============================================
@implementation EditTestCaseCell
//-------------------------------------------------------------------------------------------------------
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        self.textLabel.textColor = [UIColor whiteColor];
        self.textLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

//------------------------
- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.frame;
    frame.size.height = ROWHEIGHT;
    self.frame = frame;
}

//----------------------------------------------------------------
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    self.textLabel.alpha = highlighted ? 0.5 : 1.0;
}
@end // EditTestCaseCell


// Table View Controller
//=====================================================
@interface EditTestCaseVC ()
@property (strong, nonatomic) NSArray *titlesArray;
@property long selected_row;
@property long highlighted_row;
@end

@implementation EditTestCaseVC

//----------
- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        
        [self.tableView registerClass:[EditTestCaseCell class] forCellReuseIdentifier:@"cell"];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.backgroundColor = [UIColor clearColor];
        //self.tableView.rowHeight = 150;
        [self loadTitlesArray];
    }
    return self;
}

//---------------------------------------
- (void)refresh
{
    [self loadTitlesArray];
    [self.tableView reloadData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

// Find testcase files and remember their names for display. One per row.
//-------------------------
- (void) loadTitlesArray
{
    self.titlesArray = globFiles( @TESTCASE_FOLDER, @TESTCASE_PREFIX, @".png");
    if (_selected_row >= [_titlesArray count]) {
        _selected_row = 0;
    }
    if ([_titlesArray count]) {
        self.selectedTestCase = _titlesArray[_selected_row];
    }
}

//-------------------------------------------
- (void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear: animated];
    [self refresh];
}
//-------------------------------
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
//--------------------------------------------
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}
//-----------------------------------------------------------
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}
#pragma mark - UITableViewDataSource
//-----------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
//------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titlesArray.count;
}

//------------------------------------------------------------------------------------------------------
- (EditTestCaseCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int leftMarg = 40;
    int topMarg = 20;
    int space = 20;

    EditTestCaseCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    [[cell subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSString *fname = self.titlesArray[indexPath.row];
    NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname));
    NSString *sgfname = changeExtension( fullfname, @".sgf");
    NSString *sgf = [NSString stringWithContentsOfFile:sgfname encoding:NSUTF8StringEncoding error:NULL];
    // Photo
    UIImageView *imgView1 = [[UIImageView alloc] initWithFrame:CGRectMake(leftMarg,topMarg,IMGWIDTH,IMGWIDTH)];
    UIImage *img = [UIImage imageWithContentsOfFile:fullfname];
    if (!sgf) {
        sgf = [g_app.mainVC.cppInterface get_sgf_for_img:img];
        [g_app.mainVC.cppInterface save_current_sgf:sgfname overwrite:YES];
    }
    imgView1.image = img;
    [cell addSubview: imgView1];
    // Diagram
    UIImageView *imgView2 = [[UIImageView alloc] initWithFrame:CGRectMake(leftMarg + IMGWIDTH + space, topMarg, IMGWIDTH, IMGWIDTH)];
    UIImage *sgfImg = [CppInterface sgf2img:sgf];
    imgView2.image = sgfImg;
    [cell addSubview: imgView2];
    // Name
    UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake(leftMarg, IMGWIDTH, 250,70)];
    lb.text = fname;
    [cell addSubview:lb];
    //cell.backgroundColor = self.view.tintColor;
    cell.backgroundColor = [UIColor clearColor];
    if (indexPath.row == _highlighted_row) {
        cell.backgroundColor = self.view.tintColor;
    }
    return cell;
}
#pragma mark - UITableViewDelegate
//-----------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROWHEIGHT;
}

// Click on Test Case
//--------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selected_row = indexPath.row;
    NSArray *choices = @[@"Select", @"Pair with current position", @"Rerun", @"Delete", @"Cancel"];
    choicePopup( choices, @"Action",
                ^(UIAlertAction *action) {
                    [self handleEditAction:action.title];
                });
}

// Handle test case edit action
//---------------------------------------------
- (void)handleEditAction:(NSString *)action
{
    if ([action hasPrefix:@"Select"]) {
        [self handleSelect];
    }
    else if ([action hasPrefix:@"Pair with current position"]) {
        [self handlePairWithCurrent];
    }
    else if ([action hasPrefix:@"Rerun"]) {
        [self handleRerun];
    }
    else if ([action hasPrefix:@"Delete"]) {
        NSString *fname = _titlesArray[_selected_row];
        fname = getFullPath( fname);
        choicePopup(@[@"Delete",@"Cancel"], @"Really?",
                    ^(UIAlertAction *action) {
                        [self handleDeleteAction:action.title];
                    });
    }
    else {}
} // handleEditAction()

// Delete current test case
//---------------------------------------------
- (void)handleDeleteAction:(NSString *)action
{
    if (![action hasPrefix:@"Delete"]) return;
    // Delete png file
    NSString *fname = _titlesArray[_selected_row];
    rmFile( nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname));
    // Delete sgf file
    fname = changeExtension( fname, @".sgf");
    rmFile( nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname));
    [self refresh];
} // handleDeleteAction()

// Set current test case
//--------------------------
- (void)handleSelect
{
    NSString *fname = _titlesArray[_selected_row];
    _selectedTestCase = fname;
    _highlighted_row = _selected_row;
    //popup( nsprintf( @"%@ selected", fname), @"");
    //[self refresh];
    [g_app.navVC popViewControllerAnimated:YES];
    [g_app.menuVC gotoDebugMode];
} // handleSelect()

// Pair current test png with sgf from selected image/sgf
// This is a way of editing test case sgfs by taking a picture
// of a board with that position.
//--------------------------------------------------------------
- (void)handlePairWithCurrent
{
    // Get test case sgf file name
    NSString *testFname = _titlesArray[_selected_row];
    testFname = changeExtension( testFname, @".sgf");
    testFname = nsprintf( @"%@/%@", @TESTCASE_FOLDER, testFname);
    
    // Get selected sgf filename
    NSString *selectedFname = [g_app.imagesVC selectedFname];
    selectedFname = changeExtension( selectedFname, @".sgf");
    selectedFname = nsprintf( @"%@/%@", @SAVED_FOLDER, selectedFname);
    
    // Copy over
    copyFile( selectedFname, testFname);
    [self refresh];
} // handlePairWithCurrent()

// Rerun recognition on a testcase
//-----------------------------------
- (void)handleRerun
{
    NSString *fname = _titlesArray[_selected_row];
    fname = changeExtension( fname, @".png");
    NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @TESTCASE_FOLDER, fname));
    UIImage *img = [UIImage imageWithContentsOfFile:fullfname];
    
    [g_app.mainVC.cppInterface clearImgQ];
    [g_app.mainVC.cppInterface qImg:img];
    [g_app.mainVC.cppInterface get_best_frame];
    NSString *sgfname = changeExtension( fullfname, @".sgf");
    [g_app.mainVC.cppInterface save_current_sgf:sgfname overwrite:YES];

    [self refresh];
} // handleRerun()

@end // EditTestCaseVC












































