//
//  QNMediaItemContextManager2.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/11.
//

#import "QNMediaItemContextManager.h"
#define LOAD_FORWARD_POS 1
#define LOAD_BACKWARD_POS 5
#define TAG @"QNMediaItemContextManager"
@interface QNMediaItemContextManager()
<
IPlayItemAppendListener,
IPlayItemDeleteListener,
IPlayItemReplaceListener,
IPlayItemArrayRefreshListener
>
//@property (nonatomic, strong) MDCacheUrl *mPlayItemManager;
@property (nonatomic, strong) QNPlayItemManager *mPlayItemManager;
@property (nonatomic, strong) NSString *mExternalFilesDir;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, QMediaItemContext *> *mMediaItemContextDictionary;
@property (nonatomic, assign) int mCurrentPosition;
@end
@implementation QNMediaItemContextManager

-(instancetype)init:(QNPlayItemManager *)playItemManager externalFilesDir:(NSString *)externalFilesDir{
    self = [super init];
    if(self){
        self.mPlayItemManager = playItemManager;
        self.mExternalFilesDir = externalFilesDir;
        self.mMediaItemContextDictionary = [NSMutableDictionary dictionary];
        self.mCurrentPosition = 0 ;
        
    }
    return self;
}
-(void)load : (int) itemId mediaModel: (QMediaModel *)mediaModel startPos:(long)startPos logLevel:(QLogLevel)logLevel localStorageDir :(NSString *)localStorageDir{
    QMediaItemContext *mediaItem = self.mMediaItemContextDictionary[[NSNumber numberWithInt:itemId]];
    if(mediaItem != nil){
        if(mediaItem.controlHandler.currentState == QMEDIAITEM_STATE_STOPED || mediaItem.controlHandler.currentState == QMEDIAITEM_STATE_ERROR){
            [mediaItem.controlHandler stop];
            [self.mMediaItemContextDictionary removeObjectForKey:[NSNumber numberWithInt:itemId]];
            mediaItem = nil;
            NSLog(@"%@ load::remove error or stoped mediaitem id = %d",TAG,itemId);
        }
    }
    if (mediaItem == nil){
        mediaItem = [[QMediaItemContext alloc]initItemComtextWithMediaModel:mediaModel startPos:startPos storageDir:localStorageDir logLevel:logLevel];
        [mediaItem.controlHandler start];
        self.mMediaItemContextDictionary[[NSNumber numberWithInt:itemId]] = mediaItem;
        NSLog(@"%@ load::mediaitem id = %d",TAG,itemId);
    }
}
-(void) discardMediaItemContext:(NSNumber *)itemId{
    QMediaItemContext *mediaItem = self.mMediaItemContextDictionary[itemId];
    if(mediaItem){
        [mediaItem.controlHandler stop];
        [self.mMediaItemContextDictionary removeObjectForKey:itemId];
    }
    NSLog(@"%@ discardMediaItemContext id = %@",TAG,itemId);
}

-(void)updateMediaItemContext : (int)currentPosition {
    self.mCurrentPosition = currentPosition;
    NSMutableSet<NSNumber *> *newContextIds = [NSMutableSet set];
    int start = currentPosition - LOAD_FORWARD_POS;
    int end = currentPosition -1;
    for (int i = start; i <= end; i++) {
        QNPlayItem * item = [self.mPlayItemManager getOrNullByPosition:i];
        if(item){
            [newContextIds addObject:[NSNumber numberWithInt:item.itemId]];
        }
    }
    start = currentPosition +1;
    end = currentPosition + LOAD_BACKWARD_POS;
    for (int i = start; i <= end; i++) {
        QNPlayItem * item = [self.mPlayItemManager getOrNullByPosition:i];
        if(item){
            [newContextIds addObject:[NSNumber numberWithInt:item.itemId]];
        }
    }
    NSMutableSet *addContextIdsSet = [NSMutableSet set];
    for (NSNumber * num in newContextIds) {
        if(![self.mMediaItemContextDictionary.allKeys containsObject:num]){
            [addContextIdsSet addObject:num];
        }
    }
    for (NSNumber * contextId in addContextIdsSet) {
        QNPlayItem * item = [self.mPlayItemManager getOrNullById:[contextId intValue]];
        if(item){
            [self load:item.itemId mediaModel:item.mediaModel startPos:0 logLevel:LOG_VERBOSE localStorageDir:self.mExternalFilesDir];
        }
    }
    NSLog(@"%@ add preload ids = %@",TAG,addContextIdsSet);
    NSMutableSet *discardContextIdsSet = [NSMutableSet set];
    for (NSNumber * num in self.mMediaItemContextDictionary.allKeys) {
        if(![newContextIds containsObject:num]){
            [discardContextIdsSet addObject:num];
        }
    }
    for (NSNumber * num  in discardContextIdsSet) {
        [self discardMediaItemContext:num];
    }
    NSLog(@"%@ remove preload ids = %@",TAG,discardContextIdsSet);
}

-(void)start{
    
//        MikuClientManager.init()
    [self.mPlayItemManager addPlayItemAppendListener:self];
    [self.mPlayItemManager addPlayItemDeleteListener:self];
    [self.mPlayItemManager addPlayItemReplaceListener:self];
    [self.mPlayItemManager addPlayItemArrayRefreshListener:self];
}
-(void)stop{
//    MikuClientManager.uninit()
    [self.mPlayItemManager removePlayItemAppendListener:self];
    [self.mPlayItemManager removePlayItemDeleteListener:self];
    [self.mPlayItemManager removePlayItemRefreshListener:self];
    [self.mPlayItemManager removePlayItemReplaceListener:self];
    [self discardAllMediaItemContexts];
}
-(void)discardAllMediaItemContexts{
    NSLog(@"discardAllMediaItemContexts stop");
    for (QMediaItemContext *item  in self.mMediaItemContextDictionary.allValues) {
        [item.controlHandler stop];
    }
    [self.mMediaItemContextDictionary removeAllObjects];
    self.mMediaItemContextDictionary = nil;
}
-(QMediaItemContext *)fetchMediaItemContextById:(int)itemId{
    QMediaItemContext * mediaItem = self.mMediaItemContextDictionary[[NSNumber numberWithInt:itemId]];
    [self.mMediaItemContextDictionary removeObjectForKey:[NSNumber numberWithInt:itemId]];
    
    NSLog(@"%@ rfetchMediaItemContextById id = %d",TAG,itemId);
    return mediaItem;
}

- (void)onAppend:(nonnull NSArray<QNPlayItem *> *)appendItems {
    [self updateMediaItemContext:self.mCurrentPosition];
}

- (void)onDelete:(int)position deletePlayItem:(nonnull QNPlayItem *)deletePlayItem {
    [self discardMediaItemContext:[NSNumber numberWithInt:deletePlayItem.itemId]];
    [self updateMediaItemContext:self.mCurrentPosition];
}

- (void)onReplace:(int)position oldPlayItem:(nonnull QNPlayItem *)oldPlayItem newPlayItem:(nonnull QNPlayItem *)newPlayItem {
    
    [self updateMediaItemContext:self.mCurrentPosition];
}

- (void)onRefresh:(nonnull NSArray<QNPlayItem *> *)itemArray {
    self.mCurrentPosition = 0;
    [self updateMediaItemContext:self.mCurrentPosition];
}
-(void)dealloc{
    NSLog(@"%@ dealloc",TAG);
}
@end

