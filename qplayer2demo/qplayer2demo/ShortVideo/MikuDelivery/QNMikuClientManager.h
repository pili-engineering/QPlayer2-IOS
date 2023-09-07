//
//  QNMikuClientManager.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/14.
//

#import <Foundation/Foundation.h>

#import <MikuDelivery/MikuDelivery.h>
NS_ASSUME_NONNULL_BEGIN

@interface QNMikuClientManager : NSObject
+ (instancetype)sharedInstance;
-(MDClient *)getMikuClient;
-(void)uninit;
@end

NS_ASSUME_NONNULL_END
