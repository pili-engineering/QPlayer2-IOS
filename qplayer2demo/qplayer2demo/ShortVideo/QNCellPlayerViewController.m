//
//  PLCellPlayerViewController.m
//  PLPlayerKitDemo
//
//  Created by 冯文秀 on 2018/5/10.
//  Copyright © 2018年 Aaron. All rights reserved.
//

#import "QNCellPlayerViewController.h"
#import "QNCellPlayerTableViewCell.h"
#import "QNPlayerShortVideoMaskView.h"
#import "QNShortVideoPlayerViewCache.h"
#import "QNSamplePlayerWithQRenderView.h"
#import "QNMikuClientManager.h"
#import "QNToastView.h"
static NSString *status[] = {
    @"Unknow",
    @"Preparing",
    @"Ready",
    @"Open",
    @"Caching",
    @"Playing",
    @"Paused",
    @"Stopped",
    @"Error",
    @"Reconnecting",
    @"Completed"
};
@interface QNCellPlayerViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
QIPlayerStateChangeListener,
QIPlayerProgressListener,
QIPlayerRenderListener,
QIMediaItemStateChangeListener,
QIMediaItemCommandNotAllowListener
>

@property (nonatomic, strong) QNSamplePlayerWithQRenderView *player;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) QNCellPlayerTableViewCell *currentCell;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) NSMutableArray <NSNumber *>*cacheKeyArray;
@property (nonatomic, strong) QNPlayItemManager * myPlayItemManager;
@property (nonatomic, strong) QNShortVideoPlayerViewCache *shortVideoPlayerViewCache;

@property (nonatomic, assign) CGFloat topSpace;

@property (nonatomic, strong) QNToastView *toastView;
@property (nonatomic, assign) int modelsNum;

@end

@implementation QNCellPlayerViewController

- (void)dealloc {
    
    NSLog(@"PLCellPlayerViewController - dealloc");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.shortVideoPlayerViewCache recyclePlayerView:self.player];
    [self.shortVideoPlayerViewCache stop];
    _toastView = nil;
    _currentCell = nil;
    self.player = nil;
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];

}


- (void)viewDidLoad {
    [super viewDidLoad];
        // Do any additional setup after loading the view.
    self.modelsNum = 0;
    self.title = @"短视频";
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance* appearance = [[UINavigationBarAppearance alloc]init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor =PL_SEGMENT_BG_COLOR;
        [self.navigationController.navigationBar setScrollEdgeAppearance:appearance];
        [self.navigationController.navigationBar setStandardAppearance:appearance];
        
    } else {
        self.navigationController.navigationBar.barTintColor = PL_SEGMENT_BG_COLOR;
        // Fallback on earlier versions
    };
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 6, 34, 34)];
    UIImage *image = [UIImage imageNamed:@"pl_back"];
    // iOS 11 之后， UIBarButtonItem 在 initWithCustomView 是图片按钮的情况下变形
    if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0f) {
        image = [self originImage:image scaleToSize:CGSizeMake(34, 34)];
    }
    [backButton setImage:image forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(getBack) forControlEvents:UIControlEventTouchDown];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backButton];
    

    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDir stringByAppendingPathComponent:@"lite_urls.json"];
    
    NSData *data=[[NSData alloc] initWithContentsOfFile:path];
    if (!data) {
        path=[[NSBundle mainBundle] pathForResource:@"lite_urls" ofType:@"json"];
        data=[[NSData alloc] initWithContentsOfFile:path];
    }
    NSArray *urlArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    NSMutableArray<QNPlayItem *>* playItemArray = [NSMutableArray array];
    for (NSDictionary *dic in urlArray) {
        QMediaModelBuilder *modleBuilder = [[QMediaModelBuilder alloc]initWithIsLive:[NSString stringWithFormat:@"%@",[dic valueForKey:@"isLive"]].intValue  == 0? NO : YES];
        for (NSDictionary *elDic in dic[@"streamElements"]) {
            NSString * urlstr = [ [NSString stringWithFormat:@"%@",[elDic valueForKey:@"url"]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL * url = [[[QNMikuClientManager sharedInstance] getMikuClient] makeProxyURL:urlstr];
            [modleBuilder addStreamElementWithUserType:[NSString stringWithFormat:@"%@",[elDic valueForKey:@"userType"]]
                             urlType:   [NSString stringWithFormat:@"%@",[elDic valueForKey:@"urlType"]].intValue
                             url:       [url absoluteString]
                             quality:   [NSString stringWithFormat:@"%@",[elDic valueForKey:@"quality"]].intValue
                             isSelected:[NSString stringWithFormat:@"%@",[elDic valueForKey:@"isSelected"]].intValue == 0?NO : YES
                             backupUrl: [NSString stringWithFormat:@"%@",[elDic valueForKey:@"backupUrl"]]
                             referer:   [NSString stringWithFormat:@"%@",[elDic valueForKey:@"referer"]]
                             renderType:[NSString stringWithFormat:@"%@",[elDic valueForKey:@"renderType"]].intValue];
        }
        QMediaModel *model = [modleBuilder build];
        QNPlayItem *item = [[QNPlayItem alloc]initWithId:self.modelsNum mediaModel:model coverUrl:@""];
        [playItemArray addObject:item];
        self.modelsNum ++;
    }
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = PLAYER_PORTRAIT_HEIGHT + 1;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.pagingEnabled = YES;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:_tableView];
    

    [self setUpPlayer:playItemArray];
    
    _toastView = [[QNToastView alloc]initWithFrame:CGRectMake(0, PL_SCREEN_HEIGHT - 350, 200, 300)];
    [self.view addSubview:_toastView];
    

    
}

- (void)setUpPlayer:(NSArray *)playItemArray{
    NSMutableArray *configs = [NSMutableArray array];
    if (PL_HAS_NOTCH) {
        _topSpace = 88;
    } else {
        _topSpace = 64;
    }
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.myPlayItemManager = [[QNPlayItemManager alloc]init];
    [self.myPlayItemManager append:playItemArray];
    self.shortVideoPlayerViewCache = [[QNShortVideoPlayerViewCache alloc]initWithPlayItemManager:self.myPlayItemManager externalFilesDir:documentsDir];
    [self.shortVideoPlayerViewCache start];
   self.player = [self.shortVideoPlayerViewCache fetchPlayerView:0];
//
    [self.shortVideoPlayerViewCache changePosition:0];
    [self playerContextAllCallBack];
}

#pragma mark - PLPlayerDelegate
-(void)playerContextAllCallBack{
    [self.player.controlHandler addPlayerStateListener:self];
    [self.player.controlHandler addPlayerProgressChangeListener:self];
    [self.player.renderHandler addPlayerRenderListener:self];

}
-(void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if(state == QPLAYER_STATE_NONE){
        [_toastView addText:@"初始状态"];
        
    }
    else if (state ==     QPLAYER_STATE_INIT){
        
        [_toastView addText:@"创建完成"];
    }
    else if(state ==     QPLAYER_STATE_PREPARE ||state == QPLAYER_STATE_MEDIA_ITEM_PREPARE){
        [_toastView addText:@"正在加载"];
    }
    else if (state == QPLAYER_STATE_PLAYING) {
        if (_currentCell == nil) {
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        }
        _currentCell.state = YES;
        [_toastView addText:@"正在播放"];
    }
    else if(state == QPLAYER_STATE_PAUSED_RENDER){
        _currentCell.state = NO;
        [_toastView addText:@"播放暂停"];
    }
    else if(state == QPLAYER_STATE_STOPPED){
        _currentCell.state = NO;
        [_toastView addText:@"播放停止"];
    }
    else if(state == QPLAYER_STATE_COMPLETED){
        _currentCell.state = NO;
        [self.player.controlHandler seek:0];
        [_toastView addText:@"播放完成"];
    }
    else if(state == QPLAYER_STATE_ERROR){
        _currentCell.state = NO;
        
        [_toastView addText:@"播放出错"];
    }
    else if (state == QPLAYER_STATE_SEEKING){
        [_toastView addText:@"正在seek"];
    }
    else{
        [_toastView addText:@"其他状态"];
    }

}

-(void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    NSLog(@"预加载首帧时间----%d",elapsedTime);

    dispatch_async(dispatch_get_main_queue(), ^{
//        if(self.player != self.currentCell.playerView){
            self.currentCell.playerView = self.player;
//        }

    });
}


#pragma mark - mediaItemDelegate

-(void)addAllCallBack:(QMediaItemContext *)mediaItem{
    [mediaItem.controlHandler addMediaItemStateChangeListener:self];
    [mediaItem.controlHandler addMediaItemCommandNotAllowListener:self];


}
-(void)onStateChanged:(QMediaItemContext *)context state:(QMediaItemState)state{
    NSLog(@"-------------预加载--onStateChanged -- %d---%@",state,context.controlHandler.mediaModel.streamElements[0].url);
}
-(void)onCommandNotAllow:(QMediaItemContext *)context commandName:(NSString *)commandName state:(QMediaItemState)state{
    NSLog(@"-------------预加载--notAllow---%@",commandName);
}
#pragma mark - tableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelsNum;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld%ld", (long)[indexPath section], (long)[indexPath row]];
    // 出列可重用的 cell，从缓存池取标识为 "Cell" 的 cell
    QNCellPlayerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[QNCellPlayerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.modelKey = [NSNumber numberWithInteger:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    QNCellPlayerTableViewCell *cell = (QNCellPlayerTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self updatePlayCell:cell scroll:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return PL_SCREEN_HEIGHT;
}


// 松手时已经静止,只会调用scrollViewDidEndDragging
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (decelerate == NO) { // scrollView已经完全静止
        [self handleScroll];
    }
}

// 松手时还在运动, 先调用scrollViewDidEndDragging,在调用scrollViewDidEndDecelerating
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    // scrollView已经完全静止
    [self handleScroll];
}

-(void)handleScroll{
    // 找到下一个要播放的cell(最在屏幕中心的)
    QNCellPlayerTableViewCell *finnalCell = nil;
    NSArray *visiableCells = [self.tableView visibleCells];
    CGFloat gap = MAXFLOAT;
    for (QNCellPlayerTableViewCell *cell in visiableCells) {

        if (0<=[cell.modelKey intValue] && [cell.modelKey intValue]<self.modelsNum) { // 如果这个cell有视频
            CGPoint coorCentre = [cell.superview convertPoint:cell.center toView:nil];
            CGFloat delta = fabs(coorCentre.y-[UIScreen mainScreen].bounds.size.height*0.5);
            if (delta < gap) {
                gap = delta;
                finnalCell = cell;
            }
        }
    }

    // 注意, 如果正在播放的cell和finnalCell是同一个cell, 不应该在播放
    if (finnalCell != nil && _currentCell != finnalCell)  {
        
        [self updatePlayCell:finnalCell scroll:YES];
        
        return;
    }
    
}


-(void)updatePlayCell:(QNCellPlayerTableViewCell *)cell scroll:(BOOL)scroll{
    
    BOOL isPlaying = (_player.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    
    if (_currentCell == cell && _currentCell) {
        if (!scroll) {
            if(isPlaying) {
                    [_player.controlHandler pauseRender];
            } else{
                    [_player.controlHandler resumeRender];
            }
        }
    } else{
        if(_currentCell == nil){
            _currentCell = cell;
            return;
        }
//        [self.player removeFromSuperview];
        
        [self.shortVideoPlayerViewCache recyclePlayerView:self.player];
        
        self.player = [self.shortVideoPlayerViewCache fetchPlayerView:[cell.modelKey intValue]];
        [self playerContextAllCallBack];
        [self.shortVideoPlayerViewCache changePosition:[cell.modelKey intValue]];
        _currentCell = cell;
//        self.currentCell.playerView = self.player;
    }

}
- (void)getBack {
    [self.player.controlHandler stop];
    [self.navigationController popViewControllerAnimated:YES];
}




- (UIImage *)originImage:(UIImage *)image scaleToSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
