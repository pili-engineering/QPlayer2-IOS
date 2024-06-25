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

@property (nonatomic, strong) QNSamplePlayerWithQRenderView *mPlayer;
@property (nonatomic, strong) UITableView *mTableView;
@property (nonatomic, strong) QNCellPlayerTableViewCell *mCurrentCell;

@property (nonatomic, strong) NSMutableArray <UIImage *>*mCoverImageArray;
@property (nonatomic, strong) QNPlayItemManager * mPlayItemManager;
@property (nonatomic, strong) QNShortVideoPlayerViewCache *mShortVideoPlayerViewCache;

@property (nonatomic, assign) CGFloat mTopSpace;

@property (nonatomic, strong) QNToastView *mToastView;
@property (nonatomic, assign) int mModelsNum;
@property (nonatomic, assign) int mCurrentPlayingNum;

@end

@implementation QNCellPlayerViewController

- (void)dealloc {
    
    NSLog(@"PLCellPlayerViewController - dealloc");
}
- (void)viewDidDisappear:(BOOL)animated{
    //回收播放器
    [self.mShortVideoPlayerViewCache recyclePlayerView:self.mPlayer];
    //停止并释放 shortVideoPlayerViewCache
    [self.mShortVideoPlayerViewCache stop];
    _mToastView = nil;
    _mCurrentCell = nil;
    self.mPlayer = nil;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.mCurrentPlayingNum = 0;
    self.view.accessibilityIdentifier = @"shortViewController";
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //锁定播放器当前位置为 0 0
    [self tableView:self.mTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
        // Do any additional setup after loading the view.
    self.mModelsNum = 0;
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
    backButton.accessibilityIdentifier = @"shortViewController back";
    // iOS 11 之后， UIBarButtonItem 在 initWithCustomView 是图片按钮的情况下变形
    if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0f) {
        image = [self originImage:image scaleToSize:CGSizeMake(34, 34)];
    }
    [backButton setImage:image forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(getBack) forControlEvents:UIControlEventTouchDown];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backButton];

    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //读取 lite_urls 文件内容
    NSString *path = [documentsDir stringByAppendingPathComponent:@"lite_urls.json"];
    
    NSData *data=[[NSData alloc] initWithContentsOfFile:path];
    if (!data) {
        path=[[NSBundle mainBundle] pathForResource:@"lite_urls" ofType:@"json"];
        data=[[NSData alloc] initWithContentsOfFile:path];
    }
    NSArray *urlArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSMutableArray<QNPlayItem *>* playItemArray = [NSMutableArray array];
    self.mCoverImageArray = [NSMutableArray array];
    //创建播放的资源数据
    for (NSDictionary *dic in urlArray) {
        QMediaModelBuilder *modleBuilder = [[QMediaModelBuilder alloc]initWithIsLive:[NSString stringWithFormat:@"%@",[dic valueForKey:@"isLive"]].intValue  == 0? NO : YES];
        //获取封面名称
        NSString *coverImageName = [dic valueForKey:@"coverImageName"];
        UIImage *coverImage = [UIImage imageNamed:coverImageName];
        [self.mCoverImageArray addObject:coverImage];
        //获取 streamElements 字段数据
        for (NSDictionary *elDic in dic[@"streamElements"]) {
            NSString * urlstr = [ [NSString stringWithFormat:@"%@",[elDic valueForKey:@"url"]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            //注释掉即不使用 miku 
//            NSURL * url = [[[QNMikuClientManager sharedInstance] getMikuClient] makeProxyURL:urlstr];
            [modleBuilder addStreamElementWithUserType:[NSString stringWithFormat:@"%@",[elDic valueForKey:@"userType"]]
                             urlType:   [NSString stringWithFormat:@"%@",[elDic valueForKey:@"urlType"]].intValue
                             url:       urlstr
                             quality:   [NSString stringWithFormat:@"%@",[elDic valueForKey:@"quality"]].intValue
                             isSelected:[NSString stringWithFormat:@"%@",[elDic valueForKey:@"isSelected"]].intValue == 0?NO : YES
                             backupUrl: [NSString stringWithFormat:@"%@",[elDic valueForKey:@"backupUrl"]]
                             referer:   [NSString stringWithFormat:@"%@",[elDic valueForKey:@"referer"]]
                             renderType:[NSString stringWithFormat:@"%@",[elDic valueForKey:@"renderType"]].intValue];
        }
        //创建 QMediaModel
        QMediaModel *model = [modleBuilder build];
        //创建 QNPlayItem
        QNPlayItem *item = [[QNPlayItem alloc]initWithId:self.mModelsNum mediaModel:model coverUrl:@""];
        [playItemArray addObject:item];
        //统计 QMediaModel 数据数量
        self.mModelsNum ++;
    }
    //创建tableview
    self.mTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT) style:UITableViewStylePlain];
    self.mTableView.delegate = self;
    self.mTableView.dataSource = self;
    self.mTableView.rowHeight = PLAYER_PORTRAIT_HEIGHT + 1;
    self.mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.mTableView.pagingEnabled = YES;
    self.mTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:_mTableView];
    
    [self setUpPlayer:playItemArray];
    
    _mToastView = [[QNToastView alloc]initWithFrame:CGRectMake(0, PL_SCREEN_HEIGHT - 350, 200, 300)];
    [self.view addSubview:_mToastView];

    
}
- (void)setUpPlayer:(NSArray *)playItemArray{
    NSMutableArray *configs = [NSMutableArray array];
    if (PL_HAS_NOTCH) {
        _mTopSpace = 88;
    } else {
        _mTopSpace = 64;
    }
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.mPlayItemManager = [[QNPlayItemManager alloc]init];
    [self.mPlayItemManager append:playItemArray];
    self.mShortVideoPlayerViewCache = [[QNShortVideoPlayerViewCache alloc]initWithPlayItemManager:self.mPlayItemManager externalFilesDir:documentsDir];
    [self.mShortVideoPlayerViewCache start];
}
//添加播放器的所有 listener
-(void)playerContextAllCallBack{
    [self.mPlayer.controlHandler addPlayerStateListener:self];
    [self.mPlayer.controlHandler addPlayerProgressChangeListener:self];
    [self.mPlayer.renderHandler addPlayerRenderListener:self];

}
#pragma mark - PLPlayerDelegate

-(void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if(state == QPLAYER_STATE_NONE){
        [_mToastView addText:@"初始状态"];
    }
    else if (state ==     QPLAYER_STATE_INIT){
        
        [_mToastView addText:@"创建完成"];
    }
    else if(state ==     QPLAYER_STATE_PREPARE ||state == QPLAYER_STATE_MEDIA_ITEM_PREPARE){
        [_mToastView addText:@"正在加载"];
    }
    else if (state == QPLAYER_STATE_PLAYING) {
        _mCurrentCell.mState = YES;
        [_mToastView addText:@"正在播放"];
    }
    else if(state == QPLAYER_STATE_PAUSED_RENDER){
        _mCurrentCell.mState = NO;
        [_mToastView addText:@"播放暂停"];
    }
    else if(state == QPLAYER_STATE_STOPPED){
        _mCurrentCell.mState = NO;
        [_mToastView addText:@"播放停止"];
    }
    else if(state == QPLAYER_STATE_COMPLETED){
        _mCurrentCell.mState = NO;
        [self.mPlayer.controlHandler seek:0];
        [_mToastView addText:@"播放完成"];
    }
    else if(state == QPLAYER_STATE_ERROR){
        _mCurrentCell.mState = NO;
        
        [_mToastView addText:@"播放出错"];
    }
    else if (state == QPLAYER_STATE_SEEKING){
        [_mToastView addText:@"正在seek"];
    }
    else{
        [_mToastView addText:@"其他状态"];
    }

}

-(void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    NSLog(@"预加载首帧时间----%d",elapsedTime);
    
    self.mCurrentCell.mState = YES;
    self.mCurrentCell.mFirstFrameTime = elapsedTime;
    QNCellPlayerTableViewCell *inner = self.mCurrentCell;
    [inner hideCoverImage];
    
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
    return self.mModelsNum;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QNCellPlayerTableViewCell* cell = [[QNCellPlayerTableViewCell alloc]initWithImage:self.mCoverImageArray[indexPath.row]];
    cell.mModelKey = [NSNumber numberWithInteger:indexPath.row];
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
    [self handleScroll];
}

// 松手时还在运动, 先调用scrollViewDidEndDragging,在调用scrollViewDidEndDecelerating
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    // scrollView已经完全静止
    [self handleScroll];
}

-(void)handleScroll{
    // 找到下一个要播放的cell(最在屏幕中心的)
    QNCellPlayerTableViewCell *finnalCell = nil;
    NSArray *visiableCells = [self.mTableView visibleCells];
    CGFloat gap = MAXFLOAT;
    for (QNCellPlayerTableViewCell *cell in visiableCells) {

        if (0<=[cell.mModelKey intValue] && [cell.mModelKey intValue]<self.mModelsNum ) { // 如果这个cell有视频
            CGPoint coorCentre = [cell.superview convertPoint:cell.center toView:nil];
            CGFloat delta = fabs(coorCentre.y-[UIScreen mainScreen].bounds.size.height*0.5);
            if (delta < gap) {
                gap = delta;
                finnalCell = cell;
            }
        }
    }
    //修改当前正在播放的 playItem 的 itemId，也就是key
    self.mCurrentPlayingNum = [finnalCell.mModelKey intValue];
    // 注意, 如果正在播放的cell和finnalCell是同一个cell, 不应该在播放
    if (finnalCell != nil && finnalCell != self.mCurrentCell)  {
        
        [self updatePlayCell:finnalCell scroll:YES];
        
        return;
    }
    
}

#pragma mark - 更新cell

-(void)updatePlayCell:(QNCellPlayerTableViewCell *)cell scroll:(BOOL)scroll{
    
    BOOL isPlaying = (_mPlayer.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    
    if (_mCurrentCell == cell && _mCurrentCell) {
        if (!scroll) {
            if(isPlaying) {
                    [_mPlayer.controlHandler pauseRender];
            } else{
                    [_mPlayer.controlHandler resumeRender];
            }
        }
    } else{
        if(_mCurrentCell == nil){
            _mCurrentCell = cell;
            self.mPlayer = [self.mShortVideoPlayerViewCache fetchPlayerView:0];
             [self.mShortVideoPlayerViewCache changePosition:0];
             [self playerContextAllCallBack];
            _mCurrentCell.mPlayerView = self.mPlayer;
            return;
        }
        //重新展示封面
        [self.mCurrentCell showCoverImage];
        //回收播放器
        [self.mShortVideoPlayerViewCache recyclePlayerView:self.mPlayer];
        //拿取下一个cell所需要的播放器
        self.mPlayer = [self.mShortVideoPlayerViewCache fetchPlayerView:[cell.mModelKey intValue]];
        
        //添加listener
        [self playerContextAllCallBack];
        //切换当前正在播放的 playItem 位置
        [self.mShortVideoPlayerViewCache changePosition:[cell.mModelKey intValue]];
        //更新正在播放的cell
        _mCurrentCell = cell;
        //将播放器视图添加给正在播放的 cell
        self.mCurrentCell.mPlayerView = self.mPlayer;
    }

}
- (void)getBack {
    [self.mPlayer.controlHandler stop];
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
