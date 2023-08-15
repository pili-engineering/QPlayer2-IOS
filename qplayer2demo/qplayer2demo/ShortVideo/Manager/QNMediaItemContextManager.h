//
//  QNMediaItemContextManager2.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/11.
//

#import <Foundation/Foundation.h>
#import "QNPlayItemManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface QNMediaItemContextManager : NSObject
-(instancetype)init:(QNPlayItemManager *)playItemManager externalFilesDir:(NSString *)externalFilesDir;
-(void)start;
-(void)stop;
-(QMediaItemContext *)fetchMediaItemContextById:(int)itemId;
-(void)discardAllMediaItemContexts;
-(void)discardMediaItemContext:(NSNumber *)itemId;
-(void)updateMediaItemContext : (int)currentPosition;
@end

NS_ASSUME_NONNULL_END
