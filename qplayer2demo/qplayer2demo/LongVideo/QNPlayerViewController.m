//
//  QNPlayerViewController.m
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/9/18.
//  Copyright © 2017年 qiniu. All rights reserved.
//

#import "QNPlayerViewController.h"
#import "QNScanViewController.h"
#import "QNPlayerConfigViewController.h"

#import "QNAppDelegate.h"

#import "QNPlayerMaskView.h"
#import "QNInfoHeaderView.h"

#import "QNURLListTableViewCell.h"

#import "QDataHandle.h"
#import "QNToastView.h"

#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreAudio/CoreAudioTypes.h>


#define PL_PLAYER_VIDEO_ROOT_FOLDER @"PLPlayerFloder"
#define GET_PL_PLAYER_VIDEO_FOLDER(folderName) [PL_PLAYER_VIDEO_ROOT_FOLDER stringByAppendingPathComponent:folderName]
#define PL_PLAYER_VIDEO_REVERSER GET_PL_PLAYER_VIDEO_FOLDER(@"PLPlayerCacheFile")

@interface QNPlayerViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
QNPlayerMaskViewDelegate,
PLScanViewControlerDelegate,
QIPlayerStateChangeListener,
QIPlayerBufferingListener,
QIPlayerQualityListener,
QIPlayerSpeedListener,
QIPlayerSEIDataListener,
QIPlayerAuthenticationListener,
QIPlayerRenderListener,
QIPlayerShootVideoListener,
QIPlayerVideoFrameSizeChangeListener,
QIPlayerSeekListener,
QIPlayerSubtitleListener
>

/** 播放器蒙版视图 **/
@property (nonatomic, strong) QNPlayerMaskView *maskView;

/** 界面显示的播放信息数组 **/
@property (nonatomic, strong) NSArray *titleArray;

@property (nonatomic, strong) QNInfoHeaderView *infoHeaderView;
@property (nonatomic, strong) UITableView *urlListTableView;

/** 被选中 URL 在列表中的下标 **/
@property (nonatomic, assign) NSInteger selectedIndex;
/** 是否显示 URL 列表 **/
@property (nonatomic, assign) BOOL isPull;

@property (nonatomic, copy) NSString *playerLogFileName;

@property (nonatomic) int immediatelyType;
/** 无可显示 URL 的提示 **/
@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, assign) BOOL isFlip;
@property (nonatomic, assign) CGFloat topSpace;

/** 分栏选择 **/
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, assign) BOOL isLiving;
@property (nonatomic, assign) NSInteger modeCount;

@property (nonatomic, strong) NSMutableArray<QMediaModel *> *playerModels;

/**toast **/
@property (nonatomic, strong) QNToastView *toastView;

//@property (nonatomic, strong) QPlayerContext *playerContext;
@property (nonatomic, assign) BOOL scanClick;
//@property (nonatomic, strong) QRenderView *myRenderView;
@property (nonatomic, strong) QPlayerView *myPlayerView;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL beInterruptedByOtherAudio;
@property (nonatomic, assign) NSInteger UpQualityIndex;
@property (nonatomic, assign) NSInteger firstVideoTime;
@property (nonatomic, assign) int seiNum;
@property (nonatomic, strong) NSString *seiString;

@end

@implementation QNPlayerViewController

- (void)dealloc {
    NSLog(@"QNPlayerViewController dealloc");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    self.scanClick = NO;
    if (appDelegate.isFlip) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    } else{
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (!self.scanClick) {
        self.toastView = nil;
        [_playerModels removeAllObjects];
        _playerModels = nil;
        self.myPlayerView = nil;
        self.playerConfigArray = nil;
    }
    
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.scanClick) {
        
        [self.durationTimer invalidate];
        self.durationTimer = nil;
        [self.myPlayerView.controlHandler stop];
        
        [self.myPlayerView.controlHandler playerRelease];
        
        
    }
    
    
}



- (void)viewDidLoad {
    [super viewDidLoad];

    self.scanClick = NO;
    self.isPlaying = NO;
    _playerConfigArray = [QDataHandle shareInstance].playerConfigArray;
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDir stringByAppendingPathComponent:@"urls.json"];
    
    NSData *data=[[NSData alloc] initWithContentsOfFile:path];
    if (!data) {
        path=[[NSBundle mainBundle] pathForResource:@"urls" ofType:@"json"];
        data=[[NSData alloc] initWithContentsOfFile:path];
    }
    NSArray *urlArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    _playerModels = [NSMutableArray array];
   
    for (NSDictionary *dic in urlArray) {
        BOOL islive =  [[dic valueForKey:@"isLive"] intValue]==0? NO:YES;
        QMediaModelBuilder *modleBuilder = [[QMediaModelBuilder alloc] initWithIsLive:islive];
//        [modle setValuesForKeysWithDictionary:dic];
            
        NSMutableArray <QStreamElement*> *streams = [NSMutableArray array];
        NSMutableArray <QSubtitleElement*> *subtitiles = [NSMutableArray array];
        for (NSDictionary *elDic in dic[@"streamElements"]) {
            QStreamElement *subModle = [[QStreamElement alloc] init];
            [subModle setValuesForKeysWithDictionary:elDic];
            [streams addObject:subModle];
        }
        if([dic objectForKey:@"subtitleElements"]){
            for(NSDictionary *subDic in dic[@"subtitleElements"]){
                QSubtitleElement *subtitleEle = [[QSubtitleElement alloc]init];
                [subtitleEle setValuesForKeysWithDictionary:subDic];
                [subtitiles addObject:subtitleEle];
                
//                [modleBuilder addSubtitleElement:subDic[@"name"] url:subDic[@"url"] isDefault:[subDic[@"isSelected"]intValue]==0?NO:YES];
            }
            
        }
        [modleBuilder addStreamElements:streams];
        [modleBuilder addSubtitleElements:subtitiles];
        QMediaModel *model = [modleBuilder build];
        [_playerModels addObject:model];
        
    }

    [self.durationTimer invalidate];
    self.durationTimer = nil;
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.barTintColor = PL_SEGMENT_BG_COLOR;
    [self.navigationItem setHidesBackButton:YES];
        
    self.modeCount = 0;

    if (PL_HAS_NOTCH) {
        _topSpace = 88;
    } else {
        _topSpace = 64;
    }
    
    [self setUpPlayer:self.playerConfigArray];
    
    self.subtitleLabel = [[UILabel alloc]init];

    self.subtitleLabel.backgroundColor = [UIColor clearColor];
    self.subtitleLabel.textColor = [UIColor whiteColor];
    self.subtitleLabel.numberOfLines = 0;
    [self.subtitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.myPlayerView addSubview:self.subtitleLabel];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationLessThanOrEqual
                                                                          toItem:self.myPlayerView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0
                                                                        constant:0.0];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.myPlayerView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0];

    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.subtitleLabel
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.myPlayerView
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant:-70.0];

    [NSLayoutConstraint activateConstraints:@[widthConstraint, centerXConstraint, bottomConstraint]];
    [self addPlayerMaskView];

    [self layoutUrlListTableView];
    
    _toastView = [[QNToastView alloc]initWithFrame:CGRectMake(0, PL_SCREEN_HEIGHT-300, 200, 300)];
    [self.view addSubview:_toastView];
    [self playerContextAllCallBack];
    
    
}

#pragma mark - 初始化 PLPlayer


- (void)setUpPlayer:(NSArray<QNClassModel*>*)models {
    NSMutableArray *configs = [NSMutableArray array];
    
    if (models) {
        configs = [models mutableCopy];
    } else {
        NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
        NSArray *dataArray = [userdafault objectForKey:@"PLPlayer_settings"];
        if (dataArray.count != 0 ) {
            for (NSData *data in dataArray) {
                QNClassModel *classModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [configs addObject:classModel];
            }
        }
    }
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    self.myPlayerView = [[QPlayerView alloc]initWithFrame:CGRectMake(0, _topSpace, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT) APPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];
    [self.view addSubview:self.myPlayerView];
//    [self.playerContext.controlHandler forceAuthenticationFromNetwork];
    [self.myPlayerView.controlHandler forceAuthenticationFromNetwork];
    QMediaModel *model = _playerModels.firstObject;

    [self.myPlayerView.controlHandler playMediaModel:model startPos:[[QDataHandle shareInstance] getConfiguraPostion]];
    for (QNClassModel* model in configs) {
        for (PLConfigureModel* configModel in model.classValue) {
            if ([model.classKey isEqualToString:@"PLPlayerOption"]) {
                [self configurePlayerWithConfigureModel:configModel classModel:model];;
            }
        }
    }
    

}

#pragma mark - PlayerListenerDelegate

-(void)playerContextAllCallBack{

    [self.myPlayerView.controlHandler addPlayerStateListener:self];
    [self.myPlayerView.controlHandler addPlayerBufferingChangeListener:self];
    [self.myPlayerView.controlHandler addPlayerQualityListener:self];
    [self.myPlayerView.controlHandler addPlayerSpeedChangeListener:self];
    [self.myPlayerView.controlHandler addPlayerAuthenticationListener:self];
    [self.myPlayerView.controlHandler addPlayerSEIDataListener:self];
    [self.myPlayerView.renderHandler addPlayerRenderListener:self];
    [self.myPlayerView.controlHandler addPlayerShootVideoListener:self];
    [self.myPlayerView.controlHandler addPlayerVideoFrameSizeChangeListener:self];
    [self.myPlayerView.controlHandler addPlayerSeekListener:self];
    [self.myPlayerView.controlHandler addPlayerSubtitleListener:self];
    
    
}
-(void)onSeekFailed:(QPlayerContext *)context{
    [_toastView addText:@"seek失败"];
}
-(void)onSeekSuccess:(QPlayerContext *)context{
    [_toastView addText:@"seek成功"];
    
    [self.maskView removeActivityIndicatorView];
}
-(void)onVideoFrameSizeChanged:(QPlayerContext *)context width:(int)width height:(int)height{
    
    [_toastView addText:[NSString stringWithFormat:@"视频宽高 width:%d height:%d",width,height]];
}
-(void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    self.firstVideoTime = elapsedTime;
}
-(void)onSEIData:(QPlayerContext *)context data:(NSData *)data{
    NSString * uuidString = @"";
    NSData *seiData = data;
    if(data.length >16){
        NSData *uuidData = [data subdataWithRange:NSMakeRange(0, 16)];
        NSUUID * uuid = [[NSUUID alloc]initWithUUIDBytes:uuidData.bytes];
        uuidString = [NSString stringWithFormat:@"%@",uuid];
        seiData = [data subdataWithRange:NSMakeRange(16, data.length-16)];
    }
    NSString *str = [[NSString alloc]initWithData:seiData encoding:NSUTF8StringEncoding];
    if ([self.seiString isEqual:str]){
        self.seiNum++;
    }else{
        self.seiNum = 1;
        self.seiString = str;
    }
    NSLog(@"sei回调 data.length: %lu",(unsigned long)data.length);
    NSLog(@"sei回调 :UUID : %@         seiString = %@",uuidString,str);
    NSString * logString = [NSString stringWithFormat:@"sei回调 :UUID : %@         seiString = %@",uuidString,str];
    NSDictionary *dict=@{NSFontAttributeName:[UIFont systemFontOfSize:13.0]};
    CGSize contentSize=[logString sizeWithAttributes:dict];
    int lineNum = contentSize.width/200 + 1;
    UITextView *seitext = [[UITextView alloc]initWithFrame:CGRectMake(PL_SCREEN_WIDTH/2-100, PL_SCREEN_HEIGHT/2-200, 200, 22.0 + (contentSize.height + 6) * lineNum)];
    seitext.editable = NO;
    seitext.userInteractionEnabled = NO;
    seitext.font = [UIFont systemFontOfSize:13.0];
    seitext.backgroundColor = [UIColor blackColor];
    seitext.text = logString;
    seitext.textColor = [UIColor whiteColor];
    [self.view addSubview:seitext];
    [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [seitext removeFromSuperview];
    }];
    [_toastView addText:[NSString stringWithFormat:@"sei 条数 ： %d",self.seiNum]];
    
}

-(void)onAuthenticationFailed:(QPlayerContext *)context error:(QPlayerAuthenticationErrorType)error{
    
    [_toastView addText:[NSString stringWithFormat:@"鉴权失败 : %d",(int)error]];

}
-(void)onAuthenticationSuccess:(QPlayerContext *)context{
    [_toastView addText:@"鉴权成功"];
    
}
-(void)onSpeedChanged:(QPlayerContext *)context speed:(float)speed{
    [_toastView addText:[NSString stringWithFormat:@"倍速切换为%.2f",speed]];
}

-(void)onQualitySwitchFailed:(QPlayerContext *)context usertype:(NSString *)usertype urlType:(QPlayerURLType)urlType oldQuality:(NSInteger)oldQuality newQuality:(NSInteger)newQuality{
    [_toastView addText:[NSString stringWithFormat:@"切换失败"]];
}

-(void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if (state == QPLAYER_STATE_PREPARE) {
        
        self.subtitleLabel.text = @"";
        [self.maskView loadActivityIndicatorView];
        [_toastView addText:@"开始拉视频数据"];
        [_toastView addDecoderType:[self.maskView getDecoderType]];
    } else if (state == QPLAYER_STATE_PLAYING) {
        //            _maskView.player = _player;
        self.isPlaying = YES;
        [_maskView setPlayButtonState:YES];
        [self showHintViewWithText:@"开始播放器"];
        [_toastView addText:@"播放中"];
        [self.maskView removeActivityIndicatorView];
        
    } else if (state == QPLAYER_STATE_PAUSED_RENDER) {
        [_toastView addText:@"暂停播放"];
        [_maskView setPlayButtonState:NO];
        [self.maskView removeActivityIndicatorView];
    }else if (state == QPLAYER_STATE_STOPPED){
        
        [_toastView addText:@"停止播放"];
        self.subtitleLabel.text = @"";
        [_maskView setPlayButtonState:NO];
    }
    else if (state == QPLAYER_STATE_ERROR){
        [_toastView addText:@"播放错误"];
        [_maskView setPlayButtonState:NO];
    }else if (state == QPLAYER_STATE_COMPLETED){
        
        [_toastView addText:@"播放完成"];
        [_maskView setPlayButtonState:NO];
    }
    else if (state == QPLAYER_STATE_SEEKING){
        
        [self.maskView loadActivityIndicatorView];
    }
    
}


-(void)onBufferingEnd:(QPlayerContext *)context{
    [self.maskView removeActivityIndicatorView];
}
-(void)onBufferingStart:(QPlayerContext *)context{
    [self.maskView loadActivityIndicatorView];
}
-(void)onQualitySwitchComplete:(QPlayerContext *)context usertype:(NSString *)usertype urlType:(QPlayerURLType)urlType oldQuality:(NSInteger)oldQuality newQuality:(NSInteger)newQuality{
    NSString *string = [NSString stringWithFormat:@"清晰度 %ld p",(long)newQuality];
    [self.toastView addText:string];
}
-(void)onShootFailed:(QPlayerContext *)context{
    [_toastView addText:@"截图失败"];
}
-(void)onShootSuccessful:(QPlayerContext *)context imageData:(NSData *)imageData width:(int)width height:(int)height type:(QPlayerShootVideoType)type{
    if(type == QPLAYER_SHOOT_VIDEO_JPEG){
        UIImage *image = [UIImage imageWithData:imageData];
        UIImageView *shootImageView = [[UIImageView alloc]initWithFrame:CGRectMake(50, 50, PL_SCREEN_WIDTH-100, PL_SCREEN_HEIGHT-100)];
        shootImageView.contentMode = UIViewContentModeScaleAspectFit;
        [shootImageView setImage:image];
        shootImageView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:shootImageView];
        
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        [_toastView addText:@"截图成功"];
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [shootImageView removeFromSuperview];
        }];
    }else{
        [_toastView addText:@"截图格式为None"];
    }
}

-(void)onSubtitleEnable:(QPlayerContext *)context enable:(BOOL)enable{
    self.subtitleLabel.text = @"";
    if (enable) {
        
        [_toastView addText:@"字幕开启"];
    }else{
        
        [_toastView addText:@"字幕关闭"];
    }
}

-(void)onSubtitleNameChange:(QPlayerContext *)context name:(NSString *)name{
    [_toastView addText:[NSString stringWithFormat:@"name 更改为 %@",name]];
}
-(void)onSubtitleTextChange:(QPlayerContext *)context text:(NSString *)text{
    NSLog(@"text is :%@",text);
    self.subtitleLabel.text = text;

}
- (void)onSubtitleLoaded:(QPlayerContext *)context name:(NSString *)name result:(BOOL)result{
    if(result){
        [_toastView addText:[NSString stringWithFormat:@"字幕加载成功：%@",name]];
    }
    else{
        [_toastView addText:[NSString stringWithFormat:@"字幕加载失败：%@",name]];
    }
}
-(void)onSubtitleDecoded:(QPlayerContext *)context name:(NSString *)name result:(BOOL)result{
    if(result){
        [_toastView addText:[NSString stringWithFormat:@"字幕Decoded成功：%@",name]];
    }
    else{
        [_toastView addText:[NSString stringWithFormat:@"字幕Decoded失败：%@",name]];
    }
}


#pragma mark - 保存图片到相册出错回调
-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error == nil){
        [_toastView addText:@"保存成功"];
    }
    else{
        [_toastView addText: [NSString stringWithFormat:@"保存失败：%@",error]];
    }
}
#pragma mark - 计时器方法

- (void)onTimer:(NSTimer *)timer {
    self.urlListTableView.tableHeaderView = [_infoHeaderView updateInfoWithInfoArray:[self updateInfoArray]];
}

#pragma mark - 更新播放信息数组

- (NSArray *)updateInfoArray {
    NSString *statusStr = [self updatePlayerStatus];
    NSString *firstVideoTimeStr = [NSString stringWithFormat:@"%d ms",self.firstVideoTime];
//    NSString *renderFPSStr = [NSString stringWithFormat:@"%dfps", self.playerContext.controlHandler.fps];
    NSString *renderFPSStr = [NSString stringWithFormat:@"%dfps", self.myPlayerView.controlHandler.fps];
//    NSString *downSpeedStr = [NSString stringWithFormat:@"%.2fkb/s", self.playerContext.controlHandler.downloadSpeed * 1.0/1000];
    NSString *downSpeedStr = [NSString stringWithFormat:@"%.2fkb/s", self.myPlayerView.controlHandler.downloadSpeed * 1.0/1000];

    NSArray *array = @[statusStr,firstVideoTimeStr,renderFPSStr,downSpeedStr];

    long bufferPositon = self.myPlayerView.controlHandler.bufferPostion;
    NSString *fileUnit = @"ms";

    NSString *fileSizeStr = [NSString stringWithFormat:@"%d%@", bufferPositon, fileUnit];
    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:array];
    [mutableArray addObjectsFromArray:@[fileSizeStr]];
    array = [mutableArray copy];
    return array;
}

- (NSString *)stringByNSTimerinterval:(NSTimeInterval)interval {
    NSInteger min = interval/60;
    NSInteger sec = (NSInteger)interval%60;
    if (min >= 60) {
        NSInteger hour = min/60;
        NSInteger mins = min%60;
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hour, mins, sec];
    } else if (min > 0 && min < 60) {
        return [NSString stringWithFormat:@"%02ld:%02ld", min, sec];
    } else {
        return [NSString stringWithFormat:@"%lds", sec];
    }
}

- (NSString *)updatePlayerStatus {
    NSDictionary *statusDictionary = @{@(QPLAYER_STATE_NONE):@"Unknow",
                                       @(QPLAYER_STATE_INIT):@"init",
                                       @(QPLAYER_STATE_PREPARE):@"PREPARE",
                                       @(QPLAYER_STATE_PLAYING):@"Playing",
                                       @(QPLAYER_STATE_PAUSED_RENDER):@"Paused",
                                       @(QPLAYER_STATE_STOPPED):@"Stopped",
                                       @(QPLAYER_STATE_ERROR):@"Error",
                                       @(QPLAYER_STATE_SEEKING):@"seek",
                                       @(QPLAYER_STATE_COMPLETED):@"Completed"
                                       };
    return  statusDictionary[@(self.myPlayerView.controlHandler.currentPlayerState)];;

}

#pragma mark - 添加点播界面蒙版


- (void)addPlayerMaskView{
    self.maskView = [[QNPlayerMaskView alloc] initWithFrame:CGRectMake(0, 0, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT) player:self.myPlayerView isLiving:NO];
    
    self.maskView.center = self.myPlayerView.center;
    self.maskView.delegate = self;
    self.maskView.backgroundColor = PL_COLOR_RGB(0, 0, 0, 0.35);
        [self.view insertSubview:_maskView aboveSubview:self.myPlayerView];

    [self.maskView.qualitySegMc addTarget:self action:@selector(qualityAction:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - QNPlayerMaskView 代理方法
-(void)setImmediately:(int)immediately{
    self.immediatelyType = immediately;
}
-(void)shootVideoButtonClick{
    [self.myPlayerView.controlHandler shootVideo];

}


- (void)playerMaskView:(QNPlayerMaskView *)playerMaskView didGetBack:(UIButton *)backButton {
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.isFlip) {
        [self forceOrientationLandscape:NO];
    } else{
        [self.myPlayerView.controlHandler stop];
        [self.durationTimer invalidate];
        self.durationTimer = nil;
        
        self.maskView = nil;
        // 更新日志
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)playerMaskView:(QNPlayerMaskView *)playerMaskView isLandscape:(BOOL)isLandscape {
    [self forceOrientationLandscape:isLandscape];

}

-(void)reOpenPlayPlayerMaskView:(QNPlayerMaskView *)playerMaskView{
    QMediaModel *model = _playerModels[_selectedIndex];
    [self.myPlayerView.controlHandler playMediaModel:model startPos:[[QDataHandle shareInstance] getConfiguraPostion]];
    [_maskView setPlayButtonState:YES];

}
- (BOOL)shouldAutorotate

{

    return NO;

}

- (void)forceOrientationLandscape:(BOOL)isLandscape {
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.isFlip = isLandscape;
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationUnknown) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [appDelegate application:[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:self.view.window];
    
    UIDeviceOrientation ori = [UIDevice currentDevice].orientation;
    _isFlip = appDelegate.isFlip;
    if(@available(iOS 16.0,*)){
        [UIViewController attemptRotationToDeviceOrientation];
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
        NSArray *array = [[[UIApplication sharedApplication] connectedScenes] allObjects];
        UIWindowScene *scene = [array firstObject];
        UIInterfaceOrientationMask orientation = isLandscape ? UIInterfaceOrientationMaskLandscape : UIInterfaceOrientationMaskPortrait;
        UIWindowSceneGeometryPreferencesIOS *geometryPreferencesIOS = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:orientation];
        [scene requestGeometryUpdateWithPreferences:geometryPreferencesIOS errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"强制%@错误:%@", isLandscape ? @"横屏" : @"竖屏", error);
        }];
        
        if(isLandscape){
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [self.urlListTableView removeFromSuperview];
            self.myPlayerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
            self.maskView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
            _toastView.frame = CGRectMake(40, scene.screen.bounds.size.width-220, 200, 150);
        }else{
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [self.view addSubview:_urlListTableView];
            self.myPlayerView.frame = CGRectMake(0, _topSpace, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.height*9/16);
            self.maskView.frame = CGRectMake(0, _topSpace, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.height*9/16);
            
            _toastView.frame = CGRectMake(0, scene.screen.bounds.size.width-300, 200, 300);
        }
        
    }else{
        [UIViewController attemptRotationToDeviceOrientation];
        if (isLandscape) {
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            if ([UIDevice currentDevice].orientation != UIInterfaceOrientationLandscapeLeft) {
                
                [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
            }else{
                
                [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeLeft) forKey:@"orientation"];
            }
            [self.urlListTableView removeFromSuperview];
            self.myPlayerView.frame = CGRectMake(0, 0, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT);
            self.maskView.frame = CGRectMake(0, 0, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT);
            _toastView.frame = CGRectMake(40, PL_SCREEN_HEIGHT-220, 200, 150);
        } else {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
            [self.view addSubview:_urlListTableView];
            self.myPlayerView.frame = CGRectMake(0, _topSpace, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT);
            self.maskView.frame = CGRectMake(0, _topSpace, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT);
            _toastView.frame = CGRectMake(0, PL_SCREEN_HEIGHT-300, 200, 300);
        }
        
    }
    
}

#pragma mark - 创建  urlListTableView

- (void)layoutUrlListTableView
{
    self.isPull = YES;
    
    self.urlListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _topSpace + PLAYER_PORTRAIT_HEIGHT, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT - _topSpace - PLAYER_PORTRAIT_HEIGHT) style:UITableViewStylePlain];
    self.urlListTableView.delegate = self;
    self.urlListTableView.dataSource = self;
    self.urlListTableView.sectionHeaderHeight = 36;
    [self.urlListTableView registerClass:[QNURLListTableViewCell class] forCellReuseIdentifier:@"listCell"];
    self.urlListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.titleArray = @[@"status - PLPlayer 的播放状态 :",@"firstVideoTime - 首开时间 :",@"renderFPS - 播放渲染帧率 :",@"downSpeed - 下载速率(kb/s) :"];
    
        NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:_titleArray];
        [mutableArray addObjectsFromArray:@[@"bufferPostion - 缓存大小 :"]];
        _titleArray = [mutableArray copy];
    self.infoHeaderView = [[QNInfoHeaderView alloc] initWithTopMargin:0 titleArray:_titleArray infoArray:[self updateInfoArray]];
    
    self.urlListTableView.tableHeaderView = _infoHeaderView;
    [self.view addSubview:_urlListTableView];
}


#pragma mark - PLPlayerSettingsVcDelegate

- (void)didCompleteConfiguration:(NSArray<QNClassModel *> *)configs {
    [self setUpPlayer:configs];
}

- (void)configurePlayerWithConfigureModel:(PLConfigureModel *)configureModel classModel:(QNClassModel *)classModel {
    NSInteger index = [configureModel.selectedNum integerValue];
    
    if ([classModel.classKey isEqualToString:@"PLPlayerOption"]) {
        if ([configureModel.configuraKey containsString:@"播放速度"]) {
            [self.myPlayerView.controlHandler setSpeed:[configureModel.configuraValue[index] floatValue]];
        }

        if ([configureModel.configuraKey containsString:@"播放起始"]){

        } else if ([configureModel.configuraKey containsString:@"Decoder"]) {
            [self.myPlayerView.controlHandler setDecoderType:(QPlayerDecoder)index];
            
            
        } else if ([configureModel.configuraKey containsString:@"Seek"]) {
            [self.myPlayerView.controlHandler  setSeekMode:index];

        } else if ([configureModel.configuraKey containsString:@"Start Action"]) {
            [self.myPlayerView.controlHandler setStartAction:(QPlayerStart)index];
            
        } else if ([configureModel.configuraKey containsString:@"Render ratio"]) {
            [self.myPlayerView.renderHandler setRenderRatio:(QPlayerRenderRatio)(index + 1)];
            
        } else if ([configureModel.configuraKey containsString:@"色盲模式"]) {
            [self.myPlayerView.renderHandler setBlindType:(QPlayerBlind)index];
        }
        else if ([configureModel.configuraKey containsString:@"SEI"]) {
            if (index == 0) {
                
                [self.myPlayerView.controlHandler setSEIEnable:YES];
            }else{
                [self.myPlayerView.controlHandler setSEIEnable:NO];
            }
        }
        else if ([configureModel.configuraKey containsString:@"鉴权"]) {
            if (index == 0) {
                [self.myPlayerView.controlHandler forceAuthenticationFromNetwork];
            }
        }
        else if ([configureModel.configuraKey containsString:@"后台播放"]){
            if (index == 0) {
                [self.myPlayerView.controlHandler setBackgroundPlayEnable:YES];
            }
            else{
                [self.myPlayerView.controlHandler setBackgroundPlayEnable:NO];
            }
        }
        else if ([configureModel.configuraKey containsString:@"清晰度切换"]){
            _immediatelyType =(int)index;
        }
        else if ([configureModel.configuraKey containsString:@"字幕"]){
            [self.myPlayerView.controlHandler setSubtitleEnable:index==0?NO:YES];
            if(index == 1 ){
                if(![self.myPlayerView.controlHandler.subtitleName isEqual:@"中文"]){
                    [self.myPlayerView.controlHandler setSubtitle:@"中文"];
                }
            }
            else if (index == 2){
                if(![self.myPlayerView.controlHandler.subtitleName isEqual:@"英文"]){
                    [self.myPlayerView.controlHandler setSubtitle:@"英文"];
                }
            }
        }
    }
}

#pragma mark - PLScanViewControlerDelegate 代理方法

- (void)scanQRResult:(NSString *)qrString isLive:(BOOL)isLive{

    if (!isLive) {
        [self.myPlayerView.controlHandler resumeRender];
    }
    NSURL *url;
    if (qrString) {
        url = [NSURL URLWithString:qrString];
    }
    else{
        return;
        
    }
    if (url) {
        QMediaModelBuilder *modleBuilder = [[QMediaModelBuilder alloc] initWithIsLive:isLive];
        
        [modleBuilder addStreamElementWithUserType:@"" urlType:QURL_TYPE_QAUDIO_AND_VIDEO url:qrString quality:0 isSelected:YES backupUrl:@"" referer:@"" renderType:QPLAYER_RENDER_TYPE_PLANE];
        QMediaModel *model = [modleBuilder build];
        [_playerModels addObject:model];
        _selectedIndex = _playerModels.count - 1;
        [self tableView:self.urlListTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:_selectedIndex inSection:0]];

        [self.urlListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        [self.urlListTableView reloadData];

    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"scan url error" message:qrString delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - 扫码二维码

- (void)scanCodeAction:(UIButton *)scanButton {
    
    if (self.myPlayerView.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING) {
        [self.myPlayerView.controlHandler pauseRender];
    }
    self.scanClick = YES;
    QNScanViewController *scanViewController = [[QNScanViewController alloc] init];
    scanViewController.delegate = self;
    [self.navigationController pushViewController:scanViewController animated:YES];
}



- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView 代理方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _playerModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QNURLListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"listCell" forIndexPath:indexPath];
    [cell configureListURLString:_playerModels[indexPath.row].streamElements[0].url index:indexPath.row];
    cell.deleteButton.tag = 100 + indexPath.row;
    [cell.deleteButton addTarget:self action:@selector(deleteUrlString:) forControlEvents:UIControlEventTouchDown];
    if (indexPath.row == _selectedIndex) {
        cell.urlLabel.textColor = PL_SELECTED_BLUE;
        cell.urlLabel.font = PL_FONT_MEDIUM(14);
    } else {
        cell.urlLabel.textColor = [UIColor blackColor];
        cell.urlLabel.font = PL_FONT_LIGHT(13);
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [QNURLListTableViewCell configureListCellHeightWithURLString:_playerModels[indexPath.row].streamElements[0].url index:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *selectedURL = [NSURL URLWithString:_playerModels[indexPath.row].streamElements[0].url];
    if (self.myPlayerView.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING) {
        [self.myPlayerView.controlHandler pauseRender];
    }
    
    _selectedIndex = indexPath.row;
    [_urlListTableView reloadData];
    
    QMediaModel *model = _playerModels[indexPath.row];
    self.maskView.isLiving = model.isLive;
    if(model.streamElements.count > 1){
        [self.maskView.qualitySegMc removeAllSegments];
        int index = 0;
        int indexSel = 0;
        for (QStreamElement* modle0 in model.streamElements) {
            if(modle0.isSelected == YES){
                break;
            }
            indexSel ++;
        }
    
        
        for (QStreamElement* modle0 in model.streamElements) {
            if ([modle0.url isEqual:@"http://demo-videos.qnsdk.com/only-video-1080p-60fps.m4s"]) {
                
                self.maskView.qualitySegMc.hidden = YES;
            }else{
                
                [self.maskView.qualitySegMc insertSegmentWithTitle:[NSString stringWithFormat:@"%dp",modle0.quality] atIndex:index animated:NO];
                index++;
            }
        }
        self.maskView.qualitySegMc.selectedSegmentIndex = indexSel;
    }else{
        [self.maskView.qualitySegMc removeAllSegments];
        self.maskView.qualitySegMc.hidden = YES;
    }
    
    if ([[QDataHandle shareInstance] getAuthenticationState]) {
        [self.myPlayerView.controlHandler forceAuthenticationFromNetwork];
    }
    
    //开启此处即开启VR的陀螺仪，未验证，可能存在未知bug
//    BOOL isVR = false;
//    for (QStreamElement *stream in model.streamElements) {
//        if(stream.renderType == QPLAYER_RENDER_TYPE_PANORAMA_EQUIRECT_ANGULAR){
//            isVR = true;
//            break;
//        }
//    }
//    if(isVR == true){
//        [self.maskView gyroscopeStart];
//    }
//    else{
//        [self.maskView gyroscopeEnd];
//    }
    [self.myPlayerView.controlHandler playMediaModel:model startPos:[[QDataHandle shareInstance] getConfiguraPostion]];
    [_maskView setPlayButtonState:NO];
    [self judgeWeatherIsLiveWithURL:selectedURL];
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PL_SCREEN_WIDTH, 36)];
    headerView.backgroundColor = PL_COLOR_RGB(212, 220, 240, 1);
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 179, 26)];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = PL_FONT_MEDIUM(14);

    titleLabel.text = @"PLPlayer 点播 URL 列表";

    [headerView addSubview:titleLabel];
    
    
    UIButton *scanButton = [[UIButton alloc] initWithFrame:CGRectMake(245, 7, 22, 22)];
    scanButton.backgroundColor = PL_COLOR_RGB(81, 81, 81, 1);
    scanButton.layer.cornerRadius = 1;
    [scanButton setImage:[UIImage imageNamed:@"pl_scan"] forState:UIControlStateNormal];
    [scanButton addTarget:self action:@selector(scanCodeAction:) forControlEvents:UIControlEventTouchDown];
//    [headerView addSubview:scanButton];
    return headerView;
}

- (void)deleteUrlString:(UIButton *)button {
    NSInteger index = button.tag - 100;
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"删除播放地址" message:[NSString stringWithFormat:@"亲，是否确定要删除播放地址：%@ ？", _playerModels[index]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
    }];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.playerModels removeObjectAtIndex:index];
        if(index == self.selectedIndex){
            self.selectedIndex = 0;
            [self tableView:self.urlListTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
            [self.urlListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];

        }
        if (self.playerModels.count != 0) {
            [self.urlListTableView reloadData];
        } else{
            [self.urlListTableView removeFromSuperview];
            [self showHintViewWithText:@"暂无直播记录，快去扫描二维码观看吧 ~"];
        }
    }];
    [alertVc addAction:cancelAction];
    [alertVc addAction:sureAction];
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark - 显示提示信息

- (void)showHintViewWithText:(NSString *)hintStr
{
    self.hintLabel.text = hintStr;
    if ([self.view.subviews containsObject:_hintLabel]) {
        [self.hintLabel removeFromSuperview];
    }
    [self.view addSubview:_hintLabel];
}



- (void)judgeWeatherIsLiveWithURL:(NSURL *)URL {
    NSString *scheme = URL.scheme;
    NSString *pathExtension = URL.pathExtension;
    BOOL isLive;
    if (([scheme isEqualToString:@"rtmp"] && ![pathExtension isEqualToString:@"pili"]) ||
        ([scheme isEqualToString:@"http"] && [pathExtension isEqualToString:@"flv"])) {
        isLive = YES;
    } else {
        isLive = NO;
    }
    [self updateSegmentAndInfomationWithLive:isLive];
}

- (void)updateSegmentAndInfomationWithLive:(BOOL)isLive {
    if (isLive) {
        self.segment.selectedSegmentIndex = 1;
    } else{
        self.segment.selectedSegmentIndex = 0;
    }
    [_urlListTableView removeFromSuperview];
    [self layoutUrlListTableView];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)qualityAction:(UISegmentedControl *)segm{
    NSInteger index = segm.selectedSegmentIndex;
    QMediaModel *model = self.playerModels[_selectedIndex];
    
    int tempIndex = 0;
    for (QStreamElement* modle0 in model.streamElements) {
        modle0.isSelected = NO;
        
        if (index == tempIndex) {
            modle0.isSelected = YES;
        }
        tempIndex ++;
    }
    BOOL switchQualityBool;
    if(self.immediatelyType == 0){
        
        switchQualityBool = [self.myPlayerView.controlHandler switchQuality:model.streamElements[index].userType urlType:model.streamElements[index].urlType quality:model.streamElements[index].quality immediately:true];
    }else if(self.immediatelyType == 1){
        
        switchQualityBool = [self.myPlayerView.controlHandler switchQuality:model.streamElements[index].userType urlType:model.streamElements[index].urlType quality:model.streamElements[index].quality immediately:false];
    }
    else{
        switchQualityBool = [self.myPlayerView.controlHandler switchQuality:model.streamElements[index].userType urlType:model.streamElements[index].urlType quality:model.streamElements[index].quality immediately:model.isLive];
    }
    if (!switchQualityBool) {
        self.maskView.qualitySegMc.selectedSegmentIndex = self.UpQualityIndex;

        [_toastView addText:@"不可重复切换"];
    }else{
        _UpQualityIndex = index;
        
        [_toastView addText:[NSString stringWithFormat:@"即将切换为：%d p",model.streamElements[index].quality]];
    }
}




@end
