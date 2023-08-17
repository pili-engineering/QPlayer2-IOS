//
//  MDMediaOptimization.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDMediaOptimization : NSObject

@property (nonatomic, assign) int64_t threshold;

- (instancetype)initWithThreshold:(int64_t)threshold;

@end

NS_ASSUME_NONNULL_END
