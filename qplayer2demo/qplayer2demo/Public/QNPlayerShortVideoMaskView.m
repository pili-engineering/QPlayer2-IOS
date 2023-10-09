//
//  QNPlayerShortVideoMaskView.m
//  QPlayerKitDemo
//
//  Created by 王声禄 on 2022/7/25.
//  Copyright © 2022 Aaron. All rights reserved.
//

#import "QNPlayerShortVideoMaskView.h"
#import "QNButtonView.h"
@interface QNPlayerShortVideoMaskView()

@property (nonatomic, strong) QNButtonView *mButtomView;

@end

@implementation QNPlayerShortVideoMaskView

-(instancetype)initWithShortVideoFrame:(CGRect)frame player:(QNSamplePlayerWithQRenderView *)player isLiving:(BOOL)isLiving{
    self = [super initWithFrame:frame];
    if (self) {
        self.mPlayer = player;

        CGFloat playerWidth = CGRectGetWidth(frame);
        CGFloat playerHeight = CGRectGetHeight(frame);
        
        self.mButtomView = [[QNButtonView alloc]initWithShortVideoFrame:CGRectMake(8, playerHeight - 28, playerWidth - 16, 28) player:player playerFrame:frame isLiving:isLiving];
        [self addSubview:_mButtomView];
        __weak typeof(self) weakSelf = self;
        [self.mButtomView playButtonClickCallBack:^(BOOL selectedState) {
            if(weakSelf.mPlayer.controlHandler.currentPlayerState == QPLAYER_STATE_COMPLETED){
                if (weakSelf.mDelegate != nil && [weakSelf.mDelegate respondsToSelector:@selector(reOpenPlayPlayerMaskView:)]) {
                    [weakSelf.mDelegate reOpenPlayPlayerMaskView:weakSelf];
                }
            }
        }];
        
    }
    return  self;
}

-(void)resumeListeners{
    [self.mButtomView resumeListeners];
}
#pragma mark - public methods
-(void)setPlayButtonState:(BOOL)state{
    [self.mButtomView setPlayButtonState:state];
}
-(void)setMPlayer:(QPlayerContext *)player{
    _mPlayer = player;
    if (self.mButtomView) {
        self.mButtomView.mPlayer = player;
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
