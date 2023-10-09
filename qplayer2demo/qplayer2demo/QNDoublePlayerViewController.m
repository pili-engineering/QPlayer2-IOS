//
//  QNDoublePlayerViewController.m
//  qplayer2demo
//
//  Created by 李林峰 on 2023/2/14.
//

#import "QNDoublePlayerViewController.h"
#import "QNPlayerShortVideoMaskView.h"
#import "QNToastView.h"

#import "QDataHandle.h"

static BOOL playerSwitchFlag = true;
static NSString *status[] = {
    @"Unknow",
    @"Preparing",
    @"Ready",
    @"Open",
    @"Caching",
    @"Playing",
    @"Paused",
    @"Stopped",
    @"Error",
    @"Reconnecting",
    @"Completed"
};

@interface QNDoublePlayerViewController()
<
QIPlayerStateChangeListener,
QIPlayerProgressListener,
QIPlayerRenderListener,
QIMediaItemStateChangeListener,
QIMediaItemCommandNotAllowListener
>

@property (nonatomic, strong) QPlayerContext *mPlayer;
@property (nonatomic, strong) QPlayerContext * mPlayerOther;
@property (nonatomic, strong) QRenderView *mRenderView;
@property (nonatomic, strong) QRenderView *mOtherRenderView;

@property (nonatomic, assign) CGFloat mTopSpace;

//交换player
@property (nonatomic, strong) QMediaModelBuilder *mModleBuilderMain;
@property (nonatomic, strong) QMediaModelBuilder *mModelBuilderOther;



@end

@implementation QNDoublePlayerViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self configView];
    [self setupPlayer: _mPlayerConfigArray];
    [self setupPlayer_other: _mPlayerConfigArray];
    
    [self makeSwitch];
}


- (void)dealloc {
    NSLog(@"QNDoublePlayerViewController dealloc");
}

- (void)viewWillDisAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mPlayer.controlHandler stop];
    [self.mPlayerOther.controlHandler stop];

    [self.mPlayer.controlHandler playerRelease];
    [self.mPlayerOther.controlHandler playerRelease];
    self.mRenderView = nil;
    self.mOtherRenderView = nil;
    self.mPlayer = nil;
    self.mPlayerOther = nil;
}

#pragma mark - configPlayerANDconfigDefaults
- (void)configView {
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc]init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor =PL_SEGMENT_BG_COLOR;
        [self.navigationController.navigationBar setScrollEdgeAppearance:appearance];
        [self.navigationController.navigationBar setStandardAppearance:appearance];
        
    } else {
        self.navigationController.navigationBar.barTintColor = PL_SEGMENT_BG_COLOR;
    }
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 6, 34, 34)];
    UIImage *image = [UIImage imageNamed:@"pl_back"];
    if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0f) {
        image = [self originImage:image scaleToSize:CGSizeMake(34, 34)];
    }
    [backButton setImage:image forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(getBack) forControlEvents:UIControlEventTouchDown];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:backButton];
    
    //configDefaults
    _mPlayerConfigArray = [QDataHandle shareInstance].mPlayerConfigArray;
    
}

//
#pragma mark setup
- (void)setupPlayer:(NSArray<QNClassModel*>*)models {
    if (PL_HAS_NOTCH) {
        _mTopSpace = 88;
    } else {
        _mTopSpace = 64;
    }
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _mRenderView = [[QRenderView alloc]initWithFrame:CGRectMake(0, _mTopSpace, PLAYER_PORTRAIT_WIDTH, PL_SCREEN_HEIGHT)];
    
    [self.view addSubview:_mRenderView];
    
    QPlayerContext *player = [[QPlayerContext alloc]initPlayerAPPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];

    self.mPlayer = player;
    [self.mRenderView attachPlayerContext:self.mPlayer];
    
    _mModleBuilderMain = [[QMediaModelBuilder alloc] initWithIsLive:NO];
        [_mModleBuilderMain addStreamElementWithUserType:@""
                                 urlType:QURL_TYPE_QAUDIO_AND_VIDEO                      //资源的类型，这里的url对应的资源是音视频
                                 url:@"http://demo-videos.qnsdk.com/shortvideo/nike.mp4"     //播放地址
                                 quality:1080                                            //清晰度数值标记为1080
                                 isSelected:YES                                          
                                 backupUrl:@""                                            //备用地址
                                 referer:@""                                              //http/https 协议的地址 支持该属性
                                 renderType:QPLAYER_RENDER_TYPE_PLANE];
    QMediaModel *model = [_mModleBuilderMain build];
    [self.mPlayer.controlHandler playMediaModel:model startPos:0];
}
- (void)setupPlayer_other:(NSArray<QNClassModel*>*)models {
    if (PL_HAS_NOTCH) {
        _mTopSpace = 88;
    } else {
        _mTopSpace = 64;
    }
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _mOtherRenderView = [[QRenderView alloc]initWithFrame:CGRectMake(0, PL_SCREEN_HEIGHT-(PL_SCREEN_HEIGHT - _mTopSpace)/2, PL_SCREEN_WIDTH, (PL_SCREEN_HEIGHT - _mTopSpace)/2)];
    [self.view addSubview:_mOtherRenderView];
    QPlayerContext *player_other = [[QPlayerContext alloc]initPlayerAPPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];
    self.mPlayerOther = player_other;
    [self.mOtherRenderView attachPlayerContext:self.mPlayerOther];
    _mModelBuilderOther = [[QMediaModelBuilder alloc] initWithIsLive:NO];
        [_mModelBuilderOther addStreamElementWithUserType:@""
                                 urlType:QURL_TYPE_QAUDIO_AND_VIDEO
                                 url:@"http://demo-videos.qnsdk.com/shortvideo/桃花.mp4"
                                 quality:1080
                                 isSelected:YES
                                 backupUrl:@""
                                 referer:@""
                                 renderType:QPLAYER_RENDER_TYPE_PLANE];

    QMediaModel *model = [_mModelBuilderOther build];
    [self.mPlayerOther.controlHandler playMediaModel:model startPos:0];
    
}
- (void)getBack {
    [self.mPlayer.controlHandler stop];
    [self.mPlayerOther.controlHandler stop];
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIImage *)originImage:(UIImage *)image scaleToSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}


#pragma mark -function of switch

- (void)makeSwitch {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swithActionPlayer)];
    UITapGestureRecognizer *tapGesture_other = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swithActionPlayer)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    tapGesture_other.numberOfTapsRequired = 1;
    tapGesture_other.cancelsTouchesInView = NO;
    [_mOtherRenderView addGestureRecognizer:tapGesture];
    [_mRenderView addGestureRecognizer:tapGesture_other];

    
}

//交换player
- (void)swithActionPlayer {
    [self.mRenderView removeFromSuperview];
    [self.mOtherRenderView removeFromSuperview];
    if(playerSwitchFlag){
        [self.view addSubview:self.mOtherRenderView];
        [self.view addSubview:self.mRenderView];
        playerSwitchFlag = false;
    }else{
        [self.view addSubview:self.mRenderView];
        [self.view addSubview:self.mOtherRenderView];
        playerSwitchFlag = true;
    }

}

@end
