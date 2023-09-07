//
//  MDResult.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDResponse : NSObject
@property (nonatomic, strong, readonly) NSDictionary *headers;
@end

@interface MDResult : NSObject

@property (nonatomic, assign, readonly) int64_t size;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, strong, readonly) NSString *contentType;

- (NSInputStream *)stream;
- (MDResponse *)underLayer;

@end

NS_ASSUME_NONNULL_END
