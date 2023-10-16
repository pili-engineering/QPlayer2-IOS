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
@property (nonatomic, assign) CGFloat mWidth;
@property (nonatomic, strong) QNPlayerShortVideoMaskView* mMaskView;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *,UILabel *>* mInfoLabelDictionary;
@property (nonatomic, strong) NSDictionary<NSNumber *,NSString *>* mInfoNameDictionary;
@property (nonatomic, strong) UIImageView *mCoverImageView;

@end

@implementation QNCellPlayerTableViewCell
-(instancetype)initWithImage:(UIImage *)coverImage{
    self = [super init];
    if(self){
        
        self.contentView.backgroundColor = [UIColor blackColor];
        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.mWidth, 0.5)];
        lineView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:lineView];
        [self addCoverImage:coverImage];
        self.mInfoNameDictionary = @{@(0):@"fristFrame",@(1):@"fps",@(2):@"downSpeed",@(3):@"bufferPosition",@(4):@"status"};
    }
    return self;
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor blackColor];

        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.mWidth, 0.5)];
        lineView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:lineView];
        
        self.mInfoNameDictionary = @{@(0):@"fristFrame",@(1):@"fps",@(2):@"downSpeed",@(3):@"bufferPosition",@(4):@"status"};
    }
    return self;
}

- (void)setMPlayerView:(QNSamplePlayerWithQRenderView *)playerView{

    _mPlayerView = playerView;
    playerView.frame = self.contentView.bounds;
    if (playerView) {
        [self.contentView insertSubview:playerView atIndex:0];
    }
    if (!self.mMaskView) {
        if (playerView != nil) {
            
            [self addPlayerMaskView:playerView];
        }
    }else{
        self.mMaskView.mPlayer = playerView;
    }
    [self addListeners];
    
}
-(void)addListeners{
    [self.mPlayerView.controlHandler addPlayerFPSChangeListener:self];
    [self.mPlayerView.controlHandler addPlayerStateListener:self];
    [self.mPlayerView.controlHandler addPlayerDownloadChangeListener:self];
    [self.mPlayerView.renderHandler addPlayerRenderListener:self];
    if(self.mMaskView){
        [self.mMaskView resumeListeners];
    }
}
-(void)addCoverImage:(UIImage *)coverImage{
    if(self.mCoverImageView){
        self.mCoverImageView.image = coverImage;
        self.mCoverImageView.hidden = NO;
        return;
        
    }
    self.mCoverImageView = [[UIImageView alloc]initWithImage:coverImage];
    self.mCoverImageView.backgroundColor = [UIColor clearColor];
    self.mCoverImageView.frame = CGRectMake(0, 92, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT-170);
    [self.contentView insertSubview:self.mCoverImageView atIndex:1];
}
-(void)hideCoverImage{
    if(self.mCoverImageView){
        self.mCoverImageView.hidden = YES;
    }
}
-(void)showCoverImage{
    if(self.mCoverImageView){
        self.mCoverImageView.hidden = NO;
    }
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (!self.mMaskView && self.mPlayerView != nil) {
        [self addPlayerMaskView:self.mPlayerView];
    }
    // Configure the view for the selected state
}
-(void)setMState:(BOOL)state{
    if (self.mMaskView) {
        [self.mMaskView setPlayButtonState:state];
    }
    
}
-(void)removePlayerViewFromSuperView{
    [self.mPlayerView removeFromSuperview];
    self.mPlayerView = nil;
}
#pragma mark - 添加点播界面蒙版

- (void)addPlayerMaskView:(QNSamplePlayerWithQRenderView *)player{
    self.mMaskView = [[QNPlayerShortVideoMaskView alloc] initWithShortVideoFrame:CGRectMake(0, PL_SCREEN_HEIGHT-90, PL_SCREEN_WIDTH, 50) player:player isLiving:NO];
    self.mMaskView.mDelegate = self;
    self.mMaskView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.mMaskView];
    if(self.mInfoLabelDictionary){
        return;
    }
    self.mInfoLabelDictionary = [[NSMutableDictionary alloc]init];
    for (NSNumber *tag in self.mInfoNameDictionary.allKeys) {
        [self setInfoLabelWithtag:tag frame:CGRectMake(0, 130 + [tag intValue] *30, 0, 30)];
    }
    [self onStateChange:nil state:self.mPlayerView.controlHandler.currentPlayerState];
}
-(void)setInfoLabelWithtag:(NSNumber *)tag frame:(CGRect)frame{
    UILabel *infoLabel = [[UILabel alloc]initWithFrame:frame];
    infoLabel.tag = [tag intValue];
    infoLabel.backgroundColor = [UIColor grayColor];
    infoLabel.font = [UIFont systemFontOfSize:16];
    infoLabel.textColor = [UIColor whiteColor];
    [infoLabel sizeToFit];
    [self.contentView addSubview:infoLabel];
    self.mInfoLabelDictionary[tag] = infoLabel;
}
-(void)updateInfoLabelWithTag:(NSNumber *)tag massage:(NSString *)massage{
    UILabel *innerLabel = self.mInfoLabelDictionary[tag];
    NSString *titleName = self.mInfoNameDictionary[tag];
    innerLabel.text = [NSString stringWithFormat:@"%@:%@",titleName,massage];
    [innerLabel sizeToFit];
}
-(void)setMFirstFrameTime:(long)firstFrameTime{
    [self updateInfoLabelWithTag:[self.mInfoNameDictionary allKeysForObject:@"fristFrame"][0] massage:[NSString stringWithFormat:@"%ld ms",(long)firstFrameTime]];
}
#pragma mark - QNPlayerShortVideoMaskViewDelegate

-(void)reOpenPlayPlayerMaskView:(QNPlayerShortVideoMaskView *)playerMaskView{
    [self.mMaskView setPlayButtonState:YES];

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
    [self updateInfoLabelWithTag:[self.mInfoNameDictionary allKeysForObject:@"status"][0] massage:statusStr];
}

- (void)onDownloadChanged:(QPlayerContext *)context speed:(NSInteger)downloadSpeed bufferPos:(NSInteger)bufferPos{
    [self updateInfoLabelWithTag:[self.mInfoNameDictionary allKeysForObject:@"downSpeed"][0] massage:[NSString stringWithFormat:@"%.2lf kb/s",downloadSpeed/1000.0]];
    [self updateInfoLabelWithTag:[self.mInfoNameDictionary allKeysForObject:@"bufferPosition"][0] massage:[NSString stringWithFormat:@"%ld ms",(long)bufferPos]];
}

- (void)onFPSChanged:(QPlayerContext *)context FPS:(NSInteger)fps{
    [self updateInfoLabelWithTag:[self.mInfoNameDictionary allKeysForObject:@"fps"][0] massage:[NSString stringWithFormat:@"%ld fps",(long)fps]];
}

- (void)onFirstFrameRendered:(QPlayerContext *)context elapsedTime:(NSInteger)elapsedTime{
    [self updateInfoLabelWithTag:[self.mInfoNameDictionary allKeysForObject:@"fristFrame"][0] massage:[NSString stringWithFormat:@"%ld ms",(long)elapsedTime]];
}

@end
