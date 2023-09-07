//
//  MDResolveResult.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDResolveResult : NSObject

@property (nonatomic, strong) NSArray<NSString *> *IPs;
@property (nonatomic, assign) int TTL;

@end

NS_ASSUME_NONNULL_END
