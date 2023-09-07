//
//  QNPlayItemManager.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/11.
//

#import <Foundation/Foundation.h>
#import <qplayer2_core/qplayer2_core.h>
NS_ASSUME_NONNULL_BEGIN

@interface QNPlayItem : NSObject
@property (nonatomic , assign) int itemId;
@property (nonatomic , strong) QMediaModel * mediaModel;
@property (nonatomic , strong) NSString * coverUrl;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)new NS_UNAVAILABLE;

-(instancetype)initWithId:(int)itemId mediaModel:(QMediaModel *)mediaModel coverUrl:(NSString *)coverUrl;
@end

@protocol IPlayItemArrayRefreshListener <NSObject>

@required
-(void)onRefresh: (NSArray <QNPlayItem *> *)itemArray;
@end


@protocol IPlayItemAppendListener <NSObject>

@required
-(void)onAppend:(NSArray <QNPlayItem *> *)appendItems;
@end


@protocol IPlayItemDeleteListener <NSObject>

@required
-(void)onDelete:(int)position  deletePlayItem:(QNPlayItem *)deletePlayItem;
@end


@protocol IPlayItemReplaceListener <NSObject>

@required
-(void)onReplace:(int)position oldPlayItem: (QNPlayItem *) oldPlayItem newPlayItem: (QNPlayItem *) newPlayItem;
@end

@interface QNPlayItemManager : NSObject

-(instancetype)init;

-(BOOL)refresh:(NSArray<QNPlayItem *> *)playItemArray;

-(BOOL)append:(NSArray<QNPlayItem *> *)playItemArray;

-(BOOL)deleteWithPosition:(int)position;

-(BOOL)replace:(int)position playItem:(QNPlayItem *)playItem;

-(QNPlayItem *)getOrNullByPosition:(int)position;

-(QNPlayItem *)getOrNullById:(int)itemId;

-(int)count;

-(void)addPlayItemAppendListener:(id<IPlayItemAppendListener>)listener;

-(void)removePlayItemAppendListener:(id<IPlayItemAppendListener>)listener;

-(void)removeAllPlayItemAppendListener;

-(void)addPlayItemDeleteListener:(id<IPlayItemDeleteListener>)listener;

-(void)removePlayItemDeleteListener:(id<IPlayItemDeleteListener>)listener;

-(void)removeAllPlayItemDeleteListener;

-(void)addPlayItemReplaceListener:(id<IPlayItemReplaceListener>)listener;

-(void)removePlayItemReplaceListener:(id<IPlayItemReplaceListener>)listener;

-(void)removeAllPlayItemReplaceListener;

-(void)addPlayItemArrayRefreshListener:(id<IPlayItemArrayRefreshListener>)listener;

-(void)removePlayItemRefreshListener:(id<IPlayItemArrayRefreshListener>)listener;

-(void)removeAllPlayItemRefreshListener;

@end

NS_ASSUME_NONNULL_END
