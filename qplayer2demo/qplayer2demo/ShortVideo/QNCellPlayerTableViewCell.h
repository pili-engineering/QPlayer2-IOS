//
//  PLCellPlayerTableViewCell.h
//  PLPlayerKitCellDemo
//
//  Created by 冯文秀 on 2018/3/12.
//  Copyright © 2018年 Hera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QNSamplePlayerWithQRenderView.h"
@interface QNCellPlayerTableViewCell : UITableViewCell

//@property (nonatomic, copy) NSString *url;
//@property (nonatomic, strong) UILabel *URLLabel;
//@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, assign) BOOL state;
@property (nonatomic, weak) QNSamplePlayerWithQRenderView *playerView;
@property (nonatomic, assign) long firstFrameTime;
@property (nonatomic, strong) NSNumber *modelKey;
-(instancetype)initWithImage:(UIImage *)coverImage;
-(void)removePlayerViewFromSuperView;
-(void)showCoverImage;
-(void)hideCoverImage;

@end
