//
//  MDLogger.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDEnv.h"
#import "MDMetric.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDLogger : NSObject

@property (nonatomic, strong, readonly) NSString *appID;

@property (nonatomic, strong, readonly) NSString *appSalt;

@property (nonatomic, strong, readonly) MDEnv *env;

@property (nonatomic, strong, readonly) NSString *dir;

+ (MDLogger *)createLogger:(NSString *)appID
                   appSalt:(NSString *)appSalt
                       env:(MDEnv *)env;

+ (MDLogger *)createLogger:(NSString *)appID
                   appSalt:(NSString *)appSalt
                       env:(MDEnv *)env
                       dir:(nullable NSString *)dir;

- (void)log:(MDMetric *)metric;

@end

NS_ASSUME_NONNULL_END
