//
//  MDMetric.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDMetric : NSObject

- (NSString *)name;
- (NSArray<NSString *> *)fields;
- (NSArray<NSString *> *)values;
- (NSString *)formatGoString:(NSString *)value;

@end

NS_ASSUME_NONNULL_END
