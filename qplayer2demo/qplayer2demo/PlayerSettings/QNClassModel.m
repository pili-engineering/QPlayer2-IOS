//
//  QNClassModel.m
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/6/29.
//  Copyright © 2017年 0dayZh. All rights reserved.
//

#import "QNClassModel.h"

@implementation QNClassModel
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.classKey = [aDecoder decodeObjectForKey:@"classKey"];
        self.classValue = [aDecoder decodeObjectForKey:@"classValue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.classKey forKey:@"classKey"];
    [aCoder encodeObject:self.classValue forKey:@"classValue"];
}

+ (NSArray *)classArrayWithArray:(NSArray *)array {
    NSMutableArray *classArray = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        QNClassModel *classModel = [[QNClassModel alloc] init];
        classModel.classKey = dict.allKeys[0];
        NSMutableArray *configureArray = [NSMutableArray array];
        for (NSDictionary *configurDictionary in dict.allValues[0]) {
            PLConfigureModel *configureModel = [PLConfigureModel configureModelWithDictionary:configurDictionary];
            [configureArray addObject:configureModel];
        }
        classModel.classValue = [configureArray copy];
        [classArray addObject:classModel];
    }
    return [classArray copy];
}

@end

@implementation PLConfigureModel
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.mConfiguraKey = [aDecoder decodeObjectForKey:@"configuraKey"];
        self.mConfiguraValue = [aDecoder decodeObjectForKey:@"configuraValue"];
        self.mSelectedNum = [aDecoder decodeObjectForKey:@"selectedNum"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.mConfiguraKey forKey:@"configuraKey"];
    [aCoder encodeObject:self.mConfiguraValue forKey:@"configuraValue"];
    [aCoder encodeObject:self.mSelectedNum forKey:@"selectedNum"];
}

+ (PLConfigureModel *)configureModelWithDictionary:(NSDictionary *)dictionary {
    PLConfigureModel *configureModel = [[PLConfigureModel alloc] init];
    for (NSString *key in dictionary) {
        if ([key isEqualToString:@"default"]) {
            configureModel.mSelectedNum = dictionary[key];
        } else{
            configureModel.mConfiguraKey = key;
            configureModel.mConfiguraValue = [dictionary[key] mutableCopy];
        }
    }
    return configureModel;
}


@end
