//
//  QNPlayerViewManager.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/14.
//

#import "QNPlayerViewManager.h"

#define MAX_COUNT 3
#define INVALID_VIDEO_ID -9999
#define TAG @"PlayerViewManager"
@interface QNPlayerViewManager()<QIPlayerRenderListener>
@property (nonatomic , strong) NSMutableArray<QNSamplePlayerWithQRenderView *> * mPlayerViews;
@property (nonatomic , assign) int mCurrentCacheCount;
@property (nonatomic , strong) QNSamplePlayerWithQRenderView * mPreRenderPlayerView;
@property (nonatomic , assign) int mPreRenderVideoId;
@property (nonatomic , assign) BOOL tagFalse;
@end

@implementation QNPlayerViewManager

-(instancetype)init{
    self = [super init];
    if(self){
        self.mPlayerViews = [NSMutableArray array];
        self.mCurrentCacheCount = 0;
        self.tagFalse = false;
        self.mPreRenderVideoId = INVALID_VIDEO_ID;
    }
    return self;
}

-(void)start{
    
}

-(void)stop{
    for (QNSamplePlayerWithQRenderView *innerPlayer in self.mPlayerViews) {
        [innerPlayer.controlHandler stop];
        [innerPlayer.controlHandler playerRelease];
    }
    if(self.mPreRenderPlayerView){
        [self.mPreRenderPlayerView.controlHandler stop];
        [self.mPreRenderPlayerView.controlHandler playerRelease];
        self.mPreRenderPlayerView = nil;
    }
    [self.mPlayerViews removeAllObjects];
    self.mPlayerViews = nil;
}

-(BOOL)isPreRenderValaid{
    return self.mPreRenderVideoId != INVALID_VIDEO_ID;
}

-(BOOL)recyclePreRenderPlayerView{
    BOOL ret = false;
    if(self.mPreRenderPlayerView){
        [self.mPreRenderPlayerView.controlHandler stop];
        self.mPreRenderPlayerView.hidden =YES;
        [self recyclePlayerView:self.mPreRenderPlayerView];
        ret = true;
    }
    self.mPreRenderPlayerView = nil;
    self.mPreRenderVideoId = INVALID_VIDEO_ID;
    return ret;
}
-(void)recyclePlayerView:(QNSamplePlayerWithQRenderView *)playerView{
    for (QNSamplePlayerWithQRenderView *innerView in self.mPlayerViews) {
        if([innerView isEqual:playerView]){
            [self Log:@"playerView Repeated recycling"];
            return;
        }
    }
    
    [self.mPlayerViews addObject:playerView];
    [self Log:[NSString stringWithFormat:@"recyclePlayerView size=%ld current-count=%d" , self.mPlayerViews.count,self.mCurrentCacheCount]];
}
-(void)Log:(NSString *)logStr{
    NSLog(@"%@ %@",TAG,logStr);
}
-(QNSamplePlayerWithQRenderView *)fetchPlayerView{
    if(self.mPlayerViews.count > 0){
        QNSamplePlayerWithQRenderView * playerView = self.mPlayerViews[0];
        playerView.hidden = NO;
        [self.mPlayerViews removeObjectAtIndex:0];
        return playerView;
    }else{
        if(self.mCurrentCacheCount < MAX_COUNT){
            NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            self.mCurrentCacheCount ++;
            QNSamplePlayerWithQRenderView * playerView = [[QNSamplePlayerWithQRenderView alloc]initWithFrame:CGRectMake(0, 0, 1, 1) APPVersion:@"" localStorageDir:documentsDir logLevel:LOG_DEBUG];
            playerView.hidden = NO;
            if(!self.tagFalse){
                playerView.mytag = @"A";
                self.tagFalse = true;
            }else{
                
                playerView.mytag = @"B";
            }
            return playerView;
        }else{
            return nil;
        }
    }
}

-(QNSamplePlayerWithQRenderView *)fetchPlayerView:(QNPlayItem *)playItem mediaItemContext:(QMediaItemContext *)mediaItemContext{
    if (playItem.itemId == self.mPreRenderVideoId && self.mPreRenderPlayerView != nil){
        QNSamplePlayerWithQRenderView *ret = self.mPreRenderPlayerView;
        self.mPreRenderPlayerView = nil;
        self.mPreRenderVideoId = INVALID_VIDEO_ID;
        ret.hidden = NO;
        [ret.controlHandler resumeRender];
        [self Log:[NSString stringWithFormat:@"fetchPlayerView::PreRender playerview id=%d size=%ld current-count=%d",playItem.itemId,self.mPlayerViews.count,self.mCurrentCacheCount]];
        return ret;
    }else if (mediaItemContext != nil){
        QNSamplePlayerWithQRenderView *ret = [self fetchPlayerView];
        ret.hidden = NO;
        [ret.controlHandler setStartAction:QPLAYER_START_SETTING_PLAYING];
        [ret.controlHandler playMediaItem:mediaItemContext];
        [self Log:[NSString stringWithFormat:@"fetchPlayerView::PreLoad playerview id=%d size=%ld current-count=%d",playItem.itemId,self.mPlayerViews.count,self.mCurrentCacheCount]];
        return ret;
    }else{
        QNSamplePlayerWithQRenderView *ret = [self fetchPlayerView];
        ret.hidden = NO;
        [ret.controlHandler setStartAction:QPLAYER_START_SETTING_PLAYING];
        [ret.controlHandler playMediaModel:playItem.mediaModel startPos:0];
        [self Log:[NSString stringWithFormat:@"fetchPlayerView::normal playerview id=%d size=%ld current-count=%d",playItem.itemId,self.mPlayerViews.count,self.mCurrentCacheCount]];
        return ret;
    }
}

-(BOOL)prepare:(int)itemId mediaItemContext:(QMediaItemContext *)mediaItemContext{
    if(self.mPreRenderPlayerView != nil){
        return false;
    }
    self.mPreRenderPlayerView = [self fetchPlayerView];
    
    [self.mPreRenderPlayerView.renderHandler addPlayerRenderListener:self];
    [self Log:[NSString stringWithFormat:@"prepare id=%d ",itemId]];
    if(self.mPreRenderPlayerView !=nil){
        [self.mPreRenderPlayerView.controlHandler setStartAction:QPLAYER_START_SETTING_PAUSE];
        [self.mPreRenderPlayerView.controlHandler playMediaItem:mediaItemContext];
        self.mPreRenderPlayerView.hidden = YES;
        self.mPreRenderVideoId = itemId;
        return true;
    }else{
        return false;
    }
}
-(void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    if([self.mPreRenderPlayerView.controlHandler isEqual:context.controlHandler]){
        
        NSLog(@" QNPlayerViewManager 预渲染首帧时间----%d",elapsedTime);
    }
}
-(void)dealloc{
    NSLog(@"%@ dealloc",TAG);
}
@end

