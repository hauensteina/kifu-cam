//
//  ImagesVC.m
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


// View Controller to export or delete saved images/diagrams

#import "Globals.h"
#import "ImagesVC.h"
#import "CppInterface.h"

#define IMGWIDTH SCREEN_WIDTH/3
#define ROWHEIGHT IMGWIDTH*1.5


// Table View Cell
//==================

@implementation ImagesCell
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
} // initWithStyle()

//------------------------
- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = self.frame;
    frame.size.height = ROWHEIGHT; // * 0.95; // - 10;
    self.frame = frame;
}

//----------------------------------------------------------------
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    self.textLabel.alpha = highlighted ? 0.5 : 1.0;
}
@end // ImagesCell


// Table View Controller
//=========================

@interface ImagesVC ()
@property (strong, nonatomic) NSArray *titlesArray;
@property long selected_row;
//@property long highlighted_row;
@property UIDocumentInteractionController *documentController;
@end

@implementation ImagesVC

//----------
- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Saved Images";
        self.view.backgroundColor = [UIColor clearColor];
        
        [self.tableView registerClass:[ImagesCell class] forCellReuseIdentifier:@"cell"];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.backgroundColor = [UIColor clearColor];
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

// Find saved files and remember their names for display. One per row.
//----------------------------------------------------------------------
- (void) loadTitlesArray
{
    self.titlesArray = globFiles( @SAVED_FOLDER, @"", @".png");
    self.titlesArray = [[self.titlesArray reverseObjectEnumerator] allObjects];
    if (_selected_row >= [_titlesArray count]) {
        _selected_row = 0;
    }
}

//-------------------------------------------
- (void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear: animated];
    //[self refresh];
}

//-------------------------------------------
- (void) viewDidAppear:(BOOL) animated
{
    [super viewDidAppear: animated];
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

// UITableViewDataSource
//========================

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
- (ImagesCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //int imgWidth = SCREEN_WIDTH / 4.0;
    int leftMarg = 40;
    int topMarg = 20;
    int space = 20;
    
    ImagesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    [[cell subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSString *fname = self.titlesArray[indexPath.row];
    // Photo
    UIImageView *imgView1 = [[UIImageView alloc]
                             initWithFrame:CGRectMake(leftMarg,topMarg,IMGWIDTH,IMGWIDTH)];
    NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    UIImage *img = [UIImage imageWithContentsOfFile:fullfname];
    NSString *sgfname = changeExtension( fullfname, @".sgf");
    NSString *sgf = [NSString stringWithContentsOfFile:sgfname encoding:NSUTF8StringEncoding error:NULL];
    imgView1.image = img;
    [cell addSubview: imgView1];
    // Diagram
    UIImageView *imgView2 = [[UIImageView alloc]
                             initWithFrame:CGRectMake(leftMarg + IMGWIDTH + space, topMarg, IMGWIDTH, IMGWIDTH)];
    UIImage *sgfImg = [CppInterface sgf2img:sgf];
    imgView2.image = sgfImg;
    [cell addSubview: imgView2];
    // Name
    UILabel *lb = [[UILabel alloc] initWithFrame:CGRectMake( leftMarg, IMGWIDTH, 250, 70)];
    lb.text = fname;
    [cell addSubview:lb];
    //cell.backgroundColor = self.view.tintColor;
    cell.backgroundColor = [UIColor clearColor];
    if (indexPath.row == _selected_row) {
        cell.backgroundColor = self.view.tintColor;
    }
    return cell;
} // cellForRowAtIndexPath()

// UITableViewDelegate
//========================

//-----------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROWHEIGHT;
} // heightForRowAtIndexPath()

// Click on saved image
//--------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selected_row = indexPath.row;
    //_highlighted_row = _selected_row;
    [self.tableView reloadData];
    NSMutableArray *choices = [@[@"Export Sgf", @"Export Photo", @"Delete", @"Cancel"] mutableCopy];
    [choices addObject:@"Rerun"];
    choicePopup( choices, @"Action",
                ^(UIAlertAction *action) {
                    [self handleEditAction:action.title];
                });
} // didSelectRowAtIndexPath()

// Action Handlers
//==================

// Handle image edit action
//---------------------------------------------
- (void)handleEditAction:(NSString *)action
{
    if ([action hasPrefix:@"Export Sgf"]) {
        [self handleExportSgf];
    }
    else if ([action hasPrefix:@"Export Photo"]) {
        [self handleExportPhoto];
    }
    else if ([action hasPrefix:@"Delete"]) {
        NSString *fname = _titlesArray[_selected_row];
        fname = getFullPath( fname);
        choicePopup( @[@"Delete",@"Cancel"], @"Really?",
                    ^(UIAlertAction *action) {
                        [self handleDeleteAction:action.title];
                    });
    }
    else if ([action hasPrefix:@"Rerun"]) {
        [self handleRerun];
    }
    else {}
} // handleEditAction()

// Delete current image
//---------------------------------------------
- (void)handleDeleteAction:(NSString *)action
{
    if (![action hasPrefix:@"Delete"]) return;
    // Delete png file
    NSString *fname = _titlesArray[_selected_row];
    rmFile( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    // Delete sgf file
    fname = changeExtension( fname, @".sgf");
    rmFile( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    [self refresh];
} // handleDeleteAction()

// Export sgf
//---------------------------
- (void)handleExportSgf
{
    NSString *fname = _titlesArray[_selected_row];
    fname = changeExtension( fname, @".sgf");
    NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    
    _documentController = [UIDocumentInteractionController
                           interactionControllerWithURL:[NSURL fileURLWithPath:fullfname]];
    [_documentController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES];
} // handleExportSgf()

// Export Photo
//---------------------------
- (void)handleExportPhoto
{
    NSString *fname = _titlesArray[_selected_row];
    fname = changeExtension( fname, @".png");
    NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    UIImage *img = [UIImage imageWithContentsOfFile:fullfname];
    NSData *jpgData = UIImageJPEGRepresentation( img, 1.0);
    fname = changeExtension( fullfname, @".jpg");
    [jpgData writeToFile:fname atomically:YES];
    _documentController = [UIDocumentInteractionController
                           interactionControllerWithURL:[NSURL fileURLWithPath:fname]];
    [_documentController presentOptionsMenuFromRect:CGRectZero inView:self.view animated:YES];
} // handleExportPhoto()

// Rerun recognition on a saved photo
//--------------------------------------
- (void)handleRerun 
{
    NSString *fname = _titlesArray[_selected_row];
    fname = changeExtension( fname, @".sgf");
    NSString *fullfname = getFullPath( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    NSString *oldsgf = [NSString stringWithContentsOfFile:fullfname encoding:NSUTF8StringEncoding error:NULL];
    int turn = DDONTKNOW;
    if ([oldsgf containsString:@"PL[W]"]) {
        turn = WWHITE;
    }
    else if ([oldsgf containsString:@"PL[B]"]) {
        turn = BBLACK;
    }
    
    fname = changeExtension( fname, @".png");
    fullfname = getFullPath( nsprintf( @"%@/%@", @SAVED_FOLDER, fname));
    UIImage *img = [UIImage imageWithContentsOfFile:fullfname];
    
    [g_app.mainVC.cppInterface clearImgQ];
    [g_app.mainVC.cppInterface qImg:img];
    [g_app.mainVC.cppInterface get_best_frame];
    NSString *sgf = [g_app.mainVC.cppInterface get_sgf];
    fname = changeExtension( fullfname, @".sgf");
    
    g_app.saveDiscardVC.photo = img;
    g_app.saveDiscardVC.sgf = sgf;
    g_app.saveDiscardVC.turn = turn;
    [g_app.navVC popViewControllerAnimated:NO];
    
    g_app.saveDiscardVC.parm_komi = [CppInterface get_sgf_tag:@"KM" sgf:oldsgf];
    g_app.saveDiscardVC.parm_handicap = [CppInterface get_sgf_tag:@"HA" sgf:oldsgf];
    [g_app.navVC pushViewController:g_app.saveDiscardVC animated:YES];
} // handleRerun()

// Other
//===========

// Name of selected png file
//----------------------------
- (NSString *)selectedFname
{
    NSString *res = _titlesArray[_selected_row];
    return res;
}



@end // ImagesVC





































