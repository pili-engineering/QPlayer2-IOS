//
//  MDClient.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import "MDConfig.h"
#import <Foundation/Foundation.h>



@class MDRange;
@class MDTask;
NS_ASSUME_NONNULL_BEGIN

@interface MDClient : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (MDClient *)createClient:(nonnull NSString *)appID
                   appSalt:(nonnull NSString *)appSalt
                    config:(nullable MDConfig *)config;

- (void)setCacheSize:(int64_t)cacheSize;

- (void)setWorkers:(int)count;

- (MDTask *)createTask:(nonnull NSString *)url
                 range:(nullable MDRange *)range;

- (MDTask *)createTask:(nonnull NSString *)url
                 range:(nullable MDRange *)range
                expiry:(int64_t)expiry;

- (NSURL *)makeProxyURL:(NSString *)url;

- (void)clearCache;

- (void)close;

@end

NS_ASSUME_NONNULL_END
