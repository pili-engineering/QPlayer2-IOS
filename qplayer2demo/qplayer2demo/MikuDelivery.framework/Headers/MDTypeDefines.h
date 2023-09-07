//
//  MDTypeDefines.h
//  MikuDelivery
//
//  Copyright © 2023 Qiniu Cloud (qiniu.com). All rights reserved.
//

#ifndef MikuDelivery_MDTypeDefines_h
#define MikuDelivery_MDTypeDefines_h

#import <Foundation/Foundation.h>

extern NSString *MikuDeliveryErrorDomain;

#pragma mark - Miku Delivery Error Domain

NS_ERROR_ENUM(MikuDeliveryErrorDomain) {

    MikuDeliveryErrorTaskAlreadyStarted = 10000,

    MikuDeliveryErrorClientClosed = 10001,
    
    MikuDeliveryErrorHttpRequestFailed = 10003,
    
    MikuDeliveryErrorWiFiRequired = 10004,
    
    MikuDeliveryErrorSocketDisconnected = 10005,
    
    MikuDeliveryErrorIOWriteFailed = 10006,
    
    MikuDeliveryErrorInvalidParameter = 10007,
    
    MikuDeliveryErrorTaskIsCanceled = 10008,
    
    MikuDeliveryErrorTaskIsRefreshed = 10009,
    
    MikuDeliveryErrorCacheSizeNotEnough = 10010,
};

#endif
