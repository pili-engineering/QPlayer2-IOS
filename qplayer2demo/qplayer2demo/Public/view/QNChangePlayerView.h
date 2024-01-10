//
//  StretchingPlayerView2.h
//  QPlay2-wang
//
//  Created by 王声禄 on 2022/7/6.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, ChangeButtonType){
    BUTTON_TYPE_AUTOMATIC = 0,      //自动
    BUTTON_TYPE_STRETCHING,             //拉伸
    BUTTON_TYPE_SPREAD_OVER,             //铺满
    BUTTON_TYPE_16_9,                 //16:9
    BUTTON_TYPE_4_3,                  //4:3
    
    BUTTON_TYPE_FILTER_NONE = 100,             //无滤镜
    BUTTON_TYPE_FILTER_RED_GREEN,      //红/绿滤镜
    BUTTON_TYPE_FILTER_GREEN_RED,      //绿/红滤镜
    BUTTON_TYPE_FILTER_BLUE_YELLOW,    //蓝/黄滤镜
    
    BUTTON_TYPE_DECTOR_AUTOMATIC = 200,        //自动
    BUTTON_TYPE_DECTOR_HARD,             //硬解
    BUTTON_TYPE_DECTOR_SOFT,             //软解
    
    BUTTON_TYPE_SEEK_KEY = 300,                //关键帧seek
    BUTTON_TYPE_SEEK_ACCURATE,           //精准seek
    
    BUTTON_TYPE_ACTION_PLAY = 400,             //起播播放
    BUTTON_TYPE_ACTION_PAUSE,            //起播暂停
    
    
    BUTTON_TYPE_SEI_DATA = 500,                  //sei
    
    BUTTON_TYPE_AUTHENTICATION = 600,            //鉴权
    
    BUTTON_TYPE_BACKGROUND_PLAY = 700,            //后台播放
    
    BUTTON_TYPE_IMMEDIATELY_TRUE = 800,            //立即切换
    BUTTON_TYPE_IMMEDIATELY_FALSE,                //无缝切换
    BUTTON_TYPE_IMMEDIATELY_CUSTOM,               //直播立即切换，点播无缝立即切换
    
    
    BUTTON_TYPE_SUBTITLE_CLOSE = 900,         //关闭字幕
    BUTTON_TYPE_SUBTITLE_CHINESE,             //中文字幕
    BUTTON_TYPE_SUBTITLE_ENGLISH,              //英文字幕
    
    BUTTON_TYPE_VIDEO_DATA_YUV420P = 1000,         //YUV420p
    BUTTON_TYPE_VIDEO_DATA_NV12               //NV12
    
};
NS_ASSUME_NONNULL_BEGIN

@interface QNChangePlayerView : UIView

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
///@param selectorTag 响应事件
-(void)addButtonText:(NSString *)text frame:(CGRect)frame type:(ChangeButtonType)type target:(id)target selector:(SEL)selector selectorTag:(SEL)selectorTag;

///修改button的frame
///@param frame 修改后的frame
///@param type 需要修改哪一类的button
-(void)setButtonFrame:(CGRect)frame type:(ChangeButtonType)type;


///修改button后方显示的文本
///@param title 修改后的text
///@param type 需要修改哪一类的button
-(void)setButtonTitle:(NSString *)title type:(ChangeButtonType)type;


///修改button后方显示的未被选中文本颜色
///@param titleColor 修改后的文本颜色
-(void)setButtonNotSelectedTitleColor:(UIColor *)titleColor;

///修改button后方显示的被选中的文本颜色
///@param titleColor 修改后的文本颜色
-(void)setButtonSelectedTitleColor:(UIColor *)titleColor;

///删除已添加的button
///@param type 需要删除哪一类的button
-(void)deleteButton:(ChangeButtonType)type;


///添加/修改最上方的标题文本
///@param text 添加/修改后的text
///@param frame label的frame
///@param textColor 字体颜色
-(void)setTitleLabelText:(NSString *)text frame:(CGRect)frame textColor:(UIColor *)textColor;

///设置字体大小
///@param myfont 修改后的font
-(void)setButtonFont:(UIFont *)myfont;

///设置未被选中的图标
///@param Image 未被选中的图标
-(void)setButtonNotSelectedImage:(UIImage *)Image;


///设置被选中的图标
///@param Image 被选中的图标
-(void)setButtonSelectedImage:(UIImage *)Image;

///设置默认被选中的button
///@param type 被选中的button类型
-(void)setDefault:(ChangeButtonType)type;

//获取button是否被选择
///@param type 被选中的button类型
-(BOOL)getButtonSelected:(ChangeButtonType)type;
@end

NS_ASSUME_NONNULL_END
