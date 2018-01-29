//
//  LeftViewController.m
//  LGSideMenuControllerDemo
//

#import "Globals.h"
#import "CppInterface.h"
#import "LeftMenuController.h"
#import "LeftMenuCell.h"
#import "S3.h"
#import "TopViewController.h"
#import "UIViewController+LGSideMenuController.h"

enum {ITEM_NOT_SELECTED=0, ITEM_SELECTED=1};
enum {VIDEO_MODE=0, PHOTO_MODE=1, DEBUG_MODE=2, DEMO_MODE=3};

@interface LeftMenuController ()
@property (strong, nonatomic) NSMutableArray *titlesArray;
@property UIFont *normalFont;
@property UIFont *selectedFont;
@property int mode; // debug, video, photo mode
@end

@implementation LeftMenuController

// Initialize left menu
//-----------------------
- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _selectedFont = [UIFont fontWithName:@"Verdana-Bold" size:16 ];
        _normalFont = [UIFont fontWithName:@"Verdana" size:16 ];
        NSArray *d = @[
                       @{ @"txt": @"Video Mode", @"state": @(ITEM_SELECTED) },
                       @{ @"txt": @"Photo Mode", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Demo Mode", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"", @"state": @(ITEM_NOT_SELECTED) },
                       @{ @"txt": @"Saved Images", @"state": @(ITEM_NOT_SELECTED) },
                       ];
        _titlesArray = [NSMutableArray new];
        for (NSDictionary *x in d) { [_titlesArray addObject:[x mutableCopy]]; }
        
        self.view.backgroundColor = [UIColor clearColor];

        [self.tableView registerClass:[LeftMenuCell class] forCellReuseIdentifier:@"cell"];
        self.tableView.separatorStyle =  UITableViewCellSeparatorStyleNone;
        self.tableView.contentInset = UIEdgeInsetsMake(44.0, 0.0, 44.0, 0.0);
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    return self;
} // init()

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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LeftMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.titlesArray[indexPath.row][@"txt"];
    if ([_titlesArray[indexPath.row][@"state"] intValue] == ITEM_SELECTED) {
        [cell.textLabel setFont:_selectedFont];
    }
    else {
        [cell.textLabel setFont:_normalFont];
    }
    return cell;
} // cellForRowAtIndexPath()

#pragma mark - UITableViewDelegate
//-----------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

// Unselect all menu Items
//---------------------------
- (void)unselectAll
{
    for (id x in _titlesArray) { x[@"state"] = @(ITEM_NOT_SELECTED); }
}

// Select or unselect one menu item by row
//-------------------------------------------------
- (void)setState:(int)state forRow:(NSInteger)row
{
    _titlesArray[row][@"state"] = @(state);
} // setState: forRow:

// Select or unselect one menu item by title
//-------------------------------------------------
- (void)setState:(int)state forMenuItem:(NSString *)txt
{
    int idx = -1;
    for (NSDictionary *d in _titlesArray) {
        idx++;
        if ([d[@"txt"] hasPrefix:txt]) {
            _titlesArray[idx][@"state"] = @(state);
            break;
        }
    }
} // setState: forMenuItem:

- (bool) videoMode { return _mode == VIDEO_MODE; }
- (bool) photoMode { return _mode == PHOTO_MODE; }
- (bool) debugMode { return _mode == DEBUG_MODE; }
- (bool) demoMode  { return _mode == DEMO_MODE; }

// Handle left menu choice
//--------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopViewController *topViewController = (TopViewController *)self.sideMenuController;
    NSString *menuItem = _titlesArray[indexPath.row][@"txt"];

    do {
        if ([menuItem hasPrefix:@"Video Mode"]) {
            if (_mode == VIDEO_MODE) break;
            [self unselectAll];
            [self setState:ITEM_SELECTED forRow:indexPath.row];
            _mode = VIDEO_MODE;
            g_app.mainVC.btnCam.hidden = NO;
            [g_app.mainVC.frameExtractor resume];
            g_app.mainVC.lbBottom.text = @"Point the camera at a Go board";
            [g_app.mainVC doLayout];
        }
        else if ([menuItem hasPrefix:@"Photo Mode"]) {
            if (_mode == PHOTO_MODE) break;
            [self unselectAll];
            [self setState:ITEM_SELECTED forRow:indexPath.row];
            _mode = PHOTO_MODE;
            g_app.mainVC.btnCam.hidden = NO;
            [g_app.mainVC.frameExtractor resume];
            g_app.mainVC.lbBottom.text = @"Take a photo of a Go board";
            [g_app.mainVC doLayout];
        }
        else if ([menuItem hasPrefix:@"Demo Mode"]) {
            if (_mode == DEBUG_MODE) break;
            [self gotoDemoMode];
        }
        else if ([menuItem hasPrefix:@"Saved Images"]) {
            [g_app.navVC pushViewController:g_app.imagesVC animated:YES];
        }
        [self.tableView reloadData];
    } while(0);
    [topViewController hideLeftViewAnimated:YES completionHandler:nil];
} // didSelectRowAtIndexPath()

//---------------------
- (void)gotoDebugMode
{
    //[self unselectAll];
    //[self setState:ITEM_SELECTED forMenuItem:@"Debug Mode"];
    _mode = DEBUG_MODE;
    g_app.mainVC.btnCam.hidden = YES;
    [g_app.mainVC doLayout];
    [g_app.mainVC debugFlow:true];
    [self.tableView reloadData];
} // gotoDebugMode()

//---------------------
- (void)gotoDemoMode
{
    [self unselectAll];
    [self setState:ITEM_SELECTED forMenuItem:@"Demo Mode"];
    _mode = DEMO_MODE;
    g_app.mainVC.btnCam.hidden = YES;
    [g_app.mainVC doLayout];
    [g_app.mainVC debugFlow:true];
    [self.tableView reloadData];
} // gotoDemoMode()


@end

































































