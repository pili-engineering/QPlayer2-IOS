//
//  QDataHandle.m
//  QPlayerKitDemo
//
//  Created by 孙慕 on 2022/7/11.
//  Copyright © 2022 Aaron. All rights reserved.
//

#import "QDataHandle.h"

@implementation QDataHandle

+ (QDataHandle *)shareInstance {
    
    static QDataHandle * single = nil;
    static dispatch_once_t onceToken ;
    
    dispatch_once(&onceToken, ^{
        single =[[QDataHandle alloc]init];
    }) ;
    return single;
    
}

-(instancetype)init{
    if (self = [super init]) {
        [self showPlayerConfiguration];
    }
    return self;
}


- (void)showPlayerConfiguration {
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    NSArray *dataArray = [userdafault objectForKey:@"PLPlayer_settings"];
    

    NSMutableArray *piliOptionNameArray = [NSMutableArray arrayWithArray:@[@"播放起始 (ms)",@"Decoder", @"Seek",@"Start Action",@"Render ratio",@"播放速度",@"色盲模式",@"鉴权",@"SEI",@"后台播放",@"清晰度切换",@"字幕",@"video 回调数据类型",@"切换扬声器恢复播放",@"静音"]];
    if (dataArray.count != 0 ) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSData *data in dataArray) {
            QNClassModel *classModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            for (PLConfigureModel *config in classModel.classValue) {
                [piliOptionNameArray removeObject:config.mConfiguraKey];
            }
            if(piliOptionNameArray.count!=0){
                
                NSMutableArray<PLConfigureModel*> *arrayMissing = [NSMutableArray array];
                for (PLConfigureModel *config in classModel.classValue) {
                    [arrayMissing addObject:config];
                }
                for (NSString *str in piliOptionNameArray) {
                    PLConfigureModel *configureModel = [PLConfigureModel configureModelWithDictionary:[self getDefult:str]];
                    [arrayMissing addObject:configureModel];
                }
                classModel.classValue = arrayMissing;
            }
            [array addObject:classModel];
        }
        _mPlayerConfigArray = [array copy];
        
    } else {

        NSMutableArray *piliOptionArray = [NSMutableArray array];
        for (NSString *str in piliOptionNameArray) {
            [piliOptionArray addObject:[self getDefult:str]];
        }
        
        NSDictionary *PLPlayerOptionDict = @{@"PLPlayerOption":piliOptionArray};
    
        NSArray *configureArray = @[PLPlayerOptionDict];

        // 装入属性配置数组
        _mPlayerConfigArray = [QNClassModel classArrayWithArray:configureArray];
    }
}
-(NSDictionary *)getDefult:(NSString *)key{
    if([key isEqual:@"播放起始 (ms)"]){
        return @{@"播放起始 (ms)":@[@"0.0",@"0.0"], @"default":@0};
    }else if([key isEqual:@"Decoder"]){
        return @{@"Decoder":@[@"自动",@"硬解",@"软解"], @"default":@0};
    }else if([key isEqual:@"Seek"]){
        return @{@"Seek":@[@"关键帧seek",@"精准seek"], @"default":@0};
    }else if([key isEqual:@"Start Action"]){
        return @{@"Start Action":@[@"启播播放",@"启播暂停"], @"default":@0};
    }else if([key isEqual:@"Render ratio"]){
        return @{@"Render ratio":@[@"自动",@"拉伸",@"铺满",@"16:9",@"4:3"], @"default":@0};
    }else if([key isEqual:@"播放速度"]){
        return @{@"播放速度":@[@"0.5",@"0.75",@"1.0",@"1.25",@"1.5",@"2.0"], @"default":@2};
    }else if([key isEqual:@"色盲模式"]){
        return @{@"色盲模式":@[@"无",@"红色盲",@"绿色盲",@"蓝色盲"], @"default":@0};
    }else if([key isEqual:@"鉴权"]){
        return @{@"鉴权":@[@"开启",@"关闭"], @"default":@0};
    }else if([key isEqual:@"SEI"]){
        return @{@"SEI":@[@"开启",@"关闭"], @"default":@0};
    }else if([key isEqual:@"后台播放"]){
        return @{@"后台播放":@[@"开启",@"关闭"], @"default":@0};
    }else if([key isEqual:@"清晰度切换"]){
        return @{@"清晰度切换":@[@"立即切换",@"无缝切换",@"直播立即点播无缝"], @"default":@2};
    }else if([key isEqual:@"字幕"]){
        return @{@"字幕":@[@"关闭",@"中文",@"英文"], @"default":@0};
    }else if([key isEqual:@"video 回调数据类型"]){
        return @{@"video 回调数据类型":@[@"YUV420p",@"NV12"], @"default":@0};
    }else if([key isEqual:@"切换扬声器恢复播放"]){
        return @{@"切换扬声器恢复播放":@[@"播放",@"暂停"], @"default":@0};
    }else if([key isEqual:@"镜像"]){
        return @{@"镜像":@[@"无",@"横向",@"垂直",@"横向和垂直"], @"default":@0};
    }else if([key isEqual:@"静音"]){
        return @{@"静音":@[@"关闭",@"开启"], @"default":@0};
    }else{
        NSLog(@"读取PLPlayerOption数据出错");
        return nil;
    }
}
-(void)setSelConfiguraKey:(NSString *)tittle selIndex:(int)selIndex{
    for (QNClassModel *classModel in _mPlayerConfigArray){
        for (PLConfigureModel *cMode in classModel.classValue) {
            if ([cMode.mConfiguraKey containsString:tittle]) {
                cMode.mSelectedNum = @(selIndex);
            }
        }
    }
}


- (void)saveConfigurations {
    NSMutableArray *dataArr = [NSMutableArray array];
    for (QNClassModel * classModel in _mPlayerConfigArray) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:classModel];
        [dataArr addObject:data];
    }
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    [userdafault setObject:[NSArray arrayWithArray:dataArr] forKey:@"PLPlayer_settings"];
    [userdafault synchronize];
}
-(void)setValueConfiguraKey:(NSString *)tittle selValue:(int)value{
    for (QNClassModel *classModel in _mPlayerConfigArray){
        for (PLConfigureModel *cMode in classModel.classValue) {
            if ([cMode.mConfiguraKey containsString:tittle]) {
                if (cMode.mConfiguraValue.count > 1) {
                    cMode.mConfiguraValue[0] = @(value);
                    
                }
            }
        }
    }
    
}

-(int)getConfiguraPostion{
    for (QNClassModel *classModel in _mPlayerConfigArray){
        for (PLConfigureModel *cMode in classModel.classValue) {
            if ([cMode.mConfiguraKey containsString:@"播放起始"]) {
                
                NSLog(@"起播位置-----%d",[cMode.mConfiguraValue[0] intValue]);
                
                return  [cMode.mConfiguraValue[0] intValue];
            }
        }
    }
    
    return 0;
}
-(BOOL)getAuthenticationState{
    for (QNClassModel *classModel in _mPlayerConfigArray){
        for (PLConfigureModel *cMode in classModel.classValue) {
            if ([cMode.mConfiguraKey containsString:@"鉴权"]) {
                if ([cMode.mSelectedNum intValue] == 0) {
                    return YES;
                }
                else{
                    return NO;
                }
            }
        }
    }
    return NO;
}

@end
