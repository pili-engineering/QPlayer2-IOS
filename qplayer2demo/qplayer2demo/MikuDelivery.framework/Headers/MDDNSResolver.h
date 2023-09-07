//
//  MDDNSResolver.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import "MDResolveResult.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDDNSResolver : NSObject

- (MDResolveResult *)resolve:(NSString *)domain;

@end

NS_ASSUME_NONNULL_END
