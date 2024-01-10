//
//  NSDataToCVPixelBufferRefHelper.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2024/1/5.
//

#import "NSDataToCVPixelBufferRefHelper.h"
#define RGBA_FILE_NAME @"rgba_data.bin"
@implementation NSDataToCVPixelBufferRefHelper

+(CVPixelBufferRef) NSDataToCVPixelBufferRef:(NSData *)pixeldata height:(int)height width:(int)width type:(QVideoType)type{
    // 创建CVPixelBufferRef
    uint32_t size = (uint32_t)pixeldata.length;
    uint8_t* pdata = (uint8_t*)pixeldata.bytes;
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status;
    if(type == QVIDEO_TYPE_YUV_420P){
        //420p
        status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8Planar, NULL, &pixelBuffer);
        
        if (status != kCVReturnSuccess) {
            NSLog(@"Unable to create pixel buffer");
        }else{

            // 锁定pixel buffer的基地址
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);

            // 获取pixel buffer的Y和UV平面基地址
            uint8_t *baseAddressY = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            uint8_t *baseAddressU = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
            uint8_t *baseAddressV = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
            memcpy(baseAddressY, pdata, width * height);
            memcpy(baseAddressU, pdata + width * height, width * height / 4);

            memcpy(baseAddressV, pdata + (width * height)*5/4, width * height / 4);

            // 解锁pixel buffer的基地址
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

        }
    }else if (type == QVIDEO_TYPE_NV12){
        //nv12
        status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuffer);
        // 锁定pixel buffer的基地址
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        // 获取 pixel buffer 的 Y 平面和 UV 平面基地址
        uint8_t *baseAddressY = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t *baseAddressUV = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

        // 将图像数据复制到 Y 平面
        memcpy(baseAddressY, pdata, width * height);

        // 将图像数据复制到 UV 平面（NV12 格式）
        size_t uvPlaneSize = width * height / 2;
        uint8_t *sourceUV = pdata + width * height;
        uint8_t *destinationUV = baseAddressUV;

        for (size_t i = 0; i < uvPlaneSize; i++) {
            *destinationUV++ = *sourceUV++;
        }
        // 解锁pixel buffer的基地址
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    }
    else if (type == QVIDEO_TYPE_RGBA){
        //rgba
        // 创建 CVPixelBuffer 的属性字典
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:RGBA_FILE_NAME];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if (!fileExists) {
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        }
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:pixeldata];
        [fileHandle closeFile];
        return nil;
            
    }else{
        return nil;
    }
    return pixelBuffer;
}
+(void)ClearDataFile{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:RGBA_FILE_NAME];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if(fileExists){
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}
@end
