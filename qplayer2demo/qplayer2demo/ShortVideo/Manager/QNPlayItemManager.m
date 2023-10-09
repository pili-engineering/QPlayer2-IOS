//
//  QNPlayItemManager.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/11.
//

#import "QNPlayItemManager.h"
#define TAG @"QNPlayItemManager"
@implementation QNPlayItem
-(instancetype)initWithId:(int)itemId mediaModel:(QMediaModel *)mediaModel coverUrl:(NSString *)coverUrl{
    self = [super init];
    if(self){
        self.mItemId = itemId;
        self.mMediaModel = mediaModel;
        self.mCoverUrl = coverUrl;
    }
    return self;
}
@end

@interface QNPlayItemManager()
@property (nonatomic , strong) NSMutableArray<QNPlayItem *>* mPlayItemArray;
@property (nonatomic , strong) NSMutableArray<IPlayItemAppendListener>* mPlayItemAppendListeners;
@property (nonatomic , strong) NSMutableArray<IPlayItemDeleteListener>* mPlayItemDeleteListeners;
@property (nonatomic , strong) NSMutableArray<IPlayItemReplaceListener>* mPlayItemReplaceListeners;
@property (nonatomic , strong) NSMutableArray<IPlayItemArrayRefreshListener>* mPlayItemRefreshListeners;
@end

@implementation QNPlayItemManager
-(instancetype)init{
    self = [super init];
    if(self){
        self.mPlayItemArray = [NSMutableArray array];
        self.mPlayItemAppendListeners = [NSMutableArray<IPlayItemAppendListener> array];
        self.mPlayItemDeleteListeners = [NSMutableArray<IPlayItemDeleteListener> array];
        self.mPlayItemReplaceListeners = [NSMutableArray<IPlayItemReplaceListener> array];
        self.mPlayItemRefreshListeners = [NSMutableArray<IPlayItemArrayRefreshListener> array];
    }
    return self;
}
-(BOOL)refresh:(NSArray<QNPlayItem *> *)playItemArray{
    self.mPlayItemArray = playItemArray;
    for (id<IPlayItemArrayRefreshListener> insideListener in self.mPlayItemRefreshListeners) {
        if ([insideListener respondsToSelector:@selector(onRefresh:)]) {
            [insideListener onRefresh:playItemArray];
        }
    }
    return true;
}

-(BOOL)append:(NSArray<QNPlayItem *> *)playItemArray{
    [self.mPlayItemArray addObjectsFromArray:playItemArray];
    for (id<IPlayItemAppendListener> insideListener in self.mPlayItemAppendListeners) {
        if ([insideListener respondsToSelector:@selector(onAppend:)]) {
            [insideListener onAppend:playItemArray];
        }
    }
    return true;
}

-(BOOL)deleteWithPosition:(int)position{
    if (position >= 0 && position < self.mPlayItemArray.count){
        QNPlayItem * mdeletePlayItem = self.mPlayItemArray[position];
        [self.mPlayItemArray removeObjectAtIndex:position];
        for (id<IPlayItemDeleteListener> insideListener in self.mPlayItemDeleteListeners) {
            if ([insideListener respondsToSelector:@selector(onDelete:deletePlayItem:)]) {
                [insideListener onDelete:position deletePlayItem:mdeletePlayItem];
            }
        }
        return true;
    }
    return false;
}

-(BOOL)replace:(int)position playItem:(QNPlayItem *)playItem{
    if (position >= 0 && position < self.mPlayItemArray.count){
        QNPlayItem * replacePlayItem = self.mPlayItemArray[position];
        self.mPlayItemArray[position] = playItem;
        for (id<IPlayItemReplaceListener> insideListener in self.mPlayItemReplaceListeners) {
            if ([insideListener respondsToSelector:@selector(onDelete:deletePlayItem:)]) {
                [insideListener onReplace:position oldPlayItem:replacePlayItem newPlayItem:playItem];
            }
        }
        return true;
    }
    return false;
}

-(QNPlayItem *)getOrNullByPosition:(int)position{
    if(position >= 0 && position < self.mPlayItemArray.count){
        return self.mPlayItemArray[position];
    }
    return nil;
}

-(QNPlayItem *)getOrNullById:(int)itemId{
    for (QNPlayItem *innerItem in self.mPlayItemArray) {
        if(innerItem.mItemId == itemId){
            return innerItem;
        }
    }
    return nil;
}

-(int)count{
    return (int)self.mPlayItemArray.count;
}

-(void)addPlayItemAppendListener:(id<IPlayItemAppendListener>)listener{
    if(self.mPlayItemAppendListeners)
        [self.mPlayItemAppendListeners addObject:listener];
}
-(void)removePlayItemAppendListener:(id<IPlayItemAppendListener>)listener{
    if(self.mPlayItemAppendListeners)
        [self.mPlayItemAppendListeners removeObject:listener];
}
-(void)removeAllPlayItemAppendListener{
    if(self.mPlayItemAppendListeners)
        [self.mPlayItemAppendListeners removeAllObjects];
}

-(void)addPlayItemDeleteListener:(id<IPlayItemDeleteListener>)listener{
    if(self.mPlayItemDeleteListeners)
        [self.mPlayItemDeleteListeners addObject:listener];
}
-(void)removePlayItemDeleteListener:(id<IPlayItemDeleteListener>)listener{
    if(self.mPlayItemDeleteListeners)
        [self.mPlayItemDeleteListeners removeObject:listener];
}
-(void)removeAllPlayItemDeleteListener{
    if(self.mPlayItemDeleteListeners)
        [self.mPlayItemDeleteListeners removeAllObjects];
}


-(void)addPlayItemReplaceListener:(id<IPlayItemReplaceListener>)listener{
    if(self.mPlayItemReplaceListeners)
        [self.mPlayItemReplaceListeners addObject:listener];
}
-(void)removePlayItemReplaceListener:(id<IPlayItemReplaceListener>)listener{
    if(self.mPlayItemReplaceListeners)
        [self.mPlayItemReplaceListeners removeObject:listener];
}
-(void)removeAllPlayItemReplaceListener{
    if(self.mPlayItemReplaceListeners)
        [self.mPlayItemReplaceListeners removeAllObjects];
}

-(void)addPlayItemArrayRefreshListener:(id<IPlayItemArrayRefreshListener>)listener{
    if(self.mPlayItemRefreshListeners)
        [self.mPlayItemRefreshListeners addObject:listener];
}
-(void)removePlayItemRefreshListener:(id<IPlayItemArrayRefreshListener>)listener{
    if(self.mPlayItemRefreshListeners)
        [self.mPlayItemRefreshListeners removeObject:listener];
}
-(void)removeAllPlayItemRefreshListener{
    if(self.mPlayItemRefreshListeners)
        [self.mPlayItemRefreshListeners removeAllObjects];
}
-(void)dealloc{
    NSLog(@"%@ dealloc",TAG);
}
@end


