//
//  QNotificationCenterHelper.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2024/4/18.
//

#import "QNotificationCenterHelper.h"
@interface QNotificationCenterHelper()
<QIPlayerStateChangeListener>
@property (nonatomic, strong) QPlayerView* mPlayerView;
@property (nonatomic, strong) QPlayerContext* mPlayerContext;
@property (nonatomic, assign) BOOL mIsPlaying;
@end
@implementation QNotificationCenterHelper

-(instancetype)initWithPlayerContext:(QPlayerContext *) context{
    self = [super init];
    if (self) {
        self.mPlayerContext = context;
        self.mIsPlaying = NO;
        //被打断和打断终止通知监听
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVAudioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        
        //已经进入到前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIApplicationWillEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self.mPlayerContext.controlHandler addPlayerStateListener:self];
    }
    return self;
}
-(instancetype)initWithPlayerView:(QPlayerView *)qplayer{
    self = [super init];
    if (self) {
        self.mPlayerView = qplayer;
        self.mIsPlaying = NO;
        //被打断和打断终止通知监听
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAVAudioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
        
        //已经进入到前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIApplicationWillEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self.mPlayerView.controlHandler addPlayerStateListener:self];
    }
    return self;
}


#pragma mark - 系统通知监听
-(void)onAVAudioSessionInterruption:(NSNotification *)note{
    NSDictionary *userInfo = note.userInfo;
    AVAudioSessionInterruptionType type = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (AVAudioSessionInterruptionTypeBegan == type) {
        NSLog(@"player be interrupted by other audio");
        if (self.mIsPlaying) {
            if (self.mPlayerView != nil) {
                [self.mPlayerView.controlHandler pauseRender];
            }else if(self.mPlayerContext != nil){
                [self.mPlayerContext.controlHandler pauseRender];
            }
            
        }

    }
}
- (void)onUIApplicationWillEnterForeground:(NSNotification *)note{
    if (self.mPlayerView != nil) {
        [self.mPlayerView.controlHandler resumeAudioSessionCategory];
        [self.mPlayerView.controlHandler resumeRender];
    }else if(self.mPlayerContext != nil){
        [self.mPlayerContext.controlHandler resumeAudioSessionCategory];
        [self.mPlayerContext.controlHandler resumeRender];
    }
    
}
- (void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if (self.mPlayerView != nil) {
        if ((context.controlHandler == self.mPlayerView.controlHandler) && state == QPLAYER_STATE_PLAYING) {
            self.mIsPlaying = YES;
        }
        else{
            self.mIsPlaying = NO;
        }
    }else if(self.mPlayerContext != nil){
        if ((context.controlHandler == self.mPlayerContext.controlHandler) && state == QPLAYER_STATE_PLAYING) {
            self.mIsPlaying = YES;
        }
        else{
            self.mIsPlaying = NO;
        }
    }
}

- (void)dealloc
{
    if (self.mPlayerView) {
        self.mPlayerView = nil;
    }
    if (self.mPlayerContext) {
        self.mPlayerContext = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
