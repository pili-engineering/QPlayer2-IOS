//
//  QNToastView.m
//  QPlayerKitDemo
//
//  Created by 王声禄 on 2022/7/27.
//  Copyright © 2022 Aaron. All rights reserved.
//

#import "QNToastView.h"
#include <pthread.h>
#import "ShowMassageView.h"
@implementation QNToastView{
   __block NSMutableArray *mMessageArray;
   
}
static pthread_rwlock_t sWPlock;
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        mMessageArray = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
        pthread_rwlock_init(&sWPlock,NULL);
        self.userInteractionEnabled = NO;
        self.layer.zPosition = MAXFLOAT;
    }
    return self;
}
-(void)addText:(NSString *)str{
    [self addView:str];
}

-(void)addDecoderType:(QPlayerDecoder)type{
    switch (type) {
        case QPLAYER_DECODER_SETTING_AUTO:
            [self addView:@"解码方式：自动"];
            break;
        case QPLAYER_DECODER_SETTING_HARDWARE_PRIORITY:
            [self addView:@"解码方式：硬解"];
            break;
        case QPLAYER_DECODER_SETTING_SOFT_PRIORITY:
            [self addView:@"解码方式：软解"];
            break;
            
        default:
            [self addView:@"解码方式：NULL"];
            break;
    }
}
-(void)addView:(NSString *)str{

    ShowMassageView *showView;
    if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight ||
    [UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) {
        showView = [[ShowMassageView alloc]initWithFrame:CGRectMake(0, self.frame.size.height - 40, self.frame.size.width, 30) Massage:str];
    } else {
        showView = [[ShowMassageView alloc]initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 30) Massage:str];
    }
    [self addSubview:showView];
    pthread_rwlock_wrlock(&sWPlock);
    for (ShowMassageView *view in mMessageArray) {
        view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - 40, view.frame.size.width, view.frame.size.height);
    }
    [mMessageArray addObject:showView];
    pthread_rwlock_unlock(&sWPlock);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        sleep(3);
        dispatch_async(dispatch_get_main_queue(), ^{
            [showView removeFromSuperview];
            pthread_rwlock_wrlock(&sWPlock);
            [self->mMessageArray removeObject:showView];
            pthread_rwlock_unlock(&sWPlock);
        });
    });
}
-(void)dealloc{
    
    [mMessageArray removeAllObjects];
    mMessageArray = nil;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
