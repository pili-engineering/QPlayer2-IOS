//
//  QNPlayerMaskView.h
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/9/28.
//  Copyright © 2017年 qiniu. All rights reserved.
//

#import <UIKit/UIKit.h>
@class QNPlayerMaskView;
@protocol QNPlayerMaskViewDelegate <NSObject>

/**
 点击 QNPlayerMaskView 返回按钮的回调

 @param playerMaskView QNPlayerMaskView 的实例
 @param backButton 返回按钮
 */
- (void)playerMaskView:(QNPlayerMaskView *)playerMaskView didGetBack:(UIButton *)backButton;


/**
 点击放大／缩小 QNPlayerMaskView 屏幕按钮的结果回调

 @param playerMaskView QNPlayerMaskView 的实例
 @param isLandscape 是否是横屏状态
 */
- (void)playerMaskView:(QNPlayerMaskView *)playerMaskView isLandscape:(BOOL)isLandscape;



- (void)reOpenPlayPlayerMaskView:(QNPlayerMaskView *)playerMaskView;
- (void)shootVideoButtonClick;
- (void)pushStreamButtonClick:(BOOL)isSelected;
- (void)setImmediately:(int)immediately;

@end

@interface QNPlayerMaskView : UIView

@property (nonatomic, assign) id<QNPlayerMaskViewDelegate> mDelegate;
@property (nonatomic, assign) BOOL mIsLiving;

/** QPlayer **/
@property (nonatomic, weak) QPlayerView *mPlayer;

@property (nonatomic, strong) UISegmentedControl *mQualitySegMc;



/**
 QNPlayerMaskView 初始化方法

 @param frame QNPlayerMaskView 的位置及大小
 @param player PLPlayer 的实例
 @param isLiving 是否是直播
 @return QNPlayerMaskView 的实例子
 */


- (id)initWithFrame:(CGRect)frame player:(QPlayerView *)player isLiving:(BOOL)isLiving;

/**
 刷新音量图片的显示
 */
- (void)updateVoulmeSliderImage;


/**
 添加加载动画
 */
- (void)loadActivityIndicatorView;


/**
 停止加载动画
 */
- (void)removeActivityIndicatorView;

/**
 修改播放按钮的状态
 */
-(void)setPlayButtonState:(BOOL)state;
/**
 开启陀螺仪
 */
-(void)gyroscopeStart;
/**
 关闭陀螺仪
 */
-(void)gyroscopeEnd;

- (void)setIsVR:(BOOL)isVR;
/**
返回解码类型
 */
-(QPlayerDecoder)getDecoderType;

- (void)pushStreamButtonClick:(BOOL)isSelected;
@end
