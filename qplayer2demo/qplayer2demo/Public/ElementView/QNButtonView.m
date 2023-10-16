//
//  QNBottomView.m
//  QPlayerKitDemo
//
//  Created by 王声禄 on 2022/7/15.
//  Copyright © 2022 Aaron. All rights reserved.
//

#import "QNButtonView.h"
#import "QDataHandle.h"
@interface QNButtonView()
<
QIPlayerProgressListener,
QIPlayerStateChangeListener,
QIPlayerAudioListener
>

@property (nonatomic, strong) UILabel *mTotalDurationLabel;
@property (nonatomic, strong) UILabel *mCurrentTimeLabel;
@property (nonatomic, assign) long long mTotalDuration;
@property (nonatomic, strong) UIButton *mFullScreenButton;
@property (nonatomic, strong) UISlider *mPrograssSlider;
@property (nonatomic, assign) BOOL mIsSeeking;
@property (nonatomic, assign) BOOL mIsNeedUpdatePrograss;


@property (nonatomic, strong) UIButton *mPlayButton;
@property (nonatomic, strong) UIButton *mStopButton;
@property (nonatomic, strong) UIButton *mMuteButton;
@property (nonatomic, assign) BOOL mShortVideoBool;
@property (nonatomic, assign) BOOL mIsBuffingBool;
@end
@implementation QNButtonView{
    CGFloat mPlayerWidth;
    CGFloat mPlayerHeight;
    CGRect mPlayerFrame;
    float mMinutes;
    int mSeconds;
    void (^playButtonCallback) (BOOL selectedState);
    void (^changeScreenSizeCallback) (BOOL selectedState);
    void (^sliderStartCallBack) (BOOL seek);
    void (^sliderEndCallBack) (BOOL seek);
}
-(instancetype)initWithFrame:(CGRect)frame player:(QPlayerContext *)player playerFrame:(CGRect)playerFrame isLiving:(BOOL)isLiving{
    self = [super initWithFrame:frame];
    if (self) {
        self.mIsNeedUpdatePrograss = false;
        _mShortVideoBool = false;
        self.mIsSeeking = NO;
        self.mIsBuffingBool = NO;
        self.mIsLiving = isLiving;
        mPlayerFrame = playerFrame;
        self.backgroundColor = [UIColor clearColor];
        mPlayerWidth = CGRectGetWidth(playerFrame);
        mPlayerHeight = CGRectGetHeight(playerFrame);
        self.mPlayer = player;
        if (self.mIsLiving) {
            self.mTotalDuration = 0;
        } else {
            self.mTotalDuration = self.mPlayer.controlHandler.duration/1000;
        }
        mMinutes = _mTotalDuration / 60.0;
        mSeconds = (int)_mTotalDuration % 60;
        [self addSubview:self.mPrograssSlider];
        [self addTotalDurationLabel];
        [self addCurrentTimeLabel];
        [self addPlayButton];
        [self addMuteButton];
        [self addStopButton];
        [self addFullScreenButton];
        [self.mPlayer.controlHandler addPlayerProgressChangeListener:self];
        [self.mPlayer.controlHandler addPlayerAudioListener:self];
        [self.mPlayer.controlHandler addPlayerStateListener:self];
        
    }
    return self;
}
-(instancetype)initWithShortVideoFrame:(CGRect)frame player:(QPlayerContext *)player playerFrame:(CGRect)playerFrame isLiving:(BOOL)isLiving{
    self = [super initWithFrame:frame];
    if (self) {
        self.mShortVideoBool = YES;
        self.mIsSeeking = NO;
        self.mIsLiving = isLiving;
        mPlayerFrame = playerFrame;
        self.backgroundColor = [UIColor clearColor];
        mPlayerWidth = CGRectGetWidth(playerFrame);
        mPlayerHeight = CGRectGetHeight(playerFrame);
        
        [self addTotalDurationLabel];
        self.mPlayer = player;
        if (self.mIsLiving) {
            self.mTotalDuration = 0;
        } else {
            self.mTotalDuration = self.mPlayer.controlHandler.duration;
        }
        mMinutes = _mTotalDuration / 60.0;
        mSeconds = (int)_mTotalDuration % 60;
        [self addPlayButton];
        
        [self addSubview:self.mPrograssSlider];
        [self addCurrentTimeLabel];
        
        [self.mPlayer.controlHandler addPlayerProgressChangeListener:self];
        [self.mPlayer.controlHandler addPlayerStateListener:self];
        self.mIsNeedUpdatePrograss = true;
        
    }
    return self;
}
-(void)resumeListeners{
    
    [self.mPlayer.controlHandler addPlayerProgressChangeListener:self];
    [self.mPlayer.controlHandler addPlayerStateListener:self];
}
#pragma mark 添加控件
-(void)addMuteButton{
    self.mMuteButton = [[UIButton alloc] initWithFrame:CGRectMake(mPlayerWidth - 82, 0, 35, 30)];
    [self.mMuteButton setImageEdgeInsets:UIEdgeInsetsMake(3, 6, 5, 7)];
    [self.mMuteButton setImage:[[UIImage imageNamed:@"pl_notMute"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    [self.mMuteButton setImage:[[UIImage imageNamed:@"pl_mute"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.mMuteButton.tintColor = [UIColor whiteColor];
    self.mMuteButton.selected = YES;
    self.mMuteButton.hidden = YES;
    [self.mMuteButton addTarget:self action:@selector(muteButtonClick:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.mMuteButton];
}
-(void)addStopButton{
    self.mStopButton = [[UIButton alloc] initWithFrame:CGRectMake(36, 0, 35, 30)];
    [self.mStopButton setImageEdgeInsets:UIEdgeInsetsMake(3, 6, 5, 7)];
    [self.mStopButton setImage:[[UIImage imageNamed:@"pl_stop"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    self.mStopButton.tintColor = [UIColor whiteColor];
    self.mStopButton.selected = YES;
    [self.mStopButton addTarget:self action:@selector(stopButtonClick) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.mStopButton];
}
-(void)addTotalDurationLabel{
    if (_mShortVideoBool) {
        
        self.mTotalDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(mPlayerWidth - 55, 3, 40, 20)];
    }
    else{
        
        self.mTotalDurationLabel = [[UILabel alloc] initWithFrame:CGRectMake(mPlayerWidth - 152, 3, 70, 20)];
    }
    self.mTotalDurationLabel.font = PL_FONT_LIGHT(14);
    self.mTotalDurationLabel.textColor = [UIColor whiteColor];
    self.mTotalDurationLabel.textAlignment = NSTextAlignmentRight;
    self.mTotalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)mMinutes, mSeconds];
    
    [self addSubview:_mTotalDurationLabel];
}

-(void)addPlayButton{
    self.mPlayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35, 30)];
    [self.mPlayButton setImageEdgeInsets:UIEdgeInsetsMake(3, 6, 5, 7)];
    [self.mPlayButton setImage:[UIImage imageNamed:@"pl_play"] forState:UIControlStateNormal];
    [self.mPlayButton setImage:[UIImage imageNamed:@"pl_pause"] forState:UIControlStateSelected];
    [self.mPlayButton addTarget:self action:@selector(playButtonClick:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:_mPlayButton];
    
}
-(void)addCurrentTimeLabel{
    if(self.mShortVideoBool){
        
        self.mCurrentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 3, 55, 20)];
    }else{
        
        self.mCurrentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 3, 55, 20)];
    }
    self.mCurrentTimeLabel.font = PL_FONT_LIGHT(14);
    self.mCurrentTimeLabel.textColor = [UIColor whiteColor];
    self.mCurrentTimeLabel.textAlignment = NSTextAlignmentLeft;
    self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", 0, 0];
    [self addSubview:_mCurrentTimeLabel];
}

-(void)addFullScreenButton{
    self.mFullScreenButton = [[UIButton alloc] initWithFrame:CGRectMake(mPlayerWidth - 52, 0, 35, 30)];
    [self.mFullScreenButton setImageEdgeInsets:UIEdgeInsetsMake(3, 6, 5, 7)];
    [self.mFullScreenButton setImage:[UIImage imageNamed:@"pl_fullScreen"] forState:UIControlStateNormal];
    [self.mFullScreenButton setImage:[UIImage imageNamed:@"pl_smallScreen"] forState:UIControlStateSelected];
    [self.mFullScreenButton addTarget:self action:@selector(changeScreenSize:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:_mFullScreenButton];
    
}
- (void)setMPlayer:(QPlayerContext *)player {
    _mPlayer = player;
    self.mPlayButton.selected = (_mPlayer.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
}

- (UISlider *)mPrograssSlider {
    if (!_mPrograssSlider) {
        CGFloat playerWidth = CGRectGetWidth(self.frame);
        if (_mShortVideoBool) {
            
            _mPrograssSlider = [[UISlider alloc] initWithFrame:CGRectMake(76, 3, playerWidth - 126, 20)];
        }
        else{
            
            _mPrograssSlider = [[UISlider alloc] initWithFrame:CGRectMake(105, 3, playerWidth - 215, 20)];
        }
        _mPrograssSlider.enabled = !_mIsLiving;
        [_mPrograssSlider setThumbImage:[UIImage imageNamed:@"pl_round.png"]forState:UIControlStateNormal];
        _mPrograssSlider.minimumValue = 0;
        _mPrograssSlider.maximumValue = 1;
        _mPrograssSlider.minimumTrackTintColor = [UIColor whiteColor];
        _mPrograssSlider.maximumTrackTintColor = [UIColor grayColor];
        _mPrograssSlider.value = 0;
        
        // slider滑动中事件
        
        [_mPrograssSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_mPrograssSlider addTarget:self action:@selector(sliderTouchUpDown:) forControlEvents:UIControlEventTouchDown];
        [_mPrograssSlider addTarget:self action:@selector(sliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [_mPrograssSlider addTarget:self action:@selector(sliderTouchUpCancel:) forControlEvents:UIControlEventTouchCancel];
        
        [_mPrograssSlider addTarget:self action:@selector(sliderTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [_mPrograssSlider addTarget:self action:@selector(sliderTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    }
    return _mPrograssSlider;
}

#pragma mark ListenerDelegate
-(void)onMuteChanged:(QPlayerContext *)context isMute:(BOOL)isMute{
    self.mMuteButton.selected = !isMute;
}
- (void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if(state == QPLAYER_STATE_PLAYING || state == QPLAYER_STATE_PAUSED_RENDER){
        self.mIsNeedUpdatePrograss = true;
        if(state == QPLAYER_STATE_PLAYING){
            self.mMuteButton.hidden = NO;
        }
    }else{
        if(state == QPLAYER_STATE_PREPARE){
            self.mMuteButton.hidden = YES;
        }
        self.mIsNeedUpdatePrograss = false;
    }
}

-(void)onProgressChanged:(QPlayerContext *)context progress:(NSInteger)progress duration:(NSInteger)duration{
    if(self.mIsNeedUpdatePrograss){

 
        long long currentSeconds = progress/1000;
        float currentSecondsDouble = progress/1000.0;
        long long totalSeconds = self.mPlayer.controlHandler.duration/1000;

        
        if (self.mTotalDuration != duration/1000) {
            if (self.mIsLiving) {
                self.mTotalDuration = 0;
            } else {
                self.mTotalDuration = duration/1000;
            }
            float minutes = _mTotalDuration / 60.0;
            int seconds = (int)_mTotalDuration % 60;
            if (minutes < 60) {
                self.mTotalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)minutes, seconds];
            } else{
                float hours = minutes / 60.0;
                int min = (int)minutes % 60;
                self.mTotalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)hours, (int)min, seconds];
            }
            self.mPrograssSlider.maximumValue = _mTotalDuration;
        }
        
        if (self.mTotalDuration != 0 && (currentSecondsDouble >= duration/1000.0)) {
            if (!_mIsLiving) {
                self.mPrograssSlider.value = self.mTotalDuration;
                float minutes = totalSeconds / 60;
                int seconds = totalSeconds % 60;
                if(minutes>=60){
                    
                    self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)minutes/60, (int)minutes%60, seconds];
                }else{
                    
                    self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)minutes, seconds];
                }
                
            }
        } else{
            if (self.mIsSeeking || self.mIsBuffingBool) {
                return;
            }
            
            mMinutes = currentSeconds / 60;
            mSeconds = currentSeconds % 60;
            if(mMinutes>=60){
                self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)mMinutes/60, (int)mMinutes%60, mSeconds];
            }else{
                
                self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)mMinutes, mSeconds];
            }
            self.mPrograssSlider.value = currentSecondsDouble;
        }
        
    }

}

#pragma mark 对外接口

- (void)changeFrame:(CGRect)frame isFull:(BOOL)isFull{
    mPlayerWidth = CGRectGetWidth(frame);
    mPlayerHeight = CGRectGetHeight(frame);
    self.mTotalDurationLabel.frame = CGRectMake(mPlayerWidth - 162, 3, 70, 20);
    self.mFullScreenButton.frame = CGRectMake(mPlayerWidth - 52, 0, 35, 30);
    self.mMuteButton.frame = CGRectMake(mPlayerWidth - 87, 0, 35, 30);
    self.mPrograssSlider.frame = CGRectMake(105, 3, mPlayerWidth - 245, 20);
}

-(void)setFullButtonState:(BOOL)state{
    self.mFullScreenButton.selected = state;
}
-(void)setPlayButtonState:(BOOL)state{
    self.mPlayButton.selected = state;
}

///修改静音播放按钮的点击状态
-(void)setMuteButtonState:(BOOL)state{
    self.mMuteButton.selected = state;
}

-(BOOL)getFullButtonState{
    return self.mFullScreenButton.isSelected;
}

-(void)changeScreenSizeButtonClickCallBack:(void (^) (BOOL selectedState))callback{
    changeScreenSizeCallback = callback;
}

-(void)playButtonClickCallBack:(void (^) (BOOL selectedState))callback{
    playButtonCallback = callback;
}


-(void)setPlayState{
    self.mPlayButton.selected = !self.mPlayButton.selected;
    if(_mIsLiving && self.mPlayButton.selected){
        //直播情况下恢复渲染，目前是继续上一帧，有问题，需要新的接口来重新加房间
        [self.mPlayer.controlHandler resumeRender];
    }
    else if (self.mPlayButton.selected) {
        [self.mPlayer.controlHandler resumeRender];
    }
    else{
        [self.mPlayer.controlHandler pauseRender];
    }
}

#pragma mark 按钮点击事件
-(void)muteButtonClick:(UIButton *)sender{
    [self.mPlayer.controlHandler setMute:sender.selected];
    sender.selected = !sender.selected;
}
-(void)stopButtonClick{
    [self.mPlayer.controlHandler stop];
}
- (void)changeScreenSize:(UIButton *)button {
    button.selected = !button.selected;
    changeScreenSizeCallback(button.isSelected);
}
- (void)playButtonClick:(UIButton *)button {
    button.selected = !button.selected;

    playButtonCallback(button.isSelected);
    if(self.mPlayer.controlHandler.currentPlayerState == QPLAYER_STATE_COMPLETED){
        return;
    }
    if (button.selected) {
        [self.mPlayer.controlHandler resumeRender];

    } else {
        [self.mPlayer.controlHandler pauseRender];
    }
}
-(void)sliderStartCallBack:(void (^)(BOOL seeking))callBack{
    sliderStartCallBack = callBack;
}
-(void)sliderEndCallBack:(void (^)(BOOL seeking))callBack{
    sliderEndCallBack = callBack;
}
- (void)progressSliderValueChanged:(UISlider *)slider {
    _mIsSeeking = YES;
    self.mIsNeedUpdatePrograss = false;
}
- (void)sliderTouchUpDown:(UISlider*)slider {
    _mIsSeeking = YES;
    self.mIsNeedUpdatePrograss = false;
    if (sliderStartCallBack) {
        sliderStartCallBack(true);
    }

}
- (void)sliderTouchUpInside:(UISlider*)slider {
    _mIsSeeking = NO;
    self.mIsNeedUpdatePrograss = false;
    if (sliderEndCallBack) {
        sliderEndCallBack(false);
    }
    if (_mIsLiving) {
        
    }else{
        
        [self.mPlayer.controlHandler seek:(int)((slider.value) * 1000)];
        self.mPrograssSlider.value = slider.value;
        
        mMinutes = (int)slider.value / 60;
        mSeconds = (int)slider.value % 60;
        if(mMinutes>=60){
            self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)mMinutes/60, (int)mMinutes%60, mSeconds];
        }else{
            
            self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)mMinutes, mSeconds];
        }
        NSLog(@"seek --- %d", (int)slider.value);
        
    }
}
- (void)sliderTouchUpCancel:(UISlider*)slider {
    _mIsSeeking = NO;
    self.mIsNeedUpdatePrograss = false;
    if (sliderEndCallBack) {
        sliderEndCallBack(false);
    }
}

- (void)sliderTouchUpOutside:(UISlider*)slider {
    _mIsSeeking = NO;
    self.mIsNeedUpdatePrograss = false;
    if (sliderEndCallBack) {
        sliderEndCallBack(false);
    }
    if (_mIsLiving) {
        
    }else{
        [self.mPlayer.controlHandler seek:(int)((slider.value) * 1000)];
        self.mPrograssSlider.value = slider.value;
        
        mMinutes = (int)slider.value / 60;
        mSeconds = (int)slider.value % 60;
        if(mMinutes>=60){
            self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",(int)mMinutes/60, (int)mMinutes%60, mSeconds];
        }else{
            
            self.mCurrentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)mMinutes, mSeconds];
        }
        NSLog(@"seek --- %d", (int)slider.value * 1000);
    }

}
- (void)sliderTouchDragExit:(UISlider*)slider {
    _mIsSeeking = YES;
    self.mIsNeedUpdatePrograss = false;

}
-(void)dealloc{
    playButtonCallback = NULL;
    changeScreenSizeCallback = NULL;
    sliderStartCallBack = NULL;
    sliderEndCallBack = NULL;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
