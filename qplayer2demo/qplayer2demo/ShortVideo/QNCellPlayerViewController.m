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
@property (nonatomic, strong) NSMutableArray <UIImage *>*coverImageArray;
@property (nonatomic, strong) QNPlayItemManager * myPlayItemManager;
@property (nonatomic, strong) QNShortVideoPlayerViewCache *shortVideoPlayerViewCache;

@property (nonatomic, assign) CGFloat topSpace;

@property (nonatomic, strong) QNToastView *toastView;
@property (nonatomic, assign) int modelsNum;
@property (nonatomic, assign) int currentPlayingNum;
@property (nonatomic, assign) int lastContentOffset;
@property (nonatomic, assign) BOOL isDownScrolling;
@property (nonatomic, strong) NSMutableArray< QMediaModel *> * models;
@property (nonatomic, strong) QNSamplePlayerWithQRenderView *playerView1;
@property (nonatomic, strong) QNSamplePlayerWithQRenderView *playerView2;
@property (nonatomic, strong) QMediaItemContext *item1;
@property (nonatomic, strong) UIView *view1;
@property (nonatomic, strong) UIView *view2;
@property (nonatomic, assign) int viewtag;

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
    self.currentPlayingNum = 0;
    
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
    self.models = [NSMutableArray array];
    NSMutableArray<QNPlayItem *>* playItemArray = [NSMutableArray array];
    self.coverImageArray = [NSMutableArray array];
    for (NSDictionary *dic in urlArray) {
        QMediaModelBuilder *modleBuilder = [[QMediaModelBuilder alloc]initWithIsLive:[NSString stringWithFormat:@"%@",[dic valueForKey:@"isLive"]].intValue  == 0? NO : YES];
        NSString *coverImageName = [dic valueForKey:@"coverImageName"];
        UIImage *coverImage = [UIImage imageNamed:coverImageName];
        [self.coverImageArray addObject:coverImage];
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
        [self.models addObject:item.mediaModel];
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
    

//    self.playerView1 = [[QNSamplePlayerWithQRenderView alloc]initWithFrame:CGRectMake(0, 0, 150, 100) APPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];
//    self.playerView2 = [[QNSamplePlayerWithQRenderView alloc]initWithFrame:CGRectMake(0, 0, 150, 100) APPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];
    UIButton *stop =[[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
    [stop addTarget:self action:@selector(stopClick:) forControlEvents:UIControlEventTouchUpInside];
    stop.backgroundColor = [UIColor redColor];
    stop.tag = 1;
//    [self.view addSubview:stop];
    UIButton *stop2 =[[UIButton alloc]initWithFrame:CGRectMake(250, 100, 100, 100)];
    [stop2 addTarget:self action:@selector(stopClick:) forControlEvents:UIControlEventTouchUpInside];
    stop2.backgroundColor = [UIColor redColor];
    stop2.tag = 2;
//    [self.view addSubview:stop2];
    self.view1 = [[UIView alloc]initWithFrame:CGRectMake(50, 300, 150, 150)];
    self.view1.backgroundColor = [UIColor greenColor];
//    [self.view addSubview:self.view1];
//    [self.view1 addSubview:self.playerView1];
    self.view2 = [[UIView alloc]initWithFrame:CGRectMake(250, 300, 150, 150)];
    self.view2.backgroundColor = [UIColor greenColor];
//    [self.view addSubview:self.view2];
//    [self.view2 addSubview:self.playerView2];
//    self.item1 = [[QMediaItemContext alloc]initItemComtextWithMediaModel:self.models[1] startPos:0 storageDir:documentsDir logLevel:LOG_DEBUG];
//    [self.item1.controlHandler start];
//    [self.playerView1.renderHandler addPlayerRenderListener:self];
}
-(void) stopClick:(UIButton *)sender{
    NSLog(@"stopClick -------");
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.item1 = [[QMediaItemContext alloc]initItemComtextWithMediaModel:self.models[sender.tag] startPos:0 storageDir:documentsDir logLevel:LOG_DEBUG];
    [self.item1.controlHandler start];
    self.viewtag = sender.tag;
    if(sender.tag == 1){
        [self.playerView1 removeFromSuperview];
        [self.playerView1.controlHandler stop];
        [self.playerView1.controlHandler playMediaItem:self.item1];
//        [self.view1 addSubview:self.playerView1];
    }else{
        [self.playerView1 removeFromSuperview];
        [self.playerView1.controlHandler stop];
        [self.playerView1.controlHandler playMediaItem:self.item1];
//        [self.view2 addSubview:self.playerView1];
    }
    
//    [self.player.controlHandler stop];
//    [self.player.controlHandler playMediaItem:item];
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
    
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentCell.state = YES;
        self.currentCell.firstFrameTime = elapsedTime;
        QNCellPlayerTableViewCell *inner = self.currentCell;
        [inner hideCoverImage];
//        if(self.viewtag == 1){
//            [self.view1 addSubview:self.playerView1];
//        }else{
//            [self.view2 addSubview:self.playerView1];
//        }
//    });
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
//    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld%ld", (long)[indexPath section], (long)[indexPath row]];
//    // 出列可重用的 cell，从缓存池取标识为 "Cell" 的 cell
//    QNCellPlayerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[QNCellPlayerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }
    QNCellPlayerTableViewCell* cell = [[QNCellPlayerTableViewCell alloc]initWithImage:self.coverImageArray[indexPath.row]];
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    [cell showCoverImage];
    cell.modelKey = [NSNumber numberWithInteger:indexPath.row];
    NSLog(@"cell.modelKey index : %ld",indexPath.row);
//    self.currentPlayingNum = (int)indexPath.row;
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
//    if (decelerate == NO) { // scrollView已经完全静止
        [self handleScroll];
//    }else{
//        if(self.lastContentOffset > scrollView.contentOffset.y){
////            self.isDownScrolling = YES;
//            if(self.currentPlayingNum <self.modelsNum){
//                self.currentPlayingNum ++;
//                [self.shortVideoPlayerViewCache changePosition:self.currentPlayingNum];
//            }
//        }else if(self.lastContentOffset < scrollView.contentOffset.y) {
////            self.isDownScrolling = NO;
//            if(self.currentPlayingNum>0){
//                self.currentPlayingNum --;
//                [self.shortVideoPlayerViewCache changePosition:self.currentPlayingNum];
//            }
//        }
//    }
//    self.lastContentOffset = scrollView.contentOffset.y;
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

        if (0<=[cell.modelKey intValue] && [cell.modelKey intValue]<self.modelsNum ) { // 如果这个cell有视频
            CGPoint coorCentre = [cell.superview convertPoint:cell.center toView:nil];
            CGFloat delta = fabs(coorCentre.y-[UIScreen mainScreen].bounds.size.height*0.5);
            if (delta < gap) {
                gap = delta;
                finnalCell = cell;
            }
        }
    }
 
    self.currentPlayingNum = [finnalCell.modelKey intValue];
    if(abs([self.currentCell.modelKey intValue] - self.currentPlayingNum)>=2){
        
        NSLog(@"self.currentPlayingNum %d , self.currentCell.modelKey %@",self.currentPlayingNum,self.currentCell.modelKey);
    }
    NSLog(@"self.currentPlayingNum %d , self.currentCell.modelKey %@",self.currentPlayingNum,self.currentCell.modelKey);
    // 注意, 如果正在播放的cell和finnalCell是同一个cell, 不应该在播放
    if (finnalCell != nil && finnalCell != self.currentCell)  {
        
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
        NSLog(@"cell.modelKey : %d",[cell.modelKey intValue]);
        NSLog(@"self.player.mytag : %@",self.player.mytag);
        if(_currentCell == nil){
            _currentCell = cell;
            _currentCell.playerView = self.player;
//            [_currentCell addCoverImage:self.coverImageArray[0]];
            return;
        }
        
//        QNSamplePlayerWithQRenderView * view = self.player;
//        [self.player removeFromSuperview];
        [self.currentCell showCoverImage];
        [self.shortVideoPlayerViewCache recyclePlayerView:self.player];
//        [cell addCoverImage:self.coverImageArray[[cell.modelKey intValue]]];
        self.player = [self.shortVideoPlayerViewCache fetchPlayerView:[cell.modelKey intValue]];
        
        NSLog(@"self.player.mytag : %@ tag : %d",self.player.mytag,[cell.modelKey intValue]);
        [self playerContextAllCallBack];
        [self.shortVideoPlayerViewCache changePosition:[cell.modelKey intValue]];
        _currentCell = cell;
        
        self.currentCell.playerView = self.player;
//        NSLog(@" second self.currentPlayingNum %d , self.currentCell.modelKey %@",self.currentPlayingNum,self.currentCell.modelKey);
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
