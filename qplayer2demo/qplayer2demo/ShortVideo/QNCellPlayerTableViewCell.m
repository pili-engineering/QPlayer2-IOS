//
//  PLCellPlayerTableViewCell.m
//  PLPlayerKitCellDemo
//
//  Created by 冯文秀 on 2018/3/12.
//  Copyright © 2018年 Hera. All rights reserved.
//

#import "QNCellPlayerTableViewCell.h"
#import "QNPlayerShortVideoMaskView.h"

@interface QNCellPlayerTableViewCell()
<
QNPlayerShortVideoMaskViewDelegate,
QIPlayerRenderListener,
QIPlayerStateChangeListener,
QIPlayerDownloadListener,
QIPlayerFPSListener
>
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) QNPlayerShortVideoMaskView* maskView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *,UILabel *>* infoLabelDictionary;
@property (nonatomic, strong) NSDictionary<NSNumber *,NSString *>* infoNameDictionary;
@property (nonatomic, strong) UIImageView *coverImageView;

@end

@implementation QNCellPlayerTableViewCell
-(instancetype)initWithImage:(UIImage *)coverImage{
    self = [super init];
    if(self){
        
        self.contentView.backgroundColor = [UIColor blackColor];
        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _width, 0.5)];
        lineView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:lineView];
        [self addCoverImage:coverImage];
        self.infoNameDictionary = @{@(0):@"fristFrame",@(1):@"fps",@(2):@"downSpeed",@(3):@"bufferPosition",@(4):@"status"};
    }
    return self;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor blackColor];

        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _width, 0.5)];
        lineView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:lineView];
        
        self.infoNameDictionary = @{@(0):@"fristFrame",@(1):@"fps",@(2):@"downSpeed",@(3):@"bufferPosition",@(4):@"status"};
    }
    return self;
}

- (void)setPlayerView:(QNSamplePlayerWithQRenderView *)playerView{

    _playerView = playerView;
    playerView.frame = self.contentView.bounds;
    if (playerView) {
        [self.contentView insertSubview:playerView atIndex:0];
    }
    if (!self.maskView) {
        if (playerView != nil) {
            
            [self addPlayerMaskView:playerView];
            return;
        }
    }else{
        self.maskView.player = playerView;
    }
    [self addListeners];
    
}
-(void)addListeners{
    [self.playerView.controlHandler addPlayerFPSChangeListener:self];
    [self.playerView.controlHandler addPlayerStateListener:self];
    [self.playerView.controlHandler addPlayerDownloadChangeListener:self];
    [self.playerView.renderHandler addPlayerRenderListener:self];
    if(self.maskView){
        [self.maskView resumeListeners];
    }
}
-(void)addCoverImage:(UIImage *)coverImage{
    if(self.coverImageView){
        self.coverImageView.image = coverImage;
        self.coverImageView.hidden = NO;
        return;
        
    }
    self.coverImageView = [[UIImageView alloc]initWithImage:coverImage];
    self.coverImageView.backgroundColor = [UIColor clearColor];
    self.coverImageView.frame = CGRectMake(0, 92, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT-170);
    [self.contentView insertSubview:self.coverImageView atIndex:1];
}
-(void)hideCoverImage{
    if(self.coverImageView){
        self.coverImageView.hidden = YES;
    }
}
-(void)showCoverImage{
    if(self.coverImageView){
        self.coverImageView.hidden = NO;
    }
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (!self.maskView && self.playerView != nil) {
        [self addPlayerMaskView:self.playerView];
    }
    // Configure the view for the selected state
}
-(void)setState:(BOOL)state{
    if (self.maskView) {
        [self.maskView setPlayButtonState:state];
    }
    
}
-(void)removePlayerViewFromSuperView{
    [self.playerView removeFromSuperview];
    self.playerView = nil;
}
#pragma mark - 添加点播界面蒙版

- (void)addPlayerMaskView:(QNSamplePlayerWithQRenderView *)player{
    self.maskView = [[QNPlayerShortVideoMaskView alloc] initWithShortVideoFrame:CGRectMake(0, PL_SCREEN_HEIGHT-90, PL_SCREEN_WIDTH, 50) player:player isLiving:NO];
    self.maskView.delegate = self;
    self.maskView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:_maskView];
    if(self.infoLabelDictionary){
        return;
    }
    self.infoLabelDictionary = [[NSMutableDictionary alloc]init];
    for (NSNumber *tag in self.infoNameDictionary.allKeys) {
        [self setInfoLabelWithtag:tag frame:CGRectMake(0, 130 + [tag intValue] *30, 0, 30)];
    }
    [self onStateChange:nil state:self.playerView.controlHandler.currentPlayerState];
}
-(void)setInfoLabelWithtag:(NSNumber *)tag frame:(CGRect)frame{
    UILabel *infoLabel = [[UILabel alloc]initWithFrame:frame];
    infoLabel.tag = [tag intValue];
    infoLabel.backgroundColor = [UIColor grayColor];
    infoLabel.font = [UIFont systemFontOfSize:16];
    infoLabel.textColor = [UIColor whiteColor];
    [infoLabel sizeToFit];
    [self.contentView addSubview:infoLabel];
    self.infoLabelDictionary[tag] = infoLabel;
}
-(void)updateInfoLabelWithTag:(NSNumber *)tag massage:(NSString *)massage{
    UILabel *innerLabel = self.infoLabelDictionary[tag];
    NSString *titleName = self.infoNameDictionary[tag];
    innerLabel.text = [NSString stringWithFormat:@"%@:%@",titleName,massage];
    [innerLabel sizeToFit];
}
-(void)setFirstFrameTime:(long)firstFrameTime{
    [self updateInfoLabelWithTag:[self.infoNameDictionary allKeysForObject:@"fristFrame"][0] massage:[NSString stringWithFormat:@"%ld ms",(long)firstFrameTime]];
}
#pragma mark - QNPlayerShortVideoMaskViewDelegate

-(void)reOpenPlayPlayerMaskView:(QNPlayerShortVideoMaskView *)playerMaskView{
    [_maskView setPlayButtonState:YES];

}

#pragma mark - QPlayer2-core delegate
-(void)onStateChange:(QPlayerContext *)context state:(QPlayerState)state{
    NSString *statusStr = @"";
    if (state == QPLAYER_STATE_PREPARE) {
        statusStr = @"开始拉视频数据";
    } else if (state == QPLAYER_STATE_PLAYING) {
        statusStr = @"播放中";
        
    } else if (state == QPLAYER_STATE_PAUSED_RENDER) {
        statusStr = @"暂停播放";
    }else if (state == QPLAYER_STATE_STOPPED){
        statusStr = @"停止播放";
    }
    else if (state == QPLAYER_STATE_ERROR){
        statusStr = @"播放错误";
    }else if (state == QPLAYER_STATE_COMPLETED){
        statusStr = @"播放完成";
    }
    else if (state == QPLAYER_STATE_SEEKING){
        statusStr = @"正在seek";
    }
    [self updateInfoLabelWithTag:[self.infoNameDictionary allKeysForObject:@"status"][0] massage:statusStr];
}

- (void)onDownloadChanged:(QPlayerContext *)context speed:(NSInteger)downloadSpeed bufferPos:(NSInteger)bufferPos{
    [self updateInfoLabelWithTag:[self.infoNameDictionary allKeysForObject:@"downSpeed"][0] massage:[NSString stringWithFormat:@"%.2lf kb/s",downloadSpeed/1000.0]];
    [self updateInfoLabelWithTag:[self.infoNameDictionary allKeysForObject:@"bufferPosition"][0] massage:[NSString stringWithFormat:@"%ld ms",(long)bufferPos]];
}

- (void)onFPSChanged:(QPlayerContext *)context FPS:(NSInteger)fps{
    [self updateInfoLabelWithTag:[self.infoNameDictionary allKeysForObject:@"fps"][0] massage:[NSString stringWithFormat:@"%ld fps",(long)fps]];
}

- (void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    [self updateInfoLabelWithTag:[self.infoNameDictionary allKeysForObject:@"fristFrame"][0] massage:[NSString stringWithFormat:@"%ld ms",(long)elapsedTime]];
}

@end
