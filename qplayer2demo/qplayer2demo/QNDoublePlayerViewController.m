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

@property (nonatomic, strong) QPlayerContext *player;
@property (nonatomic, strong) QPlayerContext * player_other;
@property (nonatomic, strong) QRenderView *myRenderView;
@property (nonatomic, strong) QRenderView *otherRenderView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) CGFloat topSpace;
@property (nonatomic, strong) QNToastView *toastView;

//交换player
@property (nonatomic, strong) QMediaModelBuilder *modleBuilder_main;
@property (nonatomic, strong) QMediaModelBuilder *modelBuilder_other;
//@property (nonatomic, assign, getter=true) Boolean *PlayerSwitchFlag;



@end

@implementation QNDoublePlayerViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self configView];
    [self setupPlayer: _playerConfigArray];
    [self setupPlayer_other: _playerConfigArray];
    
    [self makeSwitch];
}


- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)viewWillDisAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.player.controlHandler stop];
    [self.player_other.controlHandler stop];

    _toastView = nil;
    [self.player.controlHandler playerRelease];
    self.myRenderView = nil;
    self.otherRenderView = nil;
    self.player = nil;
    self.player_other = nil;
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
    _playerConfigArray = [QDataHandle shareInstance].playerConfigArray;
    
}

//
#pragma mark setup
- (void)setupPlayer:(NSArray<QNClassModel*>*)models {
    if (PL_HAS_NOTCH) {
        _topSpace = 88;
    } else {
        _topSpace = 64;
    }
    NSMutableArray *configs = [NSMutableArray array];
    
    if (models) {
        configs = [models mutableCopy];
    } else {
        NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
        NSArray *dataArray = [userdafault objectForKey:@"PLPlayer_settings"];
        if (dataArray.count != 0 ) {
            for (NSData *data in dataArray) {
                QNClassModel *classModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [configs addObject:classModel];
            }
        }
    }
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    _myRenderView = [[QRenderView alloc]initWithFrame:CGRectMake(0, _topSpace, PLAYER_PORTRAIT_WIDTH, PL_SCREEN_HEIGHT)];
    
    [self.view addSubview:_myRenderView];
    
    QPlayerContext *player = [[QPlayerContext alloc]initPlayerAPPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];

    self.player = player;
    [self.myRenderView attachPlayerContext:self.player];
    
    _modleBuilder_main = [[QMediaModelBuilder alloc] initWithIsLive:NO];
        [_modleBuilder_main addStreamElementWithUserType:@""
                                 urlType:QURL_TYPE_QAUDIO_AND_VIDEO                      //资源的类型，这里的url对应的资源是音视频
                                 url:@"http://demo-videos.qnsdk.com/shortvideo/nike.mp4"     //播放地址
                                 quality:1080                                            //清晰度数值标记为1080
                                 isSelected:YES                                          
                                 backupUrl:@""                                            //备用地址
                                 referer:@""                                              //http/https 协议的地址 支持该属性
                                 renderType:QPLAYER_RENDER_TYPE_PLANE];
    for (QNClassModel* model in configs) {
        for (PLConfigureModel* configModel in model.classValue) {
            if ([model.classKey isEqualToString:@"PLPlayerOption"]) {
                [self configurePlayerWithConfigureModel:configModel classModel:model isMain:true];
            }
        }
    }
    QMediaModel *model = [_modleBuilder_main build];
    [self.player.controlHandler playMediaModel:model startPos:0];
    


}
- (void)setupPlayer_other:(NSArray<QNClassModel*>*)models {
    if (PL_HAS_NOTCH) {
        _topSpace = 88;
    } else {
        _topSpace = 64;
    }
    NSMutableArray *configs = [NSMutableArray array];
    
    if (models) {
        configs = [models mutableCopy];
    } else {
        NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
        NSArray *dataArray = [userdafault objectForKey:@"PLPlayer_settings"];
        if (dataArray.count != 0 ) {
            for (NSData *data in dataArray) {
                QNClassModel *classModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [configs addObject:classModel];
            }
        }
    }
    
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _otherRenderView = [[QRenderView alloc]initWithFrame:CGRectMake(0, PL_SCREEN_HEIGHT-350, PL_SCREEN_WIDTH, PL_SCREEN_WIDTH)];
    [self.view addSubview:_otherRenderView];
    QPlayerContext *player_other = [[QPlayerContext alloc]initPlayerAPPVersion:@"" localStorageDir:documentsDir logLevel:LOG_VERBOSE];
    self.player_other = player_other;
    [self.otherRenderView attachPlayerContext:self.player_other];
    _modelBuilder_other = [[QMediaModelBuilder alloc] initWithIsLive:NO];
        [_modelBuilder_other addStreamElementWithUserType:@""
                                 urlType:QURL_TYPE_QAUDIO_AND_VIDEO
                                 url:@"http://demo-videos.qnsdk.com/shortvideo/桃花.mp4"
                                 quality:1080
                                 isSelected:YES
                                 backupUrl:@""
                                 referer:@""
                                 renderType:QPLAYER_RENDER_TYPE_PLANE];
    for (QNClassModel* model in configs) {
        for (PLConfigureModel* configModel in model.classValue) {
            if ([model.classKey isEqualToString:@"PLPlayerOption"]) {
                [self configurePlayerWithConfigureModel:configModel classModel:model isMain:false];;
            }
        }
    }
    QMediaModel *model = [_modelBuilder_other build];
    [self.player_other.controlHandler playMediaModel:model startPos:0];
    
}
- (void)getBack {
    [self.player.controlHandler stop];
    [self.player_other.controlHandler stop];
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
    UITapGestureRecognizer *tapGesture_other = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(swithActionPlayer_other)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.cancelsTouchesInView = NO;
    tapGesture_other.numberOfTapsRequired = 1;
    tapGesture_other.cancelsTouchesInView = NO;
    [_otherRenderView addGestureRecognizer:tapGesture];
    [_myRenderView addGestureRecognizer:tapGesture_other];
}
//交换rendview
- (void)switchAction {
    BOOL isPlaying_player = (_player.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    if(isPlaying_player) {
        [_player.controlHandler pauseRender];
        [_player_other.controlHandler pauseRender];
    }
    _myRenderView.frame = CGRectMake(0, _topSpace, PLAYER_PORTRAIT_WIDTH, PL_SCREEN_HEIGHT);
    _otherRenderView.frame = CGRectMake(0, _topSpace, PLAYER_PORTRAIT_WIDTH, PL_SCREEN_HEIGHT);
    
    [_player_other.controlHandler resumeRender];
    [_player.controlHandler resumeRender];
    
}

//交换player
- (void)swithActionPlayer {
    BOOL isPlaying_player = (_player.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    BOOL isPlaying_player_other = (_player_other.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    
    BOOL bothPlaying = (isPlaying_player && isPlaying_player_other);
    BOOL onlyPlayerplaying = (isPlaying_player && !isPlaying_player_other);
    BOOL onlyPlayerOtherplaying = (!isPlaying_player && isPlaying_player_other);
    
    if(bothPlaying) {
        if(playerSwitchFlag) {
            [self.otherRenderView attachPlayerContext:self.player];
            [self.myRenderView attachPlayerContext:self.player_other];
            playerSwitchFlag = false;
        } else {
            [self.otherRenderView attachPlayerContext:self.player_other];
            [self.myRenderView attachPlayerContext:self.player];
            playerSwitchFlag = true;
        }
    } else if(onlyPlayerplaying) {
        [_player.controlHandler resumeRender];
    } else if(onlyPlayerOtherplaying) {
        [_player_other.controlHandler resumeRender];
    } else {
        [self switchAction];
    }
}
- (void)swithActionPlayer_other {
    BOOL isPlaying_player = (_player.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    BOOL isPlaying_player_other = (_player_other.controlHandler.currentPlayerState == QPLAYER_STATE_PLAYING);
    
    BOOL bothPlaying = (isPlaying_player && isPlaying_player_other);
    BOOL onlyPlayerplaying = (isPlaying_player && !isPlaying_player_other);
    BOOL onlyPlayerOtherplaying = (!isPlaying_player && isPlaying_player_other);
    
    if(bothPlaying) {
        if(playerSwitchFlag) {
            [self.otherRenderView attachPlayerContext:self.player];
            [self.myRenderView attachPlayerContext:self.player_other];
            playerSwitchFlag = false;
        } else {
            [self.otherRenderView attachPlayerContext:self.player_other];
            [self.myRenderView attachPlayerContext:self.player];
            playerSwitchFlag = true;
        }
    } else if(onlyPlayerplaying) {
        [_player.controlHandler resumeRender];
    } else if(onlyPlayerOtherplaying) {
        [_player_other.controlHandler resumeRender];
    } else {
        [self switchAction];
    }
}

#pragma mark - PLPlayerSettingsVcDelegate


- (void)configurePlayerWithConfigureModel:(PLConfigureModel *)configureModel classModel:(QNClassModel *)classModel isMain:(BOOL)isMain {
    NSInteger index = [configureModel.selectedNum integerValue];
    
    if ([classModel.classKey isEqualToString:@"PLPlayerOption"]) {
        if ([configureModel.configuraKey containsString:@"播放速度"]) {
            if(isMain) {
                [self.player.controlHandler setSpeed:[configureModel.configuraValue[index] floatValue]];
            } else {
                [self.player_other.controlHandler setSpeed:[configureModel.configuraValue[index] floatValue]];
            }
            
        }

        if ([configureModel.configuraKey containsString:@"播放起始"]){

        } else if ([configureModel.configuraKey containsString:@"Decoder"]) {
            [self.player.controlHandler setDecoderType:(QPlayerDecoder)index];
            
            
        } else if ([configureModel.configuraKey containsString:@"Seek"]) {
            [self.player.controlHandler  setSeekMode:index];

        } else if ([configureModel.configuraKey containsString:@"Start Action"]) {
            [self.player.controlHandler setStartAction:(QPlayerStart)index];
            
        } else if ([configureModel.configuraKey containsString:@"Render ratio"]) {
            if(isMain) {
                [self.player.renderHandler setRenderRatio:(QPlayerRenderRatio)(index + 1)];
            } else {
                [self.player_other.renderHandler setRenderRatio:(QPlayerRenderRatio)(index + 1)];
            }
            
        } else if ([configureModel.configuraKey containsString:@"色盲模式"]) {
            [self.player.renderHandler setBlindType:(QPlayerBlind)index];
        }
        else if ([configureModel.configuraKey containsString:@"SEI"]) {
            if (index == 0) {
                
                [self.player.controlHandler setSEIEnable:YES];
            }else{
                [self.player.controlHandler setSEIEnable:NO];
            }
        }
        else if ([configureModel.configuraKey containsString:@"鉴权"]) {
            if (index == 0) {
                [self.player.controlHandler forceAuthenticationFromNetwork];
            }
        }
        else if ([configureModel.configuraKey containsString:@"后台播放"]){
            if (index == 0) {
                [self.player.controlHandler setBackgroundPlayEnable:YES];
            }
            else{
                [self.player.controlHandler setBackgroundPlayEnable:NO];
            }
        }
        else if ([configureModel.configuraKey containsString:@"清晰度切换"]){
//            _immediatelyType =(int)index;
        }
        else if ([configureModel.configuraKey containsString:@"字幕"]){
            [self.player.controlHandler setSubtitleEnable:index==0?NO:YES];
            if(index == 1 ){
                if(![self.player.controlHandler.subtitleName isEqual:@"中文"]){
                    [self.player.controlHandler setSubtitle:@"中文"];
                }
            }
            else if (index == 2){
                if(![self.player.controlHandler.subtitleName isEqual:@"英文"]){
                    [self.player.controlHandler setSubtitle:@"英文"];
                }
            }
        }
    }
}

@end
