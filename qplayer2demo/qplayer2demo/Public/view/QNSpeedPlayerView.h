//
//  SpeedPlayerView.h
//  QPlay2-wang
//
//  Created by 王声禄 on 2022/7/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SpeedUIButtonType){
    BUTTON_TYPE_PLAY_SPEED_0_5 = 0,                    //0.5倍速
    BUTTON_TYPE_PLAY_SPEED_0_75,                  //0.75倍速
    BUTTON_TYPE_PLAY_SPEED_1_0,                   //1.0倍速
    BUTTON_TYPE_PLAY_SPEED_1_25,                  //1.25倍速
    BUTTON_TYPE_PLAY_SPEED_1_5,                   //1.5倍速
    BUTTON_TYPE_PLAY_SPEED_2_0               //2.0倍速
};
@interface QNSpeedPlayerView : UIView

///初始化
///@param frame 背景view的frame
///@param color 背景view的背景颜色
-(instancetype)initWithFrame:(CGRect)frame backgroudColor:(UIColor*)color;

///添加button
///@param text button后方显示的文本
///@param frame button的frame
///@param type button的类型
///@param target selector所在类
///@param selector 响应事件
-(void)addButtonText:(NSString *)text frame:(CGRect)frame type:(SpeedUIButtonType)type target:(id)target selector:(SEL)selector;


///设置默认被选中的button
///@param type 被选中的button类型
-(void)setDefault:(SpeedUIButtonType)type;
@end

NS_ASSUME_NONNULL_END
