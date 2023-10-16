//
//  QNPlayerMaskView.m
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/9/28.
//  Copyright © 2017年 qiniu. All rights reserved.
//

#import "QNPlayerMaskView.h"
#import "QNAppDelegate.h"
#import "QDataHandle.h"
#import "QNButtonView.h"
#import <CoreMotion/CoreMotion.h>

@interface QNPlayerMaskView ()
<
UIGestureRecognizerDelegate,
QIPlayerQualityListener,
QIPlayerAuthenticationListener,
QIPlayerSubtitleListener
>

@property (nonatomic, strong) QNButtonView *mButtonView;

@property (nonatomic, strong) UIButton *mBackButton;


@property (strong, nonatomic) UIActivityIndicatorView *mActivityIndicatorView;

@property (nonatomic, strong) UIView *mFastView;
@property (nonatomic, strong) UIProgressView *mFastProgressView;
@property (nonatomic, strong) UILabel *mFastTimeLabel;
@property (nonatomic, strong) UIImageView *mFastImageView;
@property (nonatomic)BOOL mIsScreenFull;
/** 陀螺仪**/
@property (nonatomic, strong)CMMotionManager *mMotionManager;

/** 计时器获取陀螺仪参数**/
@property (nonatomic, strong)NSTimer *mMotionTimer;
/** 陀螺仪参数**/
@property (nonatomic)float mMotionRoll;
/** 陀螺仪参数**/
@property (nonatomic)float mMotionPitch;
/** 手势参数**/
@property (nonatomic)float mRotateX;
/** 手势参数**/
@property (nonatomic)float mRotateY;
/** 手势参数**/
@property (nonatomic)BOOL mIsRotate;

@property (nonatomic, assign) float mCurrentTime;

/** 单击 **/
@property (nonatomic, strong) UITapGestureRecognizer *mSingleTap;
/** 双击 **/
@property (nonatomic, strong) UITapGestureRecognizer *mDoubleTap;

/** 设置悬浮窗 **/
@property (nonatomic, strong) UIButton *mShowSettingViewButton;
@property (nonatomic, strong) QNPlayerSettingsView *mSettingView;

/** 设置倍速悬浮窗 **/
@property (nonatomic, strong) UIButton *mShowSpeedViewButton;
@property (nonatomic, strong) QNPlayerSettingsView *mSettingSpeedView;


/** 截图按钮 **/
@property (nonatomic, strong) UIButton *mShootVideoButton;

/** 推流按钮 **/
@property (nonatomic, strong) UIButton *mPushStreamButton;

@property (nonatomic, assign) QPlayerDecoder mDecoderType;
@property (nonatomic, assign) BOOL mSeeking;

@property (nonatomic, assign) BOOL mSubtitleEnable;
@end

@implementation QNPlayerMaskView

#pragma mark - basic

- (id)initWithFrame:(CGRect)frame player:(QPlayerView *)player isLiving:(BOOL)isLiving{
    if (self = [super initWithFrame:frame]) {
        self.mPlayer = player;
        self.mSubtitleEnable = false;
        [self.mPlayer.controlHandler addPlayerQualityListener:self];
        [self.mPlayer.controlHandler addPlayerAuthenticationListener:self];
        [self.mPlayer.controlHandler addPlayerSubtitleListener:self];
        self.mIsLiving = isLiving;
        self.mMotionPitch = 0;
        self.mMotionRoll = 0;
        self.mRotateX = 0;
        self.mRotateY = 0;
        self.mIsRotate = false;
//        self.myRenderView = view;
        CGFloat playerWidth = CGRectGetWidth(frame);
        CGFloat playerHeight = CGRectGetHeight(frame);
        
        self.mButtonView = [[QNButtonView alloc]initWithFrame:CGRectMake(8, playerHeight - 28, playerWidth - 16, 28) player:player playerFrame:frame isLiving:isLiving];
        
        [self addSubview:_mButtonView];
        __weak typeof(self) weakSelf = self;
        [self.mButtonView playButtonClickCallBack:^(BOOL selectedState) {
            if(weakSelf.mPlayer.controlHandler.currentPlayerState == QPLAYER_STATE_COMPLETED){
                if (weakSelf.mDelegate != nil && [weakSelf.mDelegate respondsToSelector:@selector(reOpenPlayPlayerMaskView:)]) {
                    [weakSelf.mDelegate reOpenPlayPlayerMaskView:weakSelf];
                }
            }
        }];
        
        [self.mButtonView changeScreenSizeButtonClickCallBack:^(BOOL selectedState) {
            if (weakSelf.mDelegate != nil && [weakSelf.mDelegate respondsToSelector:@selector(playerMaskView:isLandscape:)]) {
                [weakSelf.mDelegate playerMaskView:weakSelf isLandscape:selectedState];
            }
            [weakSelf changeFrame:weakSelf.frame isFull:selectedState];
        }];
        [self.mButtonView sliderStartCallBack:^(BOOL seeking) {
            weakSelf.mSeeking = seeking;
        }];
        [self.mButtonView sliderEndCallBack:^(BOOL seeking) {
            weakSelf.mSeeking = seeking;
        }];
        // 音量调整/快进快退
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [self addGestureRecognizer:pan];
        
        if (!isLiving) {
            [self layoutFastView];
            self.mFastView.hidden = YES;
        }
        
        CGFloat ratio = [self receiveComparison];
        // 声音控件

        
        self.mBackButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 6, 44, 44)];
        [self.mBackButton setImage:[UIImage imageNamed:@"pl_back"] forState:UIControlStateNormal];
        [self.mBackButton addTarget:self action:@selector(getBackAction:) forControlEvents:UIControlEventTouchDown];
        self.mBackButton.accessibilityIdentifier = @"longVideoBack";
        [self addSubview:_mBackButton];
        
        
        NSArray *segmentedArray = [[NSArray alloc]initWithObjects:@"1080p",@"720p",@"480p",@"360p",nil];

        self.mQualitySegMc = [[UISegmentedControl alloc]initWithItems:segmentedArray];

        self.mQualitySegMc.frame = CGRectMake(playerWidth - 250, 17, 250, 28);

        self.mQualitySegMc.selectedSegmentIndex = 0;//设置默认选择项索引
        self.mQualitySegMc.tintColor = [UIColor grayColor];
        [self addSubview:_mQualitySegMc];
        

        self.mShootVideoButton = [[UIButton alloc]initWithFrame:CGRectMake(PL_SCREEN_WIDTH-60, PL_SCREEN_HEIGHT/2-20, 40, 40)];
        [self.mShootVideoButton addTarget:self action:@selector(shootVideoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [self.mShootVideoButton setImage:[[UIImage imageNamed:@"shootVideo"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.mShootVideoButton.tintColor = [UIColor whiteColor];
        self.mShootVideoButton.hidden = YES;
        [self addSubview:self.mShootVideoButton];
        
        self.mPushStreamButton = [[UIButton alloc]initWithFrame:CGRectMake(PL_SCREEN_WIDTH-60, PL_SCREEN_HEIGHT/2-80, 40, 40)];
        [self.mPushStreamButton addTarget:self action:@selector(pushStreamButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [self.mPushStreamButton setImage:[[UIImage imageNamed:@"pl_pushStream"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        
        [self.mPushStreamButton setImage:[UIImage imageNamed:@"pl_stopStream"] forState:UIControlStateSelected];
        self.mPushStreamButton.tintColor = [UIColor whiteColor];
        self.mPushStreamButton.hidden = YES;
//        [self addSubview:self.pushStreamButton];
        
        [self createGesture];
        
        [self hideInterfaceView];
        
//        [[QNHeadsetNotification alloc]addNotificationsPlayer:player];

        // 展示转码的动画
        self.mActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(playerWidth/2 - 20, playerHeight/2 - 20, 40, 40)];
        [self.mActivityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        //设置悬浮框
        _mShowSettingViewButton = [[UIButton alloc] initWithFrame:CGRectMake(playerWidth, 7, 35, 30)];
        _mShowSettingViewButton.backgroundColor = [UIColor clearColor];
        [_mShowSettingViewButton setImage:[UIImage imageNamed:@"icon-more"] forState:UIControlStateNormal];
        _mShowSettingViewButton.contentMode = UIViewContentModeScaleAspectFit;
        [_mShowSettingViewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_mShowSettingViewButton addTarget:self action:@selector(ShowSettingViewButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _mShowSettingViewButton.hidden = YES;
        [self addSubview:_mShowSettingViewButton];
        _mSettingView = [[QNPlayerSettingsView alloc]initChangePlayerViewCallBack:^(ChangeButtonType type, NSString * _Nonnull startPosition,BOOL selected) {
            if (type < 5) {
                [weakSelf.mPlayer.renderHandler setRenderRatio:(QPlayerRenderRatio)(type + 1)];
                
                [[QDataHandle shareInstance] setSelConfiguraKey:@"Render ratio" selIndex:(int)type];
            }else if(type < 104){
                [weakSelf.mPlayer.renderHandler setBlindType:(QPlayerBlind)(type - 100)];
                [[QDataHandle shareInstance] setSelConfiguraKey:@"色盲模式" selIndex:(int)(type - 100)];
            }else if(type < 204){
                
                weakSelf.mDecoderType = (QPlayerDecoder)(type - 200);
                [weakSelf.mPlayer.controlHandler setDecoderType:(QPlayerDecoder)(type - 200)];;
                [[QDataHandle shareInstance] setSelConfiguraKey:@"Decoder" selIndex:(int)(type - 200)];
            }else if(type < 302 ){
                [weakSelf.mPlayer.controlHandler  setSeekMode:(QPlayerSeek)(type-300)];
                [[QDataHandle shareInstance] setSelConfiguraKey:@"Seek" selIndex:(int)(type-300)];
            }else if(type < 402){
                [weakSelf.mPlayer.controlHandler setStartAction:(QPlayerStart)(type-400)];;;
                
                [[QDataHandle shareInstance] setSelConfiguraKey:@"Start Action" selIndex:(int)(type-400)];
            }
            else if(type == 500){
                [weakSelf.mPlayer.controlHandler setSEIEnable: selected];
                if (selected) {
                    
                    [[QDataHandle shareInstance] setSelConfiguraKey:@"SEI" selIndex:0];
                }else{
                    
                    [[QDataHandle shareInstance] setSelConfiguraKey:@"SEI" selIndex:1];
                }
            }
            else if(type == 600){
                if (selected) {
                    [weakSelf.mPlayer.controlHandler forceAuthenticationFromNetwork];
                    [[QDataHandle shareInstance] setSelConfiguraKey:@"鉴权" selIndex:0];
                }else{
                    
                    [[QDataHandle shareInstance] setSelConfiguraKey:@"鉴权" selIndex:1];
                }
            }
            else if (type == 700){
                [weakSelf.mPlayer.controlHandler setBackgroundPlayEnable:selected];
                if (selected) {
                    [[QDataHandle shareInstance] setSelConfiguraKey:@"后台播放" selIndex:0];
                }
                else{
                    [[QDataHandle shareInstance] setSelConfiguraKey:@"后台播放" selIndex:1];
                }
            }
            
            else if (800 <= type && type <= 802){
                if(weakSelf.mDelegate != nil && [weakSelf.mDelegate respondsToSelector:@selector(setImmediately:)]){
                    [weakSelf.mDelegate setImmediately:(int)(type-800)];
                }
                [[QDataHandle shareInstance] setSelConfiguraKey:@"清晰度切换" selIndex:(int)(type-800)];
                
            }else if (900 <= type && type <= 902){
                if(type == 900){
                    [weakSelf.mPlayer.controlHandler setSubtitleEnable:NO];
                }else{
                    [weakSelf.mPlayer.controlHandler setSubtitleEnable:YES];
                }
                if(type == 901){
                    [weakSelf.mPlayer.controlHandler setSubtitle:@"中文"];
                }else if(type == 902){
                    [weakSelf.mPlayer.controlHandler setSubtitle:@"英文"];
                }
                
                [[QDataHandle shareInstance] setSelConfiguraKey:@"字幕" selIndex:(int)(type-900)];
                
            }
            
            if (startPosition) {
                int satartPod = [startPosition intValue];
                
                [[QDataHandle shareInstance] setValueConfiguraKey:@"播放起始" selValue:satartPod];
                
            }
            
            [[QDataHandle shareInstance] saveConfigurations];
        }];
        _mSettingView.hidden = YES;
        [self addSubview:_mSettingView];
        
        _mShowSpeedViewButton = [[UIButton alloc] initWithFrame:CGRectMake(playerWidth, 7, 30, 30)];
        _mShowSpeedViewButton.backgroundColor = [UIColor clearColor];
        [_mShowSpeedViewButton setTitle:@"倍速" forState:UIControlStateNormal];
//        [_showSpeedViewButton setFont:[UIFont systemFontOfSize:12.0f]];
        _mShowSpeedViewButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_mShowSpeedViewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_mShowSpeedViewButton addTarget:self action:@selector(ShowSpeedViewButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        _mShowSpeedViewButton.hidden = YES;
        [self addSubview:_mShowSpeedViewButton];
        _mSettingSpeedView = [[QNPlayerSettingsView alloc]initSpeedViewCallBack:^(SpeedUIButtonType type) {
            float speed = 1.0;
            switch (type) {
                case BUTTON_TYPE_PLAY_SPEED_2_0:
                    speed = 2.0;
                    break;
                case BUTTON_TYPE_PLAY_SPEED_1_5:
                    speed = 1.5;
                    break;
                case BUTTON_TYPE_PLAY_SPEED_1_25:
                    speed = 1.25;
                    break;
                case BUTTON_TYPE_PLAY_SPEED_1_0:
                    speed = 1.0;
                    break;
                case BUTTON_TYPE_PLAY_SPEED_0_75:
                    speed = 0.75;
                    break;
                case BUTTON_TYPE_PLAY_SPEED_0_5:
                    speed = 0.5;
                    break;
                default:
                    break;
            }
            
            [weakSelf.mPlayer.controlHandler setSpeed:speed];
            [[QDataHandle shareInstance] setSelConfiguraKey:@"播放速度" selIndex:(int)(type)];
            
            [[QDataHandle shareInstance] saveConfigurations];
            
        }];
        _mSettingSpeedView.hidden = YES;
        [self addSubview:_mSettingSpeedView];
        
        
        // default UI
        for (QNClassModel* model in [QDataHandle shareInstance].mPlayerConfigArray) {
            for (PLConfigureModel* configModel in model.classValue) {
                if ([model.classKey isEqualToString:@"PLPlayerOption"]) {
                    [self configurePlayerWithConfigureModel:configModel classModel:model];;
                }
            }
        }
    }
    return self;
}





- (void)configurePlayerWithConfigureModel:(PLConfigureModel *)configureModel classModel:(QNClassModel *)classModel {
    NSInteger index = [configureModel.mSelectedNum integerValue];
    
    if ([classModel.classKey isEqualToString:@"PLPlayerOption"]) {
        if ([configureModel.mConfiguraKey containsString:@"播放速度"]) {
            [_mSettingSpeedView setSpeedDefault:(SpeedUIButtonType)index];
        }

        if ([configureModel.mConfiguraKey containsString:@"播放起始"]){
//            self.startPos = [configureModel.configuraValue[0] intValue];
            [_mSettingView setPostioTittle:[configureModel.mConfiguraValue[0] intValue]];

        } else if ([configureModel.mConfiguraKey containsString:@"Decoder"]) {
            self.mDecoderType = (QPlayerDecoder)index;
            [_mSettingView setChangeDefault:(ChangeButtonType)(index + 200)];
            
        } else if ([configureModel.mConfiguraKey containsString:@"Seek"]) {
            [_mSettingView setChangeDefault:(ChangeButtonType)(index + 300)];

        } else if ([configureModel.mConfiguraKey containsString:@"Start Action"]) {
            [_mSettingView setChangeDefault:(ChangeButtonType)(index + 400)];
            
        } else if ([configureModel.mConfiguraKey containsString:@"Render ratio"]) {
            [_mSettingView setChangeDefault:(ChangeButtonType)(index)];
            
        } else if ([configureModel.mConfiguraKey containsString:@"色盲模式"]) {
            [_mSettingView setChangeDefault:(ChangeButtonType)(index + 100)];
        }//默认开启
        else if ([configureModel.mConfiguraKey containsString:@"SEI"]) {
            if (index == 0) {
                
                [_mSettingView setChangeDefault:BUTTON_TYPE_SEI_DATA];
            }
            else{
                
            }
        }//默认开启
        else if ([configureModel.mConfiguraKey containsString:@"鉴权"]) {
            if (index == 0) {
                
                [_mSettingView setChangeDefault:BUTTON_TYPE_AUTHENTICATION];
            }
            else{
                
            }
       }
        else if ([configureModel.mConfiguraKey containsString:@"后台播放"]){
            if (index == 0) {
                [_mSettingView setChangeDefault:BUTTON_TYPE_BACKGROUND_PLAY];
            }else{
                
            }
        }else if ([configureModel.mConfiguraKey containsString:@"清晰度切换"]) {
            [_mSettingView setChangeDefault:(ChangeButtonType)(index+800)];
            
        }else if ([configureModel.mConfiguraKey containsString:@"字幕"]) {
            [_mSettingView setChangeDefault:(ChangeButtonType)(index+900)];
            
        }
        
    }
}

///**
// *  创建手势
// */
- (void)createGesture {
    // 单击 - 操作视图出现/消失
    self.mSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAction)];
    self.mSingleTap.delegate                = self;
    self.mSingleTap.numberOfTouchesRequired = 1; //手指数
    self.mSingleTap.numberOfTapsRequired    = 1;
    [self addGestureRecognizer:self.mSingleTap];

    // 双击(播放/暂停)
    self.mDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
    self.mDoubleTap.delegate                = self;
    self.mDoubleTap.numberOfTouchesRequired = 1; //手指数
    self.mDoubleTap.numberOfTapsRequired    = 2;
    [self addGestureRecognizer:self.mDoubleTap];

    // 解决点击当前view时候响应其他控件事件
    [self.mSingleTap setDelaysTouchesBegan:YES];
    [self.mDoubleTap setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [self.mSingleTap requireGestureRecognizerToFail:self.mDoubleTap];
}

- (void)layoutFastView {
    [self addSubview:self.mFastView];
    [self.mFastView addSubview:self.mFastImageView];
    [self.mFastView addSubview:self.mFastTimeLabel];
    [self.mFastView addSubview:self.mFastProgressView];
    
    [self.mFastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(125);
        make.height.mas_equalTo(80);
        make.center.equalTo(self);
    }];
    
    [self.mFastImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_offset(32);
        make.height.mas_offset(32);
        make.top.mas_equalTo(5);
        make.centerX.mas_equalTo(self.mFastView.mas_centerX);
    }];
    
    [self.mFastTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.with.trailing.mas_equalTo(0);
        make.top.mas_equalTo(self.mFastImageView.mas_bottom).offset(2);
    }];
    
    [self.mFastProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(12);
        make.trailing.mas_equalTo(-12);
        make.top.mas_equalTo(self.mFastTimeLabel.mas_bottom).offset(10);
    }];
}

- (CGFloat)receiveComparison {
    if (PL_SCREEN_WIDTH == 375) {
        return 1.18;
    }
    else if (PL_SCREEN_WIDTH == 414) {
        return 1.30;
    }
    return 1.0;
}

- (void)dealloc{
    NSLog(@"QNPlayerMaskView dealloc");
    _mDelegate = nil;
}

#pragma mark - setter

- (void)setMCurrentTime:(float)currentTime
{
//    CMTime newTime = self.player.currentTime;
//    newTime.value = newTime.timescale * currentTime;
    [self.mPlayer.controlHandler seek:currentTime*1000];
}


- (void)setMPlayer:(QPlayerContext *)player {
    self.mButtonView.mPlayer = player;
    _mPlayer = player;
}
#pragma mark - playerListenerDelegate

-(void)onQualitySwitchRetryLater:(QPlayerContext *)context usertype:(NSString *)usertype urlType:(QPlayerURLType)urlType{

    NSInteger nums = self.mQualitySegMc.numberOfSegments;
    for (int i = 0; i < nums; i++) {
        if ([[self.mQualitySegMc titleForSegmentAtIndex:i] isEqual:[NSString stringWithFormat:@"%ld%@",(long)[self.mPlayer.controlHandler getSwitchingQuality:usertype urlType:urlType],@"p"]]) {
            self.mQualitySegMc.selectedSegmentIndex = i;
            break;
        }
    }
}

-(void)onAuthenticationFailed:(QPlayerContext *)context error:(QPlayerAuthenticationErrorType)error{
    if (error == QPLAYER_AUTHENTICATION_ERROR_TYPE_AET_NO_BLIND_AUTH) {
        [_mSettingView setChangeDefault:BUTTON_TYPE_FILTER_NONE];
    }
}

- (void)onSubtitleEnable:(QPlayerContext *)context enable:(BOOL)enable{
    if (enable == false) {
        [self.mSettingView setChangeDefault:BUTTON_TYPE_SUBTITLE_CLOSE];
    }
    self.mSubtitleEnable = enable;
}
- (void)onSubtitleNameChange:(QPlayerContext *)context name:(NSString *)name{
    if(self.mSubtitleEnable == false){
        return;
    }
    if ([name isEqual: @"中文"]) {
        [self.mSettingView setChangeDefault:BUTTON_TYPE_SUBTITLE_CHINESE];
    }else if([name isEqual:@"英文"]){
        [self.mSettingView setChangeDefault:BUTTON_TYPE_SUBTITLE_ENGLISH];
    }
}

#pragma mark - getter

- (float)mCurrentTime
{
    return self.mPlayer.controlHandler.currentPosition/1000;
}

- (UIView *)mFastView {
    if (!_mFastView) {
        _mFastView = [[UIView alloc] init];
        _mFastView.backgroundColor = PL_COLOR_RGB(0, 0, 0, 0.8);
        _mFastView.layer.cornerRadius = 4;
        _mFastView.layer.masksToBounds = YES;
    }
    return _mFastView;
}

- (UIImageView *)mFastImageView {
    if (!_mFastImageView) {
        _mFastImageView = [[UIImageView alloc] init];
    }
    return _mFastImageView;
}

- (UILabel *)mFastTimeLabel {
    if (!_mFastTimeLabel) {
        _mFastTimeLabel               = [[UILabel alloc] init];
        _mFastTimeLabel.textColor     = [UIColor whiteColor];
        _mFastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _mFastTimeLabel.font          = [UIFont systemFontOfSize:14.0];
    }
    return _mFastTimeLabel;
}

- (UIProgressView *)mFastProgressView {
    if (!_mFastProgressView) {
        _mFastProgressView                   = [[UIProgressView alloc] init];
        _mFastProgressView.progressTintColor = [UIColor whiteColor];
        _mFastProgressView.trackTintColor    = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    }
    return _mFastProgressView;
}


#pragma mark - public methods
/**
 开启陀螺仪
 */
-(void)gyroscopeStart{
    if(self.mMotionManager != nil){

    }
    else{
        self.mMotionManager = [[CMMotionManager alloc]init];
        [self.mMotionManager setDeviceMotionUpdateInterval:0.1];
        [self.mMotionManager startDeviceMotionUpdates];
        __weak typeof(self) weakSelf = self;
        self.mMotionTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 repeats:YES block:^(NSTimer * _Nonnull timer) {
//            *180/M_PI
            if(!weakSelf.mIsRotate){
                //pitch = 90度 表示手机短边在下竖直正立放置  roll = 90度时 长边在下竖直屏幕朝右放置  roll = 0 pitch = 0 时屏幕朝上水平放置
                float pitch = weakSelf.mMotionManager.deviceMotion.attitude.pitch*180/M_PI-weakSelf.mMotionPitch;
                float roll = weakSelf.mMotionManager.deviceMotion.attitude.roll*180/M_PI-weakSelf.mMotionRoll;
                if(weakSelf.mIsScreenFull){
                    
                    weakSelf.mRotateX += roll;
                    weakSelf.mRotateY -= pitch;
                }else{
                    
                    weakSelf.mRotateX += pitch;
                    weakSelf.mRotateY += roll;
                }
                [weakSelf.mPlayer.renderHandler setPanoramaViewRotate:weakSelf.mRotateX rotateY:weakSelf.mRotateY];
                
            }
            
            weakSelf.mMotionRoll = weakSelf.mMotionManager.deviceMotion.attitude.roll*180/M_PI;
            
            weakSelf.mMotionPitch = weakSelf.mMotionManager.deviceMotion.attitude.pitch*180/M_PI;
        }];
    }

}
/**
 关闭陀螺仪
 */
-(void)gyroscopeEnd{
    if(self.mMotionManager != nil){

        self.mMotionManager = nil;
        [self.mMotionTimer invalidate];
        self.mMotionTimer = nil;
    }
}
// 加载视频转码的动画
- (void)loadActivityIndicatorView {

    if(!self.mActivityIndicatorView.isAnimating){
        [self addSubview:self.mActivityIndicatorView];
        [self.mActivityIndicatorView startAnimating];
    }
}

// 移除视频转码的动画
- (void)removeActivityIndicatorView {
    if ([self.mActivityIndicatorView isAnimating]) {
        [self.mActivityIndicatorView removeFromSuperview];
        [self.mActivityIndicatorView stopAnimating];
    }
}
-(void)setPlayButtonState:(BOOL)state{
    [self.mButtonView setPlayButtonState:state];
}


-(QPlayerDecoder)getDecoderType{
    return self.mDecoderType;
}
#pragma mark - private methods

-(void)setMIsLiving:(BOOL)isLiving{
    self.mButtonView.mIsLiving = isLiving;
}
// 触摸消失
- (void)showAction
{
    self.mButtonView.hidden = !self.mButtonView.hidden;
    if(self.mIsScreenFull){
        
        self.mShowSettingViewButton.hidden = self.mButtonView.hidden;
        self.mShowSpeedViewButton.hidden = self.mButtonView.hidden;
        self.mShootVideoButton.hidden = self.mButtonView.hidden;
        self.mPushStreamButton.hidden = self.mButtonView.hidden;
    }else{
        
        self.mShowSettingViewButton.hidden = YES;
        self.mShowSpeedViewButton.hidden = YES;
        self.mShootVideoButton.hidden = YES;
        self.mPushStreamButton.hidden = YES;
    }
    if (self.mQualitySegMc.numberOfSegments >1) {
        self.mQualitySegMc.hidden  = !self.mQualitySegMc.hidden;
    }




    if (!self.mButtonView.hidden) {
        self.backgroundColor = PL_COLOR_RGB(0, 0, 0, 0.3);
        [self hideInterfaceView];
    } else{
        self.backgroundColor = [UIColor clearColor];
    }
    if (self.mSettingView.hidden == NO) {
        self.mSettingView.hidden = YES;
    }
    if (self.mSettingSpeedView.hidden == NO) {
        self.mSettingSpeedView.hidden = YES;
    }
    
    [self endEditing:YES];
}

/**
 *  双击播放/暂停
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)doubleTapAction:(UIGestureRecognizer *)gesture {
    if(self.mPlayer.controlHandler.currentPlayerState == QPLAYER_STATE_COMPLETED){
        if (self.mDelegate != nil && [self.mDelegate respondsToSelector:@selector(reOpenPlayPlayerMaskView:)]) {
            [self.mDelegate reOpenPlayPlayerMaskView:self];
        }
    }
    [self.mButtonView setPlayState];

}

// 出现后隔5秒消失
- (void)hideInterfaceView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:5];
    
}

- (void)dismiss
{
    if (self.mSeeking) {
        [self hideInterfaceView];
    }
    else{
        if (!_mIsLiving) {
            self.mFastView.hidden = YES;
        }
        self.mButtonView.hidden = YES;
        self.mQualitySegMc.hidden = YES;
        self.mShowSettingViewButton.hidden = YES;
        self.mShowSpeedViewButton.hidden = YES;
        self.mShootVideoButton.hidden = YES;
        self.mPushStreamButton.hidden = YES;
        self.backgroundColor = [UIColor clearColor];
    }
}


//显示设置界面
-(void)ShowSettingViewButtonClick:(UIButton *)btn{
    if (_mSettingView) {
        [self showAction];
        btn.hidden = YES;
        _mSettingView.hidden = NO;
    }
}
-(void)ShowSpeedViewButtonClick:(UIButton *)btn{
    if (self.mSettingSpeedView) {
        [self showAction];
        btn.hidden = YES;
        self.mSettingSpeedView.hidden = NO;
    }
}

/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panAction:(UIPanGestureRecognizer *)pan {
    // 根据上次和本次移动的位置，算出一个速率的point
    if(pan.state == UIGestureRecognizerStateBegan){
        self.mIsRotate = true;
    }else if(pan.state == UIGestureRecognizerStateEnded){
        self.mIsRotate = false;
    }
    
    CGPoint transPoint = [pan translationInView:self];
    [pan setTranslation:CGPointZero inView:self];
    
    self.mRotateY -= transPoint.x;
    self.mRotateX += transPoint.y;
    [self.mPlayer.renderHandler setPanoramaViewRotate:self.mRotateX rotateY:self.mRotateY];

}


- (void)changeFrame:(CGRect)frame isFull:(BOOL)isFull {
    CGFloat playerWidth = CGRectGetWidth(frame);
    CGFloat playerHeight = CGRectGetHeight(frame);

   
    self.mShowSettingViewButton.frame = CGRectMake(playerWidth - 100, 8, 35, 30);
    self.mShootVideoButton.frame = CGRectMake(playerWidth - 60, playerHeight/2-20, 40, 40);
    self.mPushStreamButton.frame = CGRectMake(playerWidth - 60, playerHeight/2-80, 40, 40);
    self.mSettingView.frame = CGRectMake(playerWidth - 390, 0, 390, playerHeight);
    self.mShowSpeedViewButton.frame = CGRectMake(playerWidth - 170, 8, 40, 30);
    self.mSettingSpeedView.frame = CGRectMake(playerWidth - 130, 0, 130, playerHeight);
    self.mIsScreenFull = isFull;
    if (isFull) {
        self.mButtonView.frame = CGRectMake(8, playerHeight - 60, playerWidth - 16, 28);
        
        [self.mButtonView changeFrame:frame isFull:isFull];
        _mShowSettingViewButton.hidden = NO;
        _mShowSpeedViewButton.hidden = NO;
        self.mShootVideoButton.hidden = NO;
        self.mPushStreamButton.hidden = NO;
        self.mSettingSpeedView.contentSize = CGSizeMake(130, frame.size.height);
        [self.mSettingSpeedView reloadInputViews];
        self.mActivityIndicatorView.center = self.mPlayer.center;
    } else{
        self.mButtonView.frame = CGRectMake(8, playerHeight - 28, playerWidth - 16, 28);
        
        [self.mButtonView changeFrame:frame isFull:isFull];
        if (self.mSettingView.hidden == NO) {
            self.mSettingView.hidden =YES;
        }
        if (self.mSettingSpeedView.hidden == NO) {
            self.mSettingSpeedView.hidden =YES;
        }
        if (self.mShowSettingViewButton.hidden == NO) {
            self.mShowSettingViewButton.hidden =YES;
        }
        if (self.mShowSpeedViewButton.hidden == NO) {
            self.mShowSpeedViewButton.hidden =YES;
        }
        _mShowSettingViewButton.hidden = YES;
        _mShowSpeedViewButton.hidden = YES;
        self.mShootVideoButton.hidden = YES;
        self.mPushStreamButton.hidden = YES;
        self.mActivityIndicatorView.frame = CGRectMake(playerWidth/2 - 20, playerHeight/2 - 20, 40, 40);
    }
    
}
-(void)shootVideoButtonClick{
    if(self.mDelegate!=nil && [self.mDelegate respondsToSelector:@selector(shootVideoButtonClick)]){
        [self.mDelegate shootVideoButtonClick];
    }
}
-(void)pushStreamButtonClick{
    self.mPushStreamButton.selected = !self.mPushStreamButton.selected;
    if(self.mDelegate!=nil && [self.mDelegate respondsToSelector:@selector(pushStreamButtonClick:)]){
        [self.mDelegate pushStreamButtonClick:self.mPushStreamButton.selected];
    }
}

#pragma mark - 返回

- (void)getBackAction:(UIButton *)backButton {

    
    if (self.mDelegate != nil && [self.mDelegate respondsToSelector:@selector(playerMaskView:didGetBack:)]) {
        [self.mDelegate playerMaskView:self didGetBack:backButton];
    }
    
    QNAppDelegate *appDelegate = (QNAppDelegate *)[UIApplication sharedApplication].delegate;
    if (!appDelegate.mIsFlip) {
        [self.mButtonView setFullButtonState:NO];
        [self changeFrame:self.frame isFull:NO];
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {

    if([touch.view isKindOfClass:[UISlider class]] || [touch.view isKindOfClass:[QNPlayerSettingsView class]] || [touch.view isKindOfClass:[QNChangePlayerView class]] || [touch.view isKindOfClass:[QNSpeedPlayerView class]] || [touch.view isKindOfClass:[UILabel class]]){
        return NO;
    } else {
        return YES;
    }
    
}



@end
