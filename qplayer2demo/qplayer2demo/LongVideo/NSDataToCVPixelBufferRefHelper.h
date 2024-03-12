//
//  NSDataToCVPixelBufferRefHelper.h
//  qplayer2demo
//
//  Created by Dynasty Dream on 2024/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDataToCVPixelBufferRefHelper : NSObject

+(CVPixelBufferRef) NSDataToCVPixelBufferRef:(NSData *)pixeldata height:(int)height width:(int)width type:(QVideoType)type;
+(void)ClearDataFile;
@end

NS_ASSUME_NONNULL_END
