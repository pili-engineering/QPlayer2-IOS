//
//  PlayerView.m
//  QPlay2-wang
//
//  Created by 王声禄 on 2022/7/7.
//

#import "QNPlayerSettingsView.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
@implementation QNPlayerSettingsView{
    UITextField *mPosition;
    QNSpeedPlayerView *mSpeedView;
    QNChangePlayerView *mEyeView;
    QNChangePlayerView *mActionView;
    QNChangePlayerView *mSeekView;
    QNChangePlayerView *mDecoderView;
    QNChangePlayerView *mStretchPlayerView;
    QNChangePlayerView *mSEIPlayerView;
    QNChangePlayerView *mAuthenticationPlayerView;
    QNChangePlayerView *mBackgroundPlayPlayerView;
    QNChangePlayerView *mImmediatelyPlayerView;
    QNChangePlayerView *mSubtitlePlayerView;
    QNChangePlayerView *mVideoDataTypePlayerView;
    QNChangePlayerView *mInSpeakerResumeView;
    QNChangePlayerView *mMirrorView;
    void (^changePlayerViewCallback)(ChangeButtonType type , NSString * startPosition,BOOL selected);
    void (^speedViewCallback)(SpeedUIButtonType type);
}

-(instancetype)initChangePlayerViewCallBack:(void (^)(ChangeButtonType type , NSString * startPosition,BOOL selected) )back{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(ScreenWidth-390, 0, 390, ScreenHeight);
        self.backgroundColor = [UIColor blackColor];
        self.alpha =0.8;
        changePlayerViewCallback = back;
        [self addScrollView:CGRectMake(0, 0, 390, ScreenHeight)];
        
//        self.userInteractionEnabled = YES;
    }
    return self;
}
-(instancetype)initSpeedViewCallBack:(void (^)(SpeedUIButtonType type) )back{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(ScreenWidth-130, 0, 130, ScreenHeight);
        self.contentSize = CGSizeMake(130, ScreenHeight);
        self.backgroundColor = [UIColor blackColor];
        self.alpha =0.8;
        speedViewCallback = back;
        [self addSpeedView];
//        self.userInteractionEnabled = YES;
    }
    return self;
}

-(void)setPostioTittle:(int)value{
    if (mPosition) {
        mPosition.text = [NSString stringWithFormat:@"%d",value];
    }
}


-(void)setSpeedDefault:(SpeedUIButtonType)type{
    switch (type) {
        case BUTTON_TYPE_PLAY_SPEED_2_0:
        case BUTTON_TYPE_PLAY_SPEED_1_5:
        case BUTTON_TYPE_PLAY_SPEED_1_0:
        case BUTTON_TYPE_PLAY_SPEED_0_75:
        case BUTTON_TYPE_PLAY_SPEED_0_5:
            [mSpeedView setDefault:type];
            break;
            
        default:
            break;
    }
}
-(void)setChangeDefault:(ChangeButtonType)type{
    switch (type) {
        case BUTTON_TYPE_AUTOMATIC:
        case BUTTON_TYPE_STRETCHING:
        case BUTTON_TYPE_SPREAD_OVER:
        case BUTTON_TYPE_16_9:
        case BUTTON_TYPE_4_3:
            [mStretchPlayerView setDefault:type];
            break;
        case BUTTON_TYPE_FILTER_NONE:
        case BUTTON_TYPE_FILTER_GREEN_RED:
        case BUTTON_TYPE_FILTER_BLUE_YELLOW:
        case BUTTON_TYPE_FILTER_RED_GREEN:
            [mEyeView setDefault:type];
            break;
        case BUTTON_TYPE_ACTION_PLAY:
        case BUTTON_TYPE_ACTION_PAUSE:
            [mActionView setDefault:type];
            break;
        case BUTTON_TYPE_SEEK_ACCURATE:
        case BUTTON_TYPE_SEEK_KEY:
            [mSeekView setDefault:type];
            break;
        case BUTTON_TYPE_DECTOR_HARD:
        case BUTTON_TYPE_DECTOR_SOFT:
        case BUTTON_TYPE_DECTOR_AUTOMATIC:
            [mDecoderView setDefault:type];
            break;
        case BUTTON_TYPE_SEI_DATA:
            [mSEIPlayerView setDefault:type];
            break;
        case BUTTON_TYPE_AUTHENTICATION:
            [mAuthenticationPlayerView setDefault:type];
            break;
        case BUTTON_TYPE_BACKGROUND_PLAY:
            [mBackgroundPlayPlayerView setDefault:type];
            break;
            
        case BUTTON_TYPE_IMMEDIATELY_TRUE:
        case BUTTON_TYPE_IMMEDIATELY_FALSE:
        case BUTTON_TYPE_IMMEDIATELY_CUSTOM:
            [mImmediatelyPlayerView setDefault:type];
            break;
        case BUTTON_TYPE_SUBTITLE_CLOSE:
        case BUTTON_TYPE_SUBTITLE_CHINESE:
        case BUTTON_TYPE_SUBTITLE_ENGLISH:
            [mSubtitlePlayerView setDefault:type];
            break;
        case BUTTON_TYPE_VIDEO_DATA_NV12:
        case BUTTON_TYPE_VIDEO_DATA_YUV420P:
            [mVideoDataTypePlayerView setDefault:type];
            break;
        case BUTTON_TYPE_IN_SPEAKER_RESUME:
        case BUTTON_TYPE_IN_SPEAKER_NOT_RESUME:
            [mInSpeakerResumeView setDefault:type];
            break;
        case BUTTON_TYPE_MIRROR_X:
        case BUTTON_TYPE_MIRROR_Y:
        case BUTTON_TYPE_MIRROR_NONE:
        case BUTTON_TYPE_MIRROR_X_Y:
            [mMirrorView setDefault:type];
            break;
        default:
            NSLog(@"设置出错");
            break;
    }
}

-(void)addSpeedView{
    mSpeedView = [[QNSpeedPlayerView alloc]initWithFrame:CGRectMake(0, 0, 100, ScreenWidth) backgroudColor:[UIColor clearColor]];
    [mSpeedView addButtonText:@"2.0x" frame:CGRectMake((mSpeedView.frame.size.width-100)/2, 50, 100, 50) type:BUTTON_TYPE_PLAY_SPEED_2_0 target:self selector:@selector(SpeedButtonClick:)];
    [mSpeedView addButtonText:@"1.5x" frame:CGRectMake((mSpeedView.frame.size.width-100)/2, (mSpeedView.frame.size.height -100)/6+50, 100, 50) type:BUTTON_TYPE_PLAY_SPEED_1_5 target:self selector:@selector(SpeedButtonClick:)];
    [mSpeedView addButtonText:@"1.25x" frame:CGRectMake((mSpeedView.frame.size.width-100)/2, (mSpeedView.frame.size.height -100)*2/6+50, 100, 50) type:BUTTON_TYPE_PLAY_SPEED_1_25 target:self selector:@selector(SpeedButtonClick:)];
    [mSpeedView addButtonText:@"1.0x" frame:CGRectMake((mSpeedView.frame.size.width-100)/2, (mSpeedView.frame.size.height -100)*3/6+50, 100, 50) type:BUTTON_TYPE_PLAY_SPEED_1_0 target:self selector:@selector(SpeedButtonClick:)];
    [mSpeedView addButtonText:@"0.75x" frame:CGRectMake((mSpeedView.frame.size.width-100)/2, (mSpeedView.frame.size.height -100)*4/6+50, 100, 50) type:BUTTON_TYPE_PLAY_SPEED_0_75 target:self selector:@selector(SpeedButtonClick:)];
    [mSpeedView addButtonText:@"0.5x" frame:CGRectMake((mSpeedView.frame.size.width-100)/2, (mSpeedView.frame.size.height -100)*5/6+50, 100, 50) type:BUTTON_TYPE_PLAY_SPEED_0_5 target:self selector:@selector(SpeedButtonClick:)];
    [mSpeedView setDefault:BUTTON_TYPE_PLAY_SPEED_1_0];
    [self addSubview:mSpeedView];
    
}


-(void)SpeedButtonClick:(UIButton*)btn{

    if(speedViewCallback){
        speedViewCallback(btn.tag);
    }
    
}
-(void)addScrollView:(CGRect)frame{
//    self = [[UIScrollView alloc]initWithFrame:frame];
    self.contentSize = CGSizeMake(frame.size.width, 1600);
//    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;
    self.scrollEnabled = YES;
//    self.delegate = self;
//    [self addSubview:backScrollView];
    
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 5, frame.size.width-10, 30)];
    titleLabel.text = @"切换下一集生效设置";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self addSubview:titleLabel];
    
    [self addLine:CGRectMake(5, titleLabel.frame.origin.y +titleLabel.frame.size.height+3, self.frame.size.width-10, 3)];
    
    [self addDecoder:CGRectMake(0, 45, self.frame.size.width, 90)];
    
    [self addLine:CGRectMake(5, 138, self.frame.size.width-10, 2)];
    
    [self addSeek:CGRectMake(0, 145, self.frame.size.width, 90)];
    
    [self addLine:CGRectMake(5, 238, self.frame.size.width-10, 2)];
    
    [self addAction:CGRectMake(0, 245, self.frame.size.width, 90)];
    
    [self addLine:CGRectMake(5, 338, self.frame.size.width, 2)];
    
    [self addPositionTexfield: CGRectMake(0, 345, self.frame.size.width - 150, 70)];
    
    [self addLine:CGRectMake(5, 463, self.frame.size.width, 2)];
    
    [self addAuthentication:CGRectMake(0, 465, 350, 90)];
    
    UILabel *nowLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 540, self.frame.size.width, 30)];
    nowLabel.text = @"立即生效设置";
    nowLabel.textColor = [UIColor whiteColor];
    nowLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:nowLabel];
    
    [self addLine:CGRectMake(5, 568, self.frame.size.width, 2)];
    
    [self addRender:CGRectMake(0, 575, 350, 90)];
    
    [self addLine:CGRectMake(5, 663, self.frame.size.width, 2)];
    
    [self addFilter:CGRectMake(0, 675, 350, 90)];
    
    
    [self addLine:CGRectMake(5, 758, self.frame.size.width, 2)];
    
    [self addSEI:CGRectMake(0, 765, 350, 90)];
    
    [self addLine:CGRectMake(5, 853, self.frame.size.width, 2)];
    
    [self addBackgroundPlay:CGRectMake(0, 865, 350, 90)];
    
    
    [self addLine:CGRectMake(5, 948, self.frame.size.width, 2)];
    
    [self addImmediately:CGRectMake(0, 965, 350, 90)];
    
    [self addLine:CGRectMake(5, 1058, self.frame.size.width, 2)];
    
    [self addSubtitleView:CGRectMake(0, 1065, 350, 90)];
    
    [self addLine:CGRectMake(5, 1163, self.frame.size.width, 2)];
    
    [self addVideoDataType:CGRectMake(0, 1165, 350, 90)];
    
    [self addLine:CGRectMake(5, 1268, self.frame.size.width, 2)];
    
    [self addInSpeakerResume:CGRectMake(0, 1265, 350, 90)];
    
    [self addLine:CGRectMake(5, 1373, self.frame.size.width, 2)];
    
    [self addMirrorView:CGRectMake(0, 1375, 350, 90)];
    
}
-(void)addImmediately:(CGRect)frame{
    mImmediatelyPlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mImmediatelyPlayerView setTitleLabelText:@"清晰度切换" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mImmediatelyPlayerView addButtonText:@"立即切换" frame:CGRectMake(10, 50, 90, 20) type:BUTTON_TYPE_IMMEDIATELY_TRUE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mImmediatelyPlayerView addButtonText:@"无缝切换(只适用点播)" frame:CGRectMake(100, 50, 160, 20) type:BUTTON_TYPE_IMMEDIATELY_FALSE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mImmediatelyPlayerView addButtonText:@"直播立即点播无缝" frame:CGRectMake(260, 50, 150, 20) type:BUTTON_TYPE_IMMEDIATELY_CUSTOM target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mImmediatelyPlayerView setDefault:BUTTON_TYPE_IMMEDIATELY_CUSTOM];
    [self addSubview:mImmediatelyPlayerView];
}


-(void)addBackgroundPlay:(CGRect)frame{
    
    
    mBackgroundPlayPlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mBackgroundPlayPlayerView setTitleLabelText:@"后台播放" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mBackgroundPlayPlayerView addButtonText:@"是否支持后台播放" frame:CGRectMake(10, 50, 150, 20) type:BUTTON_TYPE_BACKGROUND_PLAY target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];

    [self addSubview:mBackgroundPlayPlayerView];
}
-(void)addAuthentication:(CGRect)frame{
    
    mAuthenticationPlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mAuthenticationPlayerView setTitleLabelText:@"鉴权" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mAuthenticationPlayerView addButtonText:@"下一次刷新鉴权信息" frame:CGRectMake(10, 50, 150, 20) type:BUTTON_TYPE_AUTHENTICATION target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];

    [self addSubview:mAuthenticationPlayerView];
}
-(void)addSEI:(CGRect)frame{
    
    mSEIPlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mSEIPlayerView setTitleLabelText:@"SEI回调" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mSEIPlayerView addButtonText:@"是否开启SEI回调" frame:CGRectMake(10, 50, 150, 20) type:BUTTON_TYPE_SEI_DATA target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];

    [self addSubview:mSEIPlayerView];
}
-(void)addPositionTexfield:(CGRect)frame{
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.origin.x+5, frame.origin.y+5, frame.size.width, 30)];
    titleLabel.text = @"起播位置(毫秒)";
    titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:titleLabel];
    
    
    mPosition = [[UITextField alloc]initWithFrame:CGRectMake(frame.origin.x+5, titleLabel.frame.origin.y + titleLabel.frame.size.height +5, frame.size.width, 30)];
//    position.placeholder = @"0";
    mPosition.text = @"0";
    mPosition.textColor = [UIColor whiteColor];
    mPosition.delegate  = self;
    mPosition.keyboardType = UIKeyboardTypeNumberPad;
    mPosition.backgroundColor = [UIColor clearColor];
    mPosition.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self addSubview:mPosition];
    
    [self addLine:CGRectMake(mPosition.frame.origin.x, mPosition.frame.origin.y+mPosition.frame.size.height +1, mPosition.frame.size.width, 1)];
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([mPosition.text isEqual:@""]) {
        mPosition.text = @"0";
    }
    if (changePlayerViewCallback) {
        changePlayerViewCallback(nil,mPosition.text,NO);
    }
    [textField resignFirstResponder]; //回收键盘
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([mPosition.text isEqual:@""]) {
        mPosition.text = @"0";
    }
    if (changePlayerViewCallback) {
        changePlayerViewCallback(nil,mPosition.text,NO);
    }

}


-(void)addFilter:(CGRect)frame{
    mEyeView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mEyeView setTitleLabelText:@"色觉变化" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mEyeView addButtonText:@"无滤镜" frame:CGRectMake(10, 50, 90, 20) type:BUTTON_TYPE_FILTER_NONE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mEyeView addButtonText:@"红/绿滤镜" frame:CGRectMake(105, 50, 90, 20) type:BUTTON_TYPE_FILTER_RED_GREEN target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mEyeView addButtonText:@"绿/红滤镜" frame:CGRectMake(200, 50, 90, 20) type:BUTTON_TYPE_FILTER_GREEN_RED target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mEyeView addButtonText:@"蓝/黄滤镜" frame:CGRectMake(295, 50, 90, 20) type:BUTTON_TYPE_FILTER_BLUE_YELLOW target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mEyeView setDefault:BUTTON_TYPE_FILTER_NONE];
    [self addSubview:mEyeView];
}
-(void)addAction:(CGRect)frame{
    mActionView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mActionView setTitleLabelText:@"Start Seek" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mActionView addButtonText:@"起播播放" frame:CGRectMake(10, 50, 100, 20) type:BUTTON_TYPE_ACTION_PLAY target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mActionView addButtonText:@"起播暂停" frame:CGRectMake(225, 50, 100, 20) type:BUTTON_TYPE_ACTION_PAUSE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mActionView setDefault:BUTTON_TYPE_ACTION_PLAY];
    [self addSubview:mActionView];
}

-(void)addSeek:(CGRect)frame{
    mSeekView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mSeekView setTitleLabelText:@"Seek" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mSeekView addButtonText:@"关键帧Seek" frame:CGRectMake(10, 50, 100, 20) type:BUTTON_TYPE_SEEK_KEY target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mSeekView addButtonText:@"精准Seek" frame:CGRectMake(225, 50, 100, 20) type:BUTTON_TYPE_SEEK_ACCURATE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mSeekView setDefault:BUTTON_TYPE_SEEK_KEY];
    [self addSubview:mSeekView];
}
-(void)addLine:(CGRect)frame {
    UIView *line = [[UIView alloc]initWithFrame:frame];
    line.backgroundColor = [UIColor whiteColor];
    [self addSubview:line];
}
-(void)addDecoder:(CGRect)frame{
    mDecoderView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mDecoderView setTitleLabelText:@"Decoder" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mDecoderView addButtonText:@"自动" frame:CGRectMake(10, 50, 60, 20) type:BUTTON_TYPE_DECTOR_AUTOMATIC target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mDecoderView addButtonText:@"软解" frame:CGRectMake(125, 50, 60, 20) type:BUTTON_TYPE_DECTOR_SOFT target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mDecoderView addButtonText:@"硬解" frame:CGRectMake(240, 50, 60, 20) type:BUTTON_TYPE_DECTOR_HARD target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mDecoderView setDefault:BUTTON_TYPE_DECTOR_AUTOMATIC];
    [self addSubview:mDecoderView];
}
-(void)addSubtitleView:(CGRect)frame{
    mSubtitlePlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mSubtitlePlayerView setTitleLabelText:@"字幕设置" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mSubtitlePlayerView addButtonText:@"关闭" frame:CGRectMake(10, 50, 60, 20) type:BUTTON_TYPE_SUBTITLE_CLOSE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mSubtitlePlayerView addButtonText:@"中文" frame:CGRectMake(125, 50, 60, 20) type:BUTTON_TYPE_SUBTITLE_CHINESE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mSubtitlePlayerView addButtonText:@"英文" frame:CGRectMake(240, 50, 60, 20) type:BUTTON_TYPE_SUBTITLE_ENGLISH target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mSubtitlePlayerView setDefault:BUTTON_TYPE_SUBTITLE_CLOSE];
    [self addSubview:mSubtitlePlayerView];
}
-(void)addInSpeakerResume:(CGRect)frame{
    mInSpeakerResumeView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mInSpeakerResumeView setTitleLabelText:@"切换扬声器继续播放" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mInSpeakerResumeView addButtonText:@"播放" frame:CGRectMake(10, 50, 60, 20) type:BUTTON_TYPE_IN_SPEAKER_RESUME target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mInSpeakerResumeView addButtonText:@"暂停" frame:CGRectMake(125, 50, 60, 20) type:BUTTON_TYPE_IN_SPEAKER_NOT_RESUME target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mInSpeakerResumeView setDefault:BUTTON_TYPE_IN_SPEAKER_RESUME];
    [self addSubview:mInSpeakerResumeView];
}
-(void)addMirrorView:(CGRect)frame{
    mMirrorView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mMirrorView setTitleLabelText:@"镜像" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mMirrorView addButtonText:@"无" frame:CGRectMake(10, 50, 60, 20) type:BUTTON_TYPE_MIRROR_NONE target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mMirrorView addButtonText:@"横向" frame:CGRectMake(105, 50, 90, 20) type:BUTTON_TYPE_MIRROR_X target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mMirrorView addButtonText:@"竖直" frame:CGRectMake(200, 50, 90, 20) type:BUTTON_TYPE_MIRROR_Y target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mMirrorView addButtonText:@"横向和竖直" frame:CGRectMake(295, 50, 90, 20) type:BUTTON_TYPE_MIRROR_X_Y target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mMirrorView setDefault:BUTTON_TYPE_MIRROR_NONE];
    [self addSubview:mMirrorView];
}
-(void)addVideoDataType:(CGRect)frame{
    mVideoDataTypePlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mVideoDataTypePlayerView setTitleLabelText:@"video 回调数据类型" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mVideoDataTypePlayerView addButtonText:@"YUV420p" frame:CGRectMake(10, 50, 100, 20) type:BUTTON_TYPE_VIDEO_DATA_YUV420P target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mVideoDataTypePlayerView addButtonText:@"NV12" frame:CGRectMake(165, 50, 100, 20) type:BUTTON_TYPE_VIDEO_DATA_NV12 target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mVideoDataTypePlayerView setDefault:BUTTON_TYPE_VIDEO_DATA_YUV420P];
    [self addSubview:mVideoDataTypePlayerView];
}
-(void)addRender:(CGRect)frame{
    
    mStretchPlayerView = [[QNChangePlayerView alloc]initWithFrame:frame backgroudColor:[UIColor clearColor]];
    [mStretchPlayerView setTitleLabelText:@"Render ratio" frame:CGRectMake(10, 10, 120, 30) textColor:[UIColor whiteColor]];
    [mStretchPlayerView addButtonText:@"自动" frame:CGRectMake(10, 50, 60, 20) type:BUTTON_TYPE_AUTOMATIC target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mStretchPlayerView addButtonText:@"拉伸" frame:CGRectMake(80, 50, 60, 20) type:BUTTON_TYPE_STRETCHING target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mStretchPlayerView addButtonText:@"铺满" frame:CGRectMake(150, 50, 60, 20) type:BUTTON_TYPE_SPREAD_OVER target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mStretchPlayerView addButtonText:@"16:9" frame:CGRectMake(220, 50, 60, 20) type:BUTTON_TYPE_16_9 target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mStretchPlayerView addButtonText:@"4:3" frame:CGRectMake(290, 50, 60, 20) type:BUTTON_TYPE_4_3 target:self selector:@selector(changePlayerViewClick:) selectorTag:@selector(changePlayerViewClickTag:)];
    [mStretchPlayerView setDefault:BUTTON_TYPE_AUTOMATIC];
    [self addSubview:mStretchPlayerView];
}
-(void)changePlayerViewClick:(UIButton *)btn{
    if (changePlayerViewCallback) {
        changePlayerViewCallback(btn.tag,mPosition.text,btn.selected);
    }
}
-(void)changePlayerViewClickTag:(UIGestureRecognizer *)btn{
    BOOL selected = YES;
    switch (btn.view.tag) {
        case BUTTON_TYPE_AUTHENTICATION:
            selected = [mAuthenticationPlayerView getButtonSelected:BUTTON_TYPE_AUTHENTICATION];
            break;
        case BUTTON_TYPE_SEI_DATA:
            
            selected = [mSEIPlayerView getButtonSelected:BUTTON_TYPE_SEI_DATA];
            break;
        case BUTTON_TYPE_BACKGROUND_PLAY:
            selected = [mBackgroundPlayPlayerView getButtonSelected:BUTTON_TYPE_BACKGROUND_PLAY];
            break;
        default:
            break;
            
    }
    if (changePlayerViewCallback) {
        changePlayerViewCallback(btn.view.tag,mPosition.text,selected);
    }
}
@end
