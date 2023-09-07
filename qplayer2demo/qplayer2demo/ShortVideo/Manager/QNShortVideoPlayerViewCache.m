//
//  QNShortVideoPlayerViewCache.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/14.
//

#import "QNShortVideoPlayerViewCache.h"
#define TAG @"QNShortVideoPlayerViewCache"
@interface QNShortVideoPlayerViewCache()<QIPlayerStateChangeListener>
@property(nonatomic , strong) QNPlayItemManager * mPlayItemManager;
@property(nonatomic , strong) NSString * mExternalFilesDir;
@property(nonatomic , strong) QNMediaItemContextManager * mMediaItemContextManager;
@property(nonatomic , strong) QNPlayerViewManager * mPlayerViewManager;
@property(nonatomic , assign) int mCurrentPostion;
@end
@implementation QNShortVideoPlayerViewCache
-(instancetype)initWithPlayItemManager:(QNPlayItemManager *)playItemManager externalFilesDir:(NSString *)externalFilesDir{
    self = [super init];
    if(self){
        self.mPlayItemManager = playItemManager;
        self.mExternalFilesDir = externalFilesDir;
        self.mMediaItemContextManager = [[QNMediaItemContextManager alloc]init:self.mPlayItemManager externalFilesDir:externalFilesDir];
        self.mPlayerViewManager = [[QNPlayerViewManager alloc]init];
        self.mCurrentPostion = -1;
    }
    return self;
}
-(void)Log:(NSString *)logStr{
    NSLog(@"%@ %@",TAG,logStr);
}
-(void)start{
    [self.mPlayerViewManager start];
    [self.mMediaItemContextManager start];
}

-(void)stop{
    [self.mPlayerViewManager stop];
    [self.mMediaItemContextManager stop];
}
-(void)changePosition:(int)position{
    [self.mMediaItemContextManager updateMediaItemContext:position];
    [self Log:[NSString stringWithFormat:@"change position pos=%d",position]];
    
    //如果命中预渲染，则预渲染已经使用，如果没有命中，则需要回收预渲染，重建一个新pos的预渲染
    [self.mPlayerViewManager recyclePreRenderPlayerView];
    QNPlayItem * playItem = [self.mPlayItemManager getOrNullByPosition:position +1];
    if(playItem){
        if(![self.mPlayerViewManager isPreRenderValaid]){
            QMediaItemContext * item = [self.mMediaItemContextManager fetchMediaItemContextById:playItem.itemId];
            if(item){
                [self.mPlayerViewManager prepare:playItem.itemId mediaItemContext:item];
            }
        }
    }
    
    self.mCurrentPostion = position;
}

-(QNSamplePlayerWithQRenderView *)fetchPlayerView:(int)itemId{
    QNPlayItem * playItem = [self.mPlayItemManager getOrNullById:itemId];
    if(playItem){
        QMediaItemContext *mediaItemContext = [self.mMediaItemContextManager fetchMediaItemContextById:itemId];
        if(mediaItemContext == nil){
            [self Log:[NSString stringWithFormat:@"fetchPlayerView context is null id=%d",itemId]];
        }
        return [self.mPlayerViewManager fetchPlayerView:playItem mediaItemContext:mediaItemContext];
    }
    return nil;
}
-(void)recyclePlayerView:(QNSamplePlayerWithQRenderView *)playerView{
    [self removeAllListers:playerView];
    [playerView.controlHandler stop];
//    [self removeAllListers:playerView];
    playerView.hidden = YES;
    [self.mPlayerViewManager recyclePlayerView:playerView];
    
}
-(void)removeAllListers:(QNSamplePlayerWithQRenderView *)playerView{
    [playerView.controlHandler removeAllPlayerSeekListener];
    [playerView.controlHandler removeAllPlayerAudioListener];
    [playerView.controlHandler removeAllPlayerStateListener];
    [playerView.controlHandler removeAllPlayerFormatListener];
    [playerView.controlHandler removeAllPlayerQualityListener];
    [playerView.controlHandler removeAllPlayerSubtitleListener];
    [playerView.controlHandler removeAllPlayerSEIDataListener];
    [playerView.controlHandler removeAllPlayerFPSChangeListener];
    [playerView.controlHandler removeAllPlayerShootVideoListener];
    [playerView.controlHandler removeAllPlayerAuthenticationListener];
    [playerView.controlHandler removeAllPlayerSpeedChangeListener];
    [playerView.controlHandler removeAllPlayerMediaNetworkListener];
    [playerView.controlHandler removeAllPlayerDownloadChangeListener];
    [playerView.controlHandler removeAllPlayerProgressChangeListener];
    [playerView.controlHandler removeAllPlayerBufferingChangeListener];
    [playerView.controlHandler removeAllPlayerBiteRateChangeListener];
    [playerView.controlHandler removeAllPlayerCommandNotAllowListener];
    [playerView.controlHandler removeAllPlayerVideoDecodeTypeListener];
    [playerView.controlHandler removeAllPlayerVideoFrameSizeChangeListener];
    [playerView.renderHandler removeAllPlayerRenderListener];
}
-(void)dealloc{
    NSLog(@"%@ dealloc",TAG);
}

@end

