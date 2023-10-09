//
//  QNSamplePlayerWithQRenderView.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/11.
//

#import "QNSamplePlayerWithQRenderView.h"
#import <qplayer2_core/QRenderView.h>
#import <qplayer2_core/QIPlayerListenerHeader.h>

@interface QNSamplePlayerWithQRenderView()<QIPlayerStateChangeListener>

@property (nonatomic,strong) QPlayerContext *mPlayerContext;
@end
@implementation QNSamplePlayerWithQRenderView


-(instancetype)initWithFrame:(CGRect)frame APPVersion:(nonnull NSString *)APPVersion localStorageDir:(nonnull NSString *)localStorageDir logLevel:(QLogLevel)logLevel{
    return [self initWithFrame:frame APPVersion:APPVersion localStorageDir:localStorageDir logLevel:logLevel authorid:nil];
}
//实际调用
-(instancetype)initWithFrame:(CGRect)frame APPVersion:(NSString *)APPVersion localStorageDir:(NSString *)localStorageDir logLevel:(QLogLevel)logLevel authorid:(NSString*)authorid {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = true;
        eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:NO],
                                          kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
        self.mPlayerContext = [[QPlayerContext alloc]initPlayerAPPVersion:APPVersion localStorageDir:localStorageDir logLevel:logLevel authorid:authorid];
        self.controlHandler = self.mPlayerContext.controlHandler;
        self.renderHandler = self.mPlayerContext.renderHandler;
        
        
        [self.mPlayerContext.controlHandler addPlayerStateListener:self];
        [self.renderHandler setRenderViewLayer:(CAEAGLLayer *)self.layer];
        
        [self.renderHandler setRenderViewFrame:CGSizeMake(self.frame.size.width * [UIScreen mainScreen].scale, self.frame.size.height * [UIScreen mainScreen].scale)];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
        // kvo 监控自己的 bounds 属性变化
        [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
        // kvo 监控自己的 contentMode 属性变化
        [self addObserver:self forKeyPath:@"contentMode" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

-(void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    if (state == QPLAYER_STATE_END) {

        self.renderHandler = nil;
        self.mPlayerContext = nil;
        self.controlHandler = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"frame"] || [keyPath isEqualToString:@"bounds"] || [keyPath isEqualToString:@"contentMode"]) {
        if([object valueForKeyPath:keyPath] != [NSNull null]) {
            //此处为获取新的frame
            if ([NSThread isMainThread]) {
                
                if (self.renderHandler) {
                    
                    [self.renderHandler setRenderViewFrame:CGSizeMake(self.frame.size.width * [UIScreen mainScreen].scale, self.frame.size.height * [UIScreen mainScreen].scale)];
                }
            } else {
                
                __weak typeof(self)wself = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (wself.renderHandler) {
                        
                        [wself.renderHandler setRenderViewFrame:CGSizeMake(wself.frame.size.width * [UIScreen mainScreen].scale, wself.frame.size.height * [UIScreen mainScreen].scale)];
                    }
                    
                });
            }
        }
    }
}

-(void)dealloc{
    
    [self removeObserver:self forKeyPath:@"frame"];
    [self removeObserver:self forKeyPath:@"bounds"];
    [self removeObserver:self forKeyPath:@"contentMode"];
}
@end
