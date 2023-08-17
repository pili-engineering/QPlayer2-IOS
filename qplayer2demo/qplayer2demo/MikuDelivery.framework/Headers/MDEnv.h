//
//  MDEnv.h
//  MikuDelivery
//
//  Copyright © 2022 Qiniu Cloud (qiniu.com). All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDEnv : NSObject

@property (nonatomic, strong) NSString *OS;      // 操作系统 (名称 + 版本)
@property (nonatomic, strong) NSString *App;     // App (名称 + 版本)
@property (nonatomic, strong) NSString *SDK;     // SDK (名称 + 版本)
@property (nonatomic, strong) NSString *DevModel;// 设备型号
@property (nonatomic, strong) NSString *DevID;   // 设备唯一 ID

@end

NS_ASSUME_NONNULL_END
