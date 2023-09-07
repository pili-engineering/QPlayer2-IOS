//
//  MDRange.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDRange : NSObject

// 左闭右开[start,end);
@property (nonatomic, assign) int64_t start;
@property (nonatomic, assign) int64_t end;

- (instancetype)initWithStart:(int64_t)start
                          end:(int64_t)end;

@end

NS_ASSUME_NONNULL_END
