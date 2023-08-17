//
//  MDTask.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

@class MDResult;
NS_ASSUME_NONNULL_BEGIN

@interface MDTask : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)setPriority:(int)priority;

- (void)setWifiRequired:(BOOL)wifiRequired;

- (MDResult *)start:(NSError **)error;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
