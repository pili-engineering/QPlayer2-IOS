//
//  QMediaModelBuilder.h
//  qplayer2-core
//
//  Created by 王声禄 on 2022/11/3.
//

#import <Foundation/Foundation.h>
#import <qplayer2_core/QMediaModel.h>
#import <qplayer2_core/QIOSCommon.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * 播放资源构造器
 */
@interface QMediaModelBuilder : NSObject
/***
 * 构造器初始化
 * @param islive 是否是直播
 */
-(instancetype)initWithIsLive:(bool)islive;

-(instancetype)init NS_UNAVAILABLE;

/***
 * 添加视频资源
 * @param userType 预留字段可以填空
 * @param urlType 媒体的资源属性 只包含视频/只包含音频/同时有视频音频
 * @param url 资源地址
 * @param quality 清晰度
 * @param isSelected 是否起播时播放该流
 * @param backupUrl 备用地址
 * @param referer http/https 协议的地址 支持该属性
 * @param renderType 视频的渲染类型
 */
-(void)addStreamElementWithUserType:(NSString *)userType urlType:(QPlayerURLType)urlType url:(NSString *)url quality:(int)quality isSelected:(BOOL)isSelected backupUrl:(NSString *)backupUrl referer:(NSString *)referer renderType:(QPlayerRenderType)renderType NS_SWIFT_NAME(addStreamElement(userType:urlType:url:quality:isSelected:backupUrl:referer:renderType:));
/***
 * 添加视频资源数组
 * @param streamElements 视频资源数组
 */
-(void)addStreamElements:(NSArray <QStreamElement*> *)streamElements;


/**
 * 构建QMediaModel
 * @return 返回构建的QMediaModel
 */
-(QMediaModel *)build;
@end

NS_ASSUME_NONNULL_END
