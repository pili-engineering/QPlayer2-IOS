//
//  QNPlayerViewManager.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/14.
//

#import <Foundation/Foundation.h>
#import "QNSamplePlayerWithQRenderView.h"
#import "QNPlayItemManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface QNPlayerViewManager : NSObject
-(instancetype)init;
-(void)start;

-(void)stop;
-(BOOL)isPreRenderValaid;
-(BOOL)recyclePreRenderPlayerView;
-(BOOL)prepare:(int)itemId mediaItemContext:(QMediaItemContext *)mediaItemContext;
-(QNSamplePlayerWithQRenderView *)fetchPlayerView:(QNPlayItem *)playItem mediaItemContext:(QMediaItemContext *)mediaItemContext;
-(void)recyclePlayerView:(QNSamplePlayerWithQRenderView *)playerView;
@end

NS_ASSUME_NONNULL_END
