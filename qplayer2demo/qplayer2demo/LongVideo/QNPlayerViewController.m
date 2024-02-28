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
#import "NSDataToCVPixelBufferRefHelper.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#define PL_PLAYER_VIDEO_ROOT_FOLDER @"PLPlayerFloder"
#define GET_PL_PLAYER_VIDEO_FOLDER(folderName) [PL_PLAYER_VIDEO_ROOT_FOLDER stringByAppendingPathComponent:folderName]
#define PL_PLAYER_VIDEO_REVERSER GET_PL_PLAYER_VIDEO_FOLDER(@"PLPlayerCacheFile")
#define PL_PUSH_STREAMING_URL @"rtmp://pili-publish.qnsdk.com/sdk-live/1234"
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
QIPlayerSubtitleListener,
QIPlayerVideoDecodeListener,
QIPlayerAudioDataListener,
QIPlayerVideoDataListener
>

/** 播放器蒙版视图 **/
@property (nonatomic, strong) QNPlayerMaskView *mMaskView;

/** 界面显示的播放信息数组 **/
@property (nonatomic, strong) NSArray *mTitleArray;

@property (nonatomic, strong) QNInfoHeaderView *mInfoHeaderView;
@property (nonatomic, strong) UITableView *mUrlListTableView;

/** 被选中 URL 在列表中的下标 **/
@property (nonatomic, assign) NSInteger mSelectedIndex;
/** 是否显示 URL 列表 **/
@property (nonatomic, assign) BOOL mIsPull;

@property (nonatomic) int mImmediatelyType;
/** 无可显示 URL 的提示 **/
@property (nonatomic, strong) UILabel *mHintLabel;

@property (nonatomic, strong) UILabel *mSubtitleLabel;
@property (nonatomic, strong) NSTimer *mDurationTimer;
@property (nonatomic, assign) BOOL mIsFlip;
@property (nonatomic, assign) CGFloat mTopSpace;

/** 分栏选择 **/
@property (nonatomic, strong) UISegmentedControl *mSegment;
@property (nonatomic, assign) BOOL mIsLiving;
@property (nonatomic, assign) NSInteger mModeCount;

@property (nonatomic, strong) NSMutableArray<QMediaModel *> *mPlayerModels;

/**toast **/
@property (nonatomic, strong) QNToastView *mToastView;

@property (nonatomic, assign) BOOL mScanClick;
@property (nonatomic, strong) QPlayerView *mPlayerView;
@property (nonatomic, assign) BOOL mIsPlaying;
@property (nonatomic, assign) NSInteger mUpQualityIndex;
@property (nonatomic, assign) NSInteger mFirstVideoTime;
@property (nonatomic, assign) int mSEINum;
@property (nonatomic, strong) NSString *mSEIString;

@property (nonatomic, assign) BOOL mIsStartPush;
@property (nonatomic, assign) int mVideoHeight;
@property (nonatomic, assign) int mVideoWidth;
@property (nonatomic, strong) PLStreamingSession *mSession;

@end

@implementation QNPlayerViewController

- (void)dealloc {
    if (self.mSession.isRunning) {
        [self.mSession stop];
        self.mSession.delegate = nil;
        self.mSession = nil;
    }

    NSLog(@"QNPlayerViewController dealloc");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    self.mIsStartPush = false;
    self.mScanClick = NO;
    self.mVideoWidth = 0;
    self.mVideoHeight = 0;
    if (appDelegate.mIsFlip) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    } else{
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if (!self.mScanClick) {
        self.mToastView = nil;
        [self.mPlayerModels removeAllObjects];
        self.mPlayerModels = nil;
        self.mPlayerView = nil;
        self.mPlayerConfigArray = nil;
    }

}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!self.mScanClick) {
        
        [self.mDurationTimer invalidate];
        self.mDurationTimer = nil;
        [self.mPlayerView.controlHandler stop];
        
        [self.mPlayerView.controlHandler playerRelease];
        
        
    }
    
    
}



- (void)viewDidLoad {
    [super viewDidLoad];

    self.mScanClick = NO;
    self.mIsPlaying = NO;
    self.mPlayerConfigArray = [QDataHandle shareInstance].mPlayerConfigArray;
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDir stringByAppendingPathComponent:@"urls.json"];
    
    NSData *data=[[NSData alloc] initWithContentsOfFile:path];
    if (!data) {
        path=[[NSBundle mainBundle] pathForResource:@"urls" ofType:@"json"];
        data=[[NSData alloc] initWithContentsOfFile:path];
    }
    NSArray *urlArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    self.mPlayerModels = [NSMutableArray array];
   
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
        [self.mPlayerModels addObject:model];
        
    }

    [self.mDurationTimer invalidate];
    self.mDurationTimer = nil;
    self.mDurationTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.barTintColor = PL_SEGMENT_BG_COLOR;
    [self.navigationItem setHidesBackButton:YES];
        
    self.mModeCount = 0;

    if (PL_HAS_NOTCH) {
        self.mTopSpace = 88;
    } else {
        self.mTopSpace = 64;
    }
    
    // PLPlayer 应用
    [self setUpPlayer:self.mPlayerConfigArray];
    
//    self.subtitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.myPlayerView.frame.size.width/2, self.myPlayerView.frame.size.height-60, 50, 30)];
    self.mSubtitleLabel = [[UILabel alloc]init];

    self.mSubtitleLabel.backgroundColor = [UIColor clearColor];
    self.mSubtitleLabel.textColor = [UIColor whiteColor];
    self.mSubtitleLabel.numberOfLines = 0;
    [self.mSubtitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.mSubtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.mPlayerView addSubview:self.mSubtitleLabel];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.mSubtitleLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.mPlayerView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.mSubtitleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.mPlayerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.mSubtitleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.mPlayerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-70.0];
    
    [NSLayoutConstraint activateConstraints:@[widthConstraint, centerXConstraint, bottomConstraint]];
    [self addPlayerMaskView];

    [self layoutUrlListTableView];
    [self setPLStream];

    self.mToastView = [[QNToastView alloc]initWithFrame:CGRectMake(0, PL_SCREEN_HEIGHT-300, 200, 300)];
    [self.view addSubview:self.mToastView];
    [self playerContextAllCallBack];
    
    
}

#pragma mark - 初始化 PLStreaming
-(void)setPLStream{
    //默认配置
    PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
    PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
    videoStreamingConfiguration.videoSize =CGSizeMake(1920/2, 1080/2);
    self.mSession = [[PLStreamingSession alloc] initWithVideoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
    
}
-(void)pushStreamButtonClick:(BOOL)isSelected{
    self.mIsStartPush = isSelected;
    if(isSelected){
        __weak typeof(self) weakSelf = self;
        NSURL *url = [NSURL URLWithString:PL_PUSH_STREAMING_URL];
        [self.mSession startWithPushURL:url feedback:^(PLStreamStartStateFeedback feedback) {
            [weakSelf streamStateAlert:feedback];
            
            [self.mPlayerView.controlHandler addPlayerVideoDataListener:self];
            [self.mPlayerView.controlHandler addPlayerAudioDataListener:self];
            [NSDataToCVPixelBufferRefHelper ClearDataFile];
        }];
    }else{
        [self.mSession stop];
        [self.mPlayerView.controlHandler removePlayerAudioDataListener:self];
        [self.mPlayerView.controlHandler removePlayerVideoDataListener:self];
    }
}
- (void)streamStateAlert:(PLStreamStartStateFeedback)feedback {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (feedback) {
            case PLStreamStartStateSuccess:
                NSLog(@"成功开始推流!");
                self.mIsStartPush = true;
                [weakSelf.mToastView addText:@"成功开始推流!"];
                break;
            case PLStreamStartStateSessionUnknownError:
                NSLog(@"发生未知错误无法启动!");
                [weakSelf.mToastView addText:@"发生未知错误无法启动!"];
                break;
            case PLStreamStartStateSessionStillRunning:
                NSLog(@"已经在运行中，无需重复启动!");
                [weakSelf.mToastView addText:@"已经在运行中，无需重复启动!"];
                break;
            case PLStreamStartStateStreamURLUnauthorized:
                NSLog(@"当前的 StreamURL 没有被授权!");
                [weakSelf.mToastView addText:@"当前的 StreamURL 没有被授权!"];
                break;
            case PLStreamStartStateSessionConnectStreamError:
                NSLog(@"建立 socket 连接错误!");
                [weakSelf.mToastView addText:@"建立 socket 连接错误!"];
                break;
            case PLStreamStartStateSessionPushURLInvalid:
                NSLog(@"当前传入的 pushURL 无效!");
                [weakSelf.mToastView addText:@"当前传入的 pushURL 无效!"];
                break;
            default:
                break;
        }
    });
}

#pragma mark - 初始化 PLPlayer


- (CVPixelBufferRef)createSampleBufferFromData:(NSData *)data width:(int)width height:(int)height {
    // 创建CVPixelBufferRef
    CVPixelBufferRef pixelBuffer = NULL;
//    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8Planar, (__bridge CFDictionaryRef)pixelAttributes, &pixelBuffer);
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8Planar, NULL, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        NSLog(@"Unable to create pixel buffer");
        return NULL;
    }

    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    // 获取pixel buffer的Y和UV平面基地址
    uint8_t *baseAddressY = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *baseAddressU = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    uint8_t *baseAddressV = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);

    // 从NSData中复制Y和UV平面的数据
    NSLog(@"data.bytes width : %d height : %d length :%lu",width,height,(unsigned long)data.length);
    memcpy(baseAddressY, data.bytes, width * height);
    memcpy(baseAddressU, data.bytes + width * height, width * height / 4);
    
    memcpy(baseAddressV, data.bytes + (width * height)*5/4, width * height / 4);
    
    // 解锁pixel buffer的基地址
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    

    return pixelBuffer;
}


-(CMSampleBufferRef)CVPixelBufferRefToCMSampleBufferRef : (CVPixelBufferRef) pixelBuffer{

    // 创建一个视频信息描述
    CMVideoFormatDescriptionRef videoFormatDescription;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoFormatDescription);

    // 创建一个时间戳
    CMTime presentationTimeStamp = CMTimeMake(0, 30000);

    // 创建一个 CMSampleTimingInfo 结构
    CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = presentationTimeStamp;

    // 创建一个 CMSampleBufferRef
    CMSampleBufferRef sampleBuffer;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoFormatDescription, &timingInfo, &sampleBuffer);
    
    CFRelease(videoFormatDescription);
    return sampleBuffer;

}

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

    self.mPlayerView = [[QPlayerView alloc]initWithFrame:CGRectMake(0, self.mTopSpace, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT) APPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];
    [self.view addSubview:self.mPlayerView];
    [self.mPlayerView.controlHandler forceAuthenticationFromNetwork];
    QMediaModel *model = self.mPlayerModels.firstObject;

    for (QNClassModel* model in configs) {
        for (PLConfigureModel* configModel in model.classValue) {
            if ([model.classKey isEqualToString:@"PLPlayerOption"]) {
                [self configurePlayerWithConfigureModel:configModel classModel:model];;
            }
        }
    }
    
    [self.mPlayerView.controlHandler playMediaModel:model startPos:[[QDataHandle shareInstance] getConfiguraPostion]];
    
//    [self.mPlayerView.controlHandler setVideoDataType:QVIDEO_TYPE_NV12];
}

#pragma mark - PlayerListenerDelegate

-(void)playerContextAllCallBack{

    [self.mPlayerView.controlHandler addPlayerStateListener:self];
    [self.mPlayerView.controlHandler addPlayerBufferingChangeListener:self];
    [self.mPlayerView.controlHandler addPlayerQualityListener:self];
    [self.mPlayerView.controlHandler addPlayerSpeedChangeListener:self];
    [self.mPlayerView.controlHandler addPlayerAuthenticationListener:self];
    [self.mPlayerView.controlHandler addPlayerSEIDataListener:self];
    [self.mPlayerView.renderHandler addPlayerRenderListener:self];
    [self.mPlayerView.controlHandler addPlayerShootVideoListener:self];
    [self.mPlayerView.controlHandler addPlayerVideoFrameSizeChangeListener:self];
    [self.mPlayerView.controlHandler addPlayerSeekListener:self];
    [self.mPlayerView.controlHandler addPlayerSubtitleListener:self];
    [self.mPlayerView.controlHandler addPlayerVideoDecodeTypeListener:self];
    
    
}
-(void)onSeekFailed:(QPlayerContext *)context{
    [self.mToastView addText:@"seek失败"];
}
-(void)onSeekSuccess:(QPlayerContext *)context{
    [self.mToastView addText:@"seek成功"];
    
    [self.mMaskView removeActivityIndicatorView];
}
-(void)onVideoFrameSizeChanged:(QPlayerContext *)context width:(int)width height:(int)height{
    
    [self.mToastView addText:[NSString stringWithFormat:@"视频宽高 width:%d height:%d",width,height]];
}
-(void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    self.mFirstVideoTime = elapsedTime;
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
    if ([self.mSEIString isEqual:str]){
        self.mSEINum++;
    }else{
        self.mSEINum = 1;
        self.mSEIString = str;
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
    [self.mToastView addText:[NSString stringWithFormat:@"sei 条数 ： %d",self.mSEINum]];
    
}

-(void)onAuthenticationFailed:(QPlayerContext *)context error:(QPlayerAuthenticationErrorType)error{
    
    [self.mToastView addText:[NSString stringWithFormat:@"鉴权失败 : %d",(int)error]];

}
-(void)onAuthenticationSuccess:(QPlayerContext *)context{
    [self.mToastView addText:@"鉴权成功"];
    
}
-(void)onSpeedChanged:(QPlayerContext *)context speed:(float)speed{
    [self.mToastView addText:[NSString stringWithFormat:@"倍速切换为%.2f",speed]];
}

-(void)onQualitySwitchFailed:(QPlayerContext *)context usertype:(NSString *)usertype urlType:(QPlayerURLType)urlType oldQuality:(NSInteger)oldQuality newQuality:(NSInteger)newQuality{
    [self.mToastView addText:[NSString stringWithFormat:@"切换失败"]];
}

-(void)onDecodeFailed:(QPlayerContext *)context retry:(BOOL)retry{
    if(retry){
        
        [self.mToastView addText:[NSString stringWithFormat:@"解码失败 ： retry true"]];
    }else{
        [self.mToastView addText:[NSString stringWithFormat:@"解码失败 ： retry false"]];
    }
}
-(void)onVideoDecodeByType:(QPlayerContext *)context Type:(QPlayerDecoderType)type{
    NSString* text = @"使用的解码类型：";
    switch (type) {
        case QPLAYER_DECODER_TYPE_NONE:
            text = [NSString stringWithFormat:@"%@ none",text];
            break;
        case QPLAYER_DECODER_TYPE_SOFTWARE:
            text = [NSString stringWithFormat:@"%@ 软解",text];
            break;
        case QPLAYER_DECODER_TYPE_HARDWARE:
            text = [NSString stringWithFormat:@"%@ 硬解",text];
            break;
        default:
            text = [NSString stringWithFormat:@"%@ none",text];
            break;
    }
    [self.mToastView addText:text];
}
//n 用于限制文件写入次数的，此处仅写入100帧。发布前要删除该内容，不限制会导致文件过大 发生crash
-(void)onVideoData:(QPlayerContext *)context width:(int)width height:(int)height videoType:(QVideoType)videoType buffer:(NSData *)buffer{
    
    if (self.mIsStartPush && self.mVideoWidth != 0 && self.mVideoHeight != 0 && (self.mVideoHeight != height || self.mVideoWidth != width)) {
        if (self.mSession != nil) {
            [self.mSession stop];
            [self.mSession destroy];
            self.mSession = nil;
        }
        self.mVideoHeight = height;
        self.mVideoWidth = width;
        //推流端视频编码参数要求最大值为 width：1280 height：720 故超过该值的等比例缩小
        while (self.mVideoWidth > 1280||self.mVideoHeight>720) {
            self.mVideoWidth = self.mVideoWidth/2;
            self.mVideoHeight = self.mVideoHeight/2;
        }
        self.mIsStartPush = false;
        PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
        videoStreamingConfiguration.videoSize =CGSizeMake(self.mVideoWidth, self.mVideoHeight);
        PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
        self.mSession = [[PLStreamingSession alloc] initWithVideoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
        __weak typeof(self) weakSelf = self;
        NSURL *url = [NSURL URLWithString:PL_PUSH_STREAMING_URL];
        [self.mSession startWithPushURL:url feedback:^(PLStreamStartStateFeedback feedback) {
            [weakSelf streamStateAlert:feedback];
            [NSDataToCVPixelBufferRefHelper ClearDataFile];
        }];
    }
    self.mVideoHeight = height;
    self.mVideoWidth = width;
    if(self.mIsStartPush &&videoType == QVIDEO_TYPE_RGBA){
        CVPixelBufferRef piexel = [NSDataToCVPixelBufferRefHelper NSDataToCVPixelBufferRef:buffer height:height width:width type:videoType];
        if(piexel != nil){
            CFRelease(piexel);
        }
    }
    if(self.mIsStartPush && videoType == QVIDEO_TYPE_NV12){
        CVPixelBufferRef piexel = [NSDataToCVPixelBufferRefHelper NSDataToCVPixelBufferRef:buffer height:height width:width type:videoType];
        [self.mSession pushPixelBuffer:piexel completion:^(BOOL success) {
            if (success) {
                NSLog(@"push stream success");
            }else{
                NSLog(@"push stream false");
            }
        }];
        if(piexel != nil){
            CFRelease(piexel);
        }
    }
    if(self.mIsStartPush && videoType==QVIDEO_TYPE_YUV_420P){
        CVPixelBufferRef piexel = [NSDataToCVPixelBufferRefHelper NSDataToCVPixelBufferRef:buffer height:height width:width type:videoType];
//        CVPixelBufferLockBaseAddress(piexel, 0);
//
//        // Y 分量
//        uint8_t *yData = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(piexel, 0);
//        size_t yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(piexel, 0);
//
//        // U 分量
//        uint8_t *uData = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(piexel, 1);
//        size_t uBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(piexel, 1);
//
//        // V 分量
//        uint8_t *vData = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(piexel, 2);
//        size_t vBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(piexel, 2);
//
//        // 图像宽度和高度
//        size_t width = CVPixelBufferGetWidth(piexel);
//        size_t height = CVPixelBufferGetHeight(piexel);
//
//        // 创建 YUV 数据的 RGB 数据
//        size_t rgbBytesPerRow = width * 4; // RGBA 格式
//        uint8_t *rgbData = (uint8_t *)malloc(rgbBytesPerRow * height);
//        memset(rgbData, 0, rgbBytesPerRow * height);
//        for (int i = 0; i < height; i++) {
//            for (int j = 0; j < width; j++) {
//                uint8_t y = yData[i * yBytesPerRow + j];
//                uint8_t u = uData[(i / 2) * uBytesPerRow + (j / 2)];
//                uint8_t v = vData[(i / 2) * vBytesPerRow + (j / 2)];
//
//                int32_t r = (int32_t)(y + 1.4075 * (v - 128));
//                int32_t g = (int32_t)(y - 0.3455 * (u - 128) - 0.7169 * (v - 128));
//                int32_t b = (int32_t)(y + 1.779 * (u - 128));
//
//                r = MIN(MAX(0, r), 255);
//                g = MIN(MAX(0, g), 255);
//                b = MIN(MAX(0, b), 255);
//
//                rgbData[i * rgbBytesPerRow + j * 4] = (uint8_t)r;
//                rgbData[i * rgbBytesPerRow + j * 4 + 1] = (uint8_t)g;
//                rgbData[i * rgbBytesPerRow + j * 4 + 2] = (uint8_t)b;
//                rgbData[i * rgbBytesPerRow + j * 4 + 3] = 255; // 不透明度设置为255
//            }
//        }
//
//        // 创建 RGB 数据的 CGDataProviderRef
//        CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbData, rgbBytesPerRow * height, NULL);
//        
//        // 创建 RGB 的位图上下文
//        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
//        CGImageRef rgbImageRef = CGImageCreate(width, height, 8, 32, rgbBytesPerRow, colorSpace, bitmapInfo, dataProvider, NULL, NO, kCGRenderingIntentDefault);
//
//        // 创建 UIImage
//        UIImage *image = [UIImage imageWithCGImage:rgbImageRef];
//
//        // 释放资源
//        CVPixelBufferUnlockBaseAddress(piexel, 0);
//        CGColorSpaceRelease(colorSpace);
//        CGDataProviderRelease(dataProvider);
//        CGImageRelease(rgbImageRef);
//        free(rgbData);
//
//        // 将 UIImage 保存到相册
//        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//            [PHAssetChangeRequest creationRequestForAssetFromImage:image];
//        } completionHandler:^(BOOL success, NSError *error) {
//            if (success) {
//                NSLog(@"Image saved to photo library");
//            } else {
//                NSLog(@"Error saving image to photo library: %@", error);
//            }
//        }];
        [self.mSession pushPixelBuffer:piexel completion:^(BOOL success) {
            if (success) {
                NSLog(@"push stream success");
            }else{
                NSLog(@"push stream false");
            }
        }];
        if(piexel != nil){
            CFRelease(piexel);
        }
    }
}
-(void)onAudioData:(QPlayerContext *)context sampleRate:(int)sampleRate format:(QSampleFormat)format channelNum:(int)channelNum channelLayout:(QChannelLayout)channelLayout data:(NSData *)data{
    if (self.mIsStartPush) {
        
        AudioStreamBasicDescription audioFormatDesc;
        audioFormatDesc.mSampleRate = sampleRate;
        audioFormatDesc.mFormatID = kAudioFormatLinearPCM;
        audioFormatDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioFormatDesc.mFramesPerPacket = 1;
        audioFormatDesc.mChannelsPerFrame = channelNum;
        audioFormatDesc.mBitsPerChannel = 16;
        audioFormatDesc.mBytesPerFrame = (audioFormatDesc.mBitsPerChannel/8)  * audioFormatDesc.mChannelsPerFrame;
        audioFormatDesc.mBytesPerPacket = audioFormatDesc.mBytesPerFrame * audioFormatDesc.mFramesPerPacket;
        audioFormatDesc.mReserved = 0;

        AudioBuffer audioBuffer;

        audioBuffer.mNumberChannels = channelNum;
        audioBuffer.mDataByteSize = (UInt32)[data length];

        audioBuffer.mData = malloc( audioBuffer.mDataByteSize );

        [data getBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
        [self.mSession pushAudioBuffer:&audioBuffer asbd:&audioFormatDesc completion:^(BOOL success) {
            
        }];
    }
    

}

-(void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if (state == QPLAYER_STATE_PREPARE) {
        
        self.mSubtitleLabel.text = @"";
        [self.mMaskView loadActivityIndicatorView];
        [self.mToastView addText:@"开始拉视频数据"];
        [self.mToastView addDecoderType:[self.mMaskView getDecoderType]];
    } else if (state == QPLAYER_STATE_PLAYING) {
        //            _maskView.player = _player;
        self.mIsPlaying = YES;
        [self.mMaskView setPlayButtonState:YES];
        [self showHintViewWithText:@"开始播放器"];
        [self.mToastView addText:@"播放中"];
        [self.mMaskView removeActivityIndicatorView];
        
    } else if (state == QPLAYER_STATE_PAUSED_RENDER) {
        [self.mToastView addText:@"暂停播放"];
        [self.mMaskView setPlayButtonState:NO];
        [self.mMaskView removeActivityIndicatorView];
    }else if (state == QPLAYER_STATE_STOPPED){
        
        [self.mToastView addText:@"停止播放"];
        self.mSubtitleLabel.text = @"";
        [self.mMaskView setPlayButtonState:NO];
    }
    else if (state == QPLAYER_STATE_ERROR){
        [self.mToastView addText:@"播放错误"];
        [self.mMaskView setPlayButtonState:NO];
    }else if (state == QPLAYER_STATE_COMPLETED){
        
        [self.mToastView addText:@"播放完成"];
        [self.mMaskView setPlayButtonState:NO];
    }
    else if (state == QPLAYER_STATE_SEEKING){
        
        [self.mMaskView loadActivityIndicatorView];
    }
    
}


-(void)onBufferingEnd:(QPlayerContext *)context{
    [self.mMaskView removeActivityIndicatorView];
}
-(void)onBufferingStart:(QPlayerContext *)context{
    [self.mMaskView loadActivityIndicatorView];
}
-(void)onQualitySwitchComplete:(QPlayerContext *)context usertype:(NSString *)usertype urlType:(QPlayerURLType)urlType oldQuality:(NSInteger)oldQuality newQuality:(NSInteger)newQuality{
    NSString *string = [NSString stringWithFormat:@"清晰度 %ld p",(long)newQuality];
    [self.mToastView addText:string];
}
-(void)onShootFailed:(QPlayerContext *)context{
    [self.mToastView addText:@"截图失败"];
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
        [self.mToastView addText:@"截图成功"];
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [shootImageView removeFromSuperview];
        }];
    }else{
        [self.mToastView addText:@"截图格式为None"];
    }
}

-(void)onSubtitleEnable:(QPlayerContext *)context enable:(BOOL)enable{
    self.mSubtitleLabel.text = @"";
    if (enable) {
        
        [self.mToastView addText:@"字幕开启"];
    }else{
        
        [self.mToastView addText:@"字幕关闭"];
    }
}

-(void)onSubtitleNameChange:(QPlayerContext *)context name:(NSString *)name{
    [self.mToastView addText:[NSString stringWithFormat:@"name 更改为 %@",name]];
}
-(void)onSubtitleTextChange:(QPlayerContext *)context text:(NSString *)text{
    NSLog(@"text is :%@",text);
    self.mSubtitleLabel.text = text;

}
- (void)onSubtitleLoaded:(QPlayerContext *)context name:(NSString *)name result:(BOOL)result{
    if(result){
        [self.mToastView addText:[NSString stringWithFormat:@"字幕加载成功：%@",name]];
    }
    else{
        [self.mToastView addText:[NSString stringWithFormat:@"字幕加载失败：%@",name]];
    }
}
-(void)onSubtitleDecoded:(QPlayerContext *)context name:(NSString *)name result:(BOOL)result{
    if(result){
        [self.mToastView addText:[NSString stringWithFormat:@"字幕Decoded成功：%@",name]];
    }
    else{
        [self.mToastView addText:[NSString stringWithFormat:@"字幕Decoded失败：%@",name]];
    }
}




#pragma mark - 保存图片到相册出错回调
-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error == nil){
        [self.mToastView addText:@"保存成功"];
    }
    else{
        [self.mToastView addText: [NSString stringWithFormat:@"保存失败：%@",error]];
    }
}
#pragma mark - 计时器方法

- (void)onTimer:(NSTimer *)timer {
    self.mUrlListTableView.tableHeaderView = [self.mInfoHeaderView updateInfoWithInfoArray:[self updateInfoArray]];
}

#pragma mark - 更新播放信息数组

- (NSArray *)updateInfoArray {
    NSString *statusStr = [self updatePlayerStatus];
    NSString *firstVideoTimeStr = [NSString stringWithFormat:@"%d ms",self.mFirstVideoTime];
//    NSString *renderFPSStr = [NSString stringWithFormat:@"%dfps", self.playerContext.controlHandler.fps];
    NSString *renderFPSStr = [NSString stringWithFormat:@"%dfps", self.mPlayerView.controlHandler.fps];
//    NSString *downSpeedStr = [NSString stringWithFormat:@"%.2fkb/s", self.playerContext.controlHandler.downloadSpeed * 1.0/1000];
    NSString *downSpeedStr = [NSString stringWithFormat:@"%.2fkb/s", self.mPlayerView.controlHandler.downloadSpeed * 1.0/1000];

    NSArray *array = @[statusStr,firstVideoTimeStr,renderFPSStr,downSpeedStr];

    long bufferPositon = self.mPlayerView.controlHandler.bufferPostion;
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
//    return statusDictionary[@(self.playerContext.controlHandler.currentPlayerState)];
    return  statusDictionary[@(self.mPlayerView.controlHandler.currentPlayerState)];;

}

#pragma mark - 添加点播界面蒙版


- (void)addPlayerMaskView{
    self.mMaskView = [[QNPlayerMaskView alloc] initWithFrame:CGRectMake(0, 0, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT) player:self.mPlayerView isLiving:NO];
    
    self.mMaskView.center = self.mPlayerView.center;
    self.mMaskView.mDelegate = self;
    self.mMaskView.backgroundColor = PL_COLOR_RGB(0, 0, 0, 0.35);
        [self.view insertSubview:self.mMaskView aboveSubview:self.mPlayerView];

    [self.mMaskView.mQualitySegMc addTarget:self action:@selector(qualityAction:) forControlEvents:UIControlEventValueChanged];
}

#pragma mark - QNPlayerMaskView 代理方法
-(void)setImmediately:(int)immediately{
    self.mImmediatelyType = immediately;
}
-(void)shootVideoButtonClick{
    [self.mPlayerView.controlHandler shootVideo];

}


- (void)playerMaskView:(QNPlayerMaskView *)playerMaskView didGetBack:(UIButton *)backButton {
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.mIsFlip) {
        [self forceOrientationLandscape:NO];
    } else{
        [self.mPlayerView.controlHandler stop];
        [self.mDurationTimer invalidate];
        self.mDurationTimer = nil;
        
        self.mMaskView = nil;
        // 更新日志
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)playerMaskView:(QNPlayerMaskView *)playerMaskView isLandscape:(BOOL)isLandscape {
    [self forceOrientationLandscape:isLandscape];

}

-(void)reOpenPlayPlayerMaskView:(QNPlayerMaskView *)playerMaskView{
    QMediaModel *model = self.mPlayerModels[self.mSelectedIndex];
    [self.mPlayerView.controlHandler playMediaModel:model startPos:[[QDataHandle shareInstance] getConfiguraPostion]];
    [self.mMaskView setPlayButtonState:YES];

}
- (BOOL)shouldAutorotate

{

    return NO;

}

- (void)forceOrientationLandscape:(BOOL)isLandscape {
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.mIsFlip = isLandscape;
    if ([UIDevice currentDevice].orientation == UIDeviceOrientationUnknown) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [appDelegate application:[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:self.view.window];
    
    self.mIsFlip = appDelegate.mIsFlip;
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
            [self.mUrlListTableView removeFromSuperview];
            self.mPlayerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
            self.mMaskView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
            self.mToastView.frame = CGRectMake(40, scene.screen.bounds.size.width-220, 200, 150);
        }else{
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [self.view addSubview:self.mUrlListTableView];
            self.mPlayerView.frame = CGRectMake(0, self.mTopSpace, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.height*9/16);
            self.mMaskView.frame = CGRectMake(0, self.mTopSpace, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.height*9/16);
            
            self.mToastView.frame = CGRectMake(0, scene.screen.bounds.size.width-300, 200, 300);
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
            [self.mUrlListTableView removeFromSuperview];
            self.mPlayerView.frame = CGRectMake(0, 0, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT);
            self.mMaskView.frame = CGRectMake(0, 0, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT);
            self.mToastView.frame = CGRectMake(40, PL_SCREEN_HEIGHT-220, 200, 150);
        } else {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
            [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
            [self.view addSubview:self.mUrlListTableView];
            self.mPlayerView.frame = CGRectMake(0, self.mTopSpace, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT);
            self.mMaskView.frame = CGRectMake(0, self.mTopSpace, PLAYER_PORTRAIT_WIDTH, PLAYER_PORTRAIT_HEIGHT);
            self.mToastView.frame = CGRectMake(0, PL_SCREEN_HEIGHT-300, 200, 300);
        }
        
    }
//    [UIViewController attemptRotationToDeviceOrientation];
    
}

#pragma mark - 创建  urlListTableView

- (void)layoutUrlListTableView
{
    self.mIsPull = YES;
    
    self.mUrlListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.mTopSpace + PLAYER_PORTRAIT_HEIGHT, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT - self.mTopSpace - PLAYER_PORTRAIT_HEIGHT) style:UITableViewStylePlain];
    self.mUrlListTableView.delegate = self;
    self.mUrlListTableView.dataSource = self;
    self.mUrlListTableView.sectionHeaderHeight = 36;
    [self.mUrlListTableView registerClass:[QNURLListTableViewCell class] forCellReuseIdentifier:@"listCell"];
    self.mUrlListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.mTitleArray = @[@"status - PLPlayer 的播放状态 :",@"firstVideoTime - 首开时间 :",@"renderFPS - 播放渲染帧率 :",@"downSpeed - 下载速率(kb/s) :"];
    
        NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:self.mTitleArray];
        [mutableArray addObjectsFromArray:@[@"bufferPostion - 缓存大小 :"]];
        self.mTitleArray = [mutableArray copy];
    self.mInfoHeaderView = [[QNInfoHeaderView alloc] initWithTopMargin:0 titleArray:self.mTitleArray infoArray:[self updateInfoArray]];
    
    self.mUrlListTableView.tableHeaderView = self.mInfoHeaderView;
    [self.view addSubview:self.mUrlListTableView];
}


#pragma mark - PLPlayerSettingsVcDelegate

- (void)didCompleteConfiguration:(NSArray<QNClassModel *> *)configs {
    [self setUpPlayer:configs];
}

- (void)configurePlayerWithConfigureModel:(PLConfigureModel *)configureModel classModel:(QNClassModel *)classModel {
    NSInteger index = [configureModel.mSelectedNum integerValue];
    
    if ([classModel.classKey isEqualToString:@"PLPlayerOption"]) {
        if ([configureModel.mConfiguraKey containsString:@"播放速度"]) {
            [self.mPlayerView.controlHandler setSpeed:[configureModel.mConfiguraValue[index] floatValue]];
        }

        if ([configureModel.mConfiguraKey containsString:@"播放起始"]){

        } else if ([configureModel.mConfiguraKey containsString:@"Decoder"]) {
            [self.mPlayerView.controlHandler setDecoderType:(QPlayerDecoder)index];
        } else if ([configureModel.mConfiguraKey containsString:@"Seek"]) {
            [self.mPlayerView.controlHandler  setSeekMode:index];

        } else if ([configureModel.mConfiguraKey containsString:@"Start Action"]) {
            [self.mPlayerView.controlHandler setStartAction:(QPlayerStart)index];
            
        } else if ([configureModel.mConfiguraKey containsString:@"Render ratio"]) {
            [self.mPlayerView.renderHandler setRenderRatio:(QPlayerRenderRatio)(index + 1)];
            
        } else if ([configureModel.mConfiguraKey containsString:@"色盲模式"]) {
            [self.mPlayerView.renderHandler setBlindType:(QPlayerBlind)index];
        }
        else if ([configureModel.mConfiguraKey containsString:@"SEI"]) {
            if (index == 0) {
                
                [self.mPlayerView.controlHandler setSEIEnable:YES];
            }else{
                [self.mPlayerView.controlHandler setSEIEnable:NO];
            }
        }
        else if ([configureModel.mConfiguraKey containsString:@"鉴权"]) {
            if (index == 0) {
                [self.mPlayerView.controlHandler forceAuthenticationFromNetwork];
            }
        }
        else if ([configureModel.mConfiguraKey containsString:@"后台播放"]){
            if (index == 0) {
                [self.mPlayerView.controlHandler setBackgroundPlayEnable:YES];
            }
            else{
                [self.mPlayerView.controlHandler setBackgroundPlayEnable:NO];
            }
        }
        else if ([configureModel.mConfiguraKey containsString:@"清晰度切换"]){
            self.mImmediatelyType =(int)index;
        }
        else if ([configureModel.mConfiguraKey containsString:@"video 回调数据类型"]){
            [self.mPlayerView.controlHandler setVideoDataType:(QVideoType)(index+1)];
        }
        else if ([configureModel.mConfiguraKey containsString:@"字幕"]){
            [self.mPlayerView.controlHandler setSubtitleEnable:index==0?NO:YES];
            if(index == 1 ){
                if(![self.mPlayerView.controlHandler.subtitleName isEqual:@"中文"]){
                    [self.mPlayerView.controlHandler setSubtitle:@"中文"];
                }
            }
            else if (index == 2){
                if(![self.mPlayerView.controlHandler.subtitleName isEqual:@"英文"]){
                    [self.mPlayerView.controlHandler setSubtitle:@"英文"];
                }
            }
        }
    }
}

#pragma mark - PLScanViewControlerDelegate 代理方法

- (void)scanQRResult:(NSString *)qrString isLive:(BOOL)isLive{

    if (!isLive) {
        [self.mPlayerView.controlHandler resumeRender];
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
        [self.mPlayerModels addObject:model];
        self.mSelectedIndex = self.mPlayerModels.count - 1;
        [self tableView:self.mUrlListTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:self.mSelectedIndex inSection:0]];

        [self.mUrlListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.mSelectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        [self.urlListTableView reloadData];

    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"scan url error" message:qrString delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - 扫码二维码

- (void)scanCodeAction:(UIButton *)scanButton {
    
    if (self.mPlayerView.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING) {
        [self.mPlayerView.controlHandler pauseRender];
    }
    self.mScanClick = YES;
    QNScanViewController *scanViewController = [[QNScanViewController alloc] init];
    scanViewController.delegate = self;
    [self.navigationController pushViewController:scanViewController animated:YES];
}



- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView 代理方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mPlayerModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QNURLListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"listCell" forIndexPath:indexPath];
    if([self.mPlayerModels[indexPath.row].streamElements[0].url isEqual:@"rtmp://pili-live-rtmp.test.qnsdk.com/sdk-live-test/test6666"]){
        [cell configureListURLString:self.mPlayerModels[indexPath.row].streamElements[1].url index:indexPath.row];
        
    }else{
        [cell configureListURLString:self.mPlayerModels[indexPath.row].streamElements[0].url index:indexPath.row];
    }
    cell.mDeleteButton.tag = 100 + indexPath.row;
    [cell.mDeleteButton addTarget:self action:@selector(deleteUrlString:) forControlEvents:UIControlEventTouchDown];
    if (indexPath.row == self.mSelectedIndex) {
        cell.mUrlLabel.textColor = PL_SELECTED_BLUE;
        cell.mUrlLabel.font = PL_FONT_MEDIUM(14);
    } else {
        cell.mUrlLabel.textColor = [UIColor blackColor];
        cell.mUrlLabel.font = PL_FONT_LIGHT(13);
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [QNURLListTableViewCell configureListCellHeightWithURLString:self.mPlayerModels[indexPath.row].streamElements[0].url index:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *selectedURL = [NSURL URLWithString:self.mPlayerModels[indexPath.row].streamElements[0].url];
    if (self.mPlayerView.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING) {
        [self.mPlayerView.controlHandler pauseRender];
    }
    
    self.mSelectedIndex = indexPath.row;
    [self.mUrlListTableView reloadData];
    
    QMediaModel *model = self.mPlayerModels[indexPath.row];
    self.mMaskView.mIsLiving = model.isLive;
    if(model.streamElements.count > 1){
        [self.mMaskView.mQualitySegMc removeAllSegments];
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
                
                self.mMaskView.mQualitySegMc.hidden = YES;
            }else{
                
                [self.mMaskView.mQualitySegMc insertSegmentWithTitle:[NSString stringWithFormat:@"%dp",modle0.quality] atIndex:index animated:NO];
                index++;
            }
        }
        self.mMaskView.mQualitySegMc.selectedSegmentIndex = indexSel;
    }else{
        [self.mMaskView.mQualitySegMc removeAllSegments];
        self.mMaskView.mQualitySegMc.hidden = YES;
    }
    
    if ([[QDataHandle shareInstance] getAuthenticationState]) {
        [self.mPlayerView.controlHandler forceAuthenticationFromNetwork];
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
    [self.mPlayerView.controlHandler playMediaModel:model startPos:[[QDataHandle shareInstance] getConfiguraPostion]];
    [self.mMaskView setPlayButtonState:NO];
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
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"删除播放地址" message:[NSString stringWithFormat:@"亲，是否确定要删除播放地址：%@ ？", self.mPlayerModels[index]] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
    }];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.mPlayerModels removeObjectAtIndex:index];
        if(index == self.mSelectedIndex){
            self.mSelectedIndex = 0;
            [self tableView:self.mUrlListTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:self.mSelectedIndex inSection:0]];
            [self.mUrlListTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.mSelectedIndex inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];

        }
        if (self.mPlayerModels.count != 0) {
            [self.mUrlListTableView reloadData];
        } else{
            [self.mUrlListTableView removeFromSuperview];
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
    self.mHintLabel.text = hintStr;
    if ([self.view.subviews containsObject:self.mHintLabel]) {
        [self.mHintLabel removeFromSuperview];
    }
    [self.view addSubview:self.mHintLabel];
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
        self.mSegment.selectedSegmentIndex = 1;
    } else{
        self.mSegment.selectedSegmentIndex = 0;
    }
    [self.mUrlListTableView removeFromSuperview];
    [self layoutUrlListTableView];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)qualityAction:(UISegmentedControl *)segm{
    NSInteger index = segm.selectedSegmentIndex;
    QMediaModel *model = self.mPlayerModels[self.mSelectedIndex];
    
    int tempIndex = 0;
    for (QStreamElement* modle0 in model.streamElements) {
        modle0.isSelected = NO;
        
        if (index == tempIndex) {
            modle0.isSelected = YES;
        }
        tempIndex ++;
    }
    BOOL switchQualityBool;
    if(self.mImmediatelyType == 0){
        
        switchQualityBool = [self.mPlayerView.controlHandler switchQuality:model.streamElements[index].userType urlType:model.streamElements[index].urlType quality:model.streamElements[index].quality immediately:true];
    }else if(self.mImmediatelyType == 1){
        
        switchQualityBool = [self.mPlayerView.controlHandler switchQuality:model.streamElements[index].userType urlType:model.streamElements[index].urlType quality:model.streamElements[index].quality immediately:false];
    }
    else{
        switchQualityBool = [self.mPlayerView.controlHandler switchQuality:model.streamElements[index].userType urlType:model.streamElements[index].urlType quality:model.streamElements[index].quality immediately:model.isLive];
    }
    if (!switchQualityBool) {
        self.mMaskView.mQualitySegMc.selectedSegmentIndex = self.mUpQualityIndex;

        [self.mToastView addText:@"不可重复切换"];
    }else{
        self.mUpQualityIndex = index;
        
        [self.mToastView addText:[NSString stringWithFormat:@"即将切换为：%d p",model.streamElements[index].quality]];
    }
}




@end
