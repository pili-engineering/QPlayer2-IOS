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
    
    int inner_width = 0;
    int inner_height = 0;
    if (width*1.0 / height*1.0 != 16.0/9 || width*1.0 / height*1.0 != 1.0 || width*1.0 / height*1.0 != 4.0/3 || width%32 != 0 || height%32 != 0 ) {
        inner_width = 1920;
        inner_height = 1080;
    }else{
        inner_width = width;
        inner_height = height;
    }
    if(type == QVIDEO_TYPE_YUV_420P){
        //420p
        status = CVPixelBufferCreate(kCFAllocatorDefault, inner_width, inner_height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuffer);
        
        
        if (status != kCVReturnSuccess) {
            NSLog(@"Unable to create pixel buffer");
        }else{
            
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            unsigned char *yDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
            for (int i = 0, k = 0; i < inner_height; i++) {
                for (int j = 0; j< inner_width; j++) {
                    if (inner_width > width && j >= width) {
                        if (i >= height) {
                            yDestPlane[k++] = pdata[height*width];
                            continue;
                        }
                        yDestPlane[k++] = pdata[i*width + width];
                        continue;
                    }
                    if (inner_height > height && i >= height) {
                        
                        yDestPlane[k++] = pdata[height * width];
                        continue;
                    }
                    yDestPlane[k++] = pdata[i*width + j];
                }
            }
            unsigned char *uvDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
            for (int i = 0, k = 0; i < inner_height / 2; i++) {
                for (int j = 0; j< inner_width / 2; j ++) {
                    if (inner_width > width && j >= width/2) {
                        if (i > height/2) {
                            
                            uvDestPlane[k++] = pdata[height *width/4  + width * height];
                            uvDestPlane[k++] = pdata[height *width/4  + width * height * 5 / 4];
                        }else{
                            uvDestPlane[k++] = pdata[i *width/2 + width/2 + width * height];
                            uvDestPlane[k++] = pdata[i *width/2 + width/2 + width * height * 5 / 4];
                            
                        }
                        continue;
                    }
                    if (inner_height > height && i >= height/2) {
                        
                        uvDestPlane[k++] = pdata[height *width/4 + width * height];
                        uvDestPlane[k++] = pdata[height *width/4 + width * height * 5 / 4];
                        continue;
                    }
                    uvDestPlane[k++] = pdata[i *width/2 + j + width * height];
                    uvDestPlane[k++] = pdata[i *width/2 + j + width * height * 5 / 4];
                }
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

        }
    }else if (type == QVIDEO_TYPE_NV12){
        //nv12
        status = CVPixelBufferCreate(kCFAllocatorDefault, inner_width, inner_height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        unsigned char *yDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        for (int i = 0, k = 0; i < inner_height; i++) {
            for (int j = 0; j< inner_width; j++) {
                if (inner_width > width && j >= width) {
                    if (i >= height) {
                        yDestPlane[k++] = pdata[height*width];
                        continue;
                    }
                    yDestPlane[k++] = pdata[i*width + width];
                    continue;
                }
                if (inner_height > height && i >= height) {
                    
                    yDestPlane[k++] = pdata[height * width];
                    continue;
                }
                yDestPlane[k++] = pdata[i*width + j];
            }
        }
        unsigned char *uvDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        for (int i = 0, k = 0; i < inner_height/2; i++) {
            for (int j = 0; j< inner_width; j ++) {
                if (inner_width > width && j >= width) {
                    if (i > height/2) {
                        uvDestPlane[k++] = pdata[height *width/2  + width * height];
                    }else{
                        uvDestPlane[k++] = pdata[i *width + width + width * height];
                    }
                    continue;
                }
                if (inner_height > height && i >= height/2) {
                    
                    uvDestPlane[k++] = pdata[height *width/2 + width * height];
                    continue;
                }
                uvDestPlane[k++] = pdata[i *width + j + width * height];
            }
        }
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
