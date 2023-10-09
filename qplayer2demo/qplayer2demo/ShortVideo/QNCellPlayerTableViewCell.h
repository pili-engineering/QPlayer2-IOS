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

@property (nonatomic, assign) BOOL mState;
@property (nonatomic, weak) QNSamplePlayerWithQRenderView *mPlayerView;
@property (nonatomic, assign) long mFirstFrameTime;
@property (nonatomic, strong) NSNumber *mModelKey;
-(instancetype)initWithImage:(UIImage *)coverImage;
-(void)removePlayerViewFromSuperView;
-(void)showCoverImage;
-(void)hideCoverImage;

@end
