//
//  QMediaModel.h
//  qplayer2-core
//
//  Created by 王声禄 on 2022/11/3.
//

#import <Foundation/Foundation.h>
#import <qplayer2_core/QIOSCommon.h>
NS_ASSUME_NONNULL_BEGIN
/**
 * 添加 steramElement
*/
@interface QStreamElement : NSObject
/**
 @brief userType 用户自定义Type
 */
@property (strong, nonatomic) NSString *userType;
/**
 @brief urlType 媒体的资源属性 只包含视频/只包含音频/同时有视频音频
 */
@property (assign, nonatomic) QPlayerURLType urlType;
/**
 @brief url 视频地址
 */
@property (strong, nonatomic) NSString *url;
/**
 @brief quality 清晰度
 */
@property (assign, nonatomic) int quality;
/**
 @brief isSelected 是否起播时播放该流
 */
@property (assign, nonatomic) BOOL isSelected;
/**
 @brief backupUrl 备用地址
 */
@property (copy, nonatomic) NSString *backupUrl;
/**
 @brief referer http/https 协议的地址 支持该属性
 */
@property (copy, nonatomic) NSString *referer;
/**
 @brief renderType 视频的渲染类型
 */
@property (assign, nonatomic) QPlayerRenderType renderType;

@end


/**
 * 播放资源
 */
@interface QMediaModel : NSObject
/**
 @brief streamElements 媒体资源包含的流
 */
@property (strong, nonatomic,readonly) NSArray <QStreamElement*> *streamElements;
/**
 @brief isLive true 直播 false 点播
 */
@property (assign, nonatomic,readonly) BOOL isLive;


-(instancetype)init NS_UNAVAILABLE;


@end

NS_ASSUME_NONNULL_END
