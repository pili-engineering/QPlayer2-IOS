//
//  MDConfig.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDCacheConfig.h"
#import "MDCacheUrl.h"
#import "MDDNSResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDConfig : NSObject

@property (nonatomic, strong) MDDNSResolver *resolver;
@property (nonatomic, assign) BOOL httpDNS;
@property (nonatomic, strong) MDCacheConfig *cacheConfig;
@property (nonatomic, strong) MDCacheUrl *cacheUrl;
@property (nonatomic, assign) int workers;

@end

NS_ASSUME_NONNULL_END
