//
//  QNotificationCenterHelper.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2024/4/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QNotificationCenterHelper : NSObject

-(instancetype)initWithPlayerView:(QPlayerView *) qplayer;

-(instancetype)initWithPlayerContext:(QPlayerContext *) context;

-(instancetype)init NS_UNAVAILABLE;

-(instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
