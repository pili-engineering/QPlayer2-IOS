//
//  QNShortVideoPlayerViewCache.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/14.
//

#import <Foundation/Foundation.h>
#import "QNPlayItemManager.h"
#import "QNSamplePlayerWithQRenderView.h"
#import "QNPlayerViewManager.h"
#import "QNMediaItemContextManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface QNShortVideoPlayerViewCache : NSObject
-(instancetype)initWithPlayItemManager:(QNPlayItemManager *)playItemManager externalFilesDir:(NSString *)externalFilesDir;

-(void)start;

-(void)stop;

-(void)changePosition:(int)position;

-(QNSamplePlayerWithQRenderView *)fetchPlayerView:(int)itemId;

-(void)recyclePlayerView:(QNSamplePlayerWithQRenderView *)playerView;
@end

NS_ASSUME_NONNULL_END
