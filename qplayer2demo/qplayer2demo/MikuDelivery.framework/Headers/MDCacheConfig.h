//
//  MDCacheConfig.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDCacheConfig : NSObject

@property (nonatomic, strong) NSString *dir;
@property (nonatomic, strong) NSString *dbName;
@property (nonatomic, assign) int64_t cacheSize;

@end

NS_ASSUME_NONNULL_END
