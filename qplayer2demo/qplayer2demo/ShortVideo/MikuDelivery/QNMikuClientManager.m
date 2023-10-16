//
//  QNMikuClientManager.m
//  qplayer2demo
//
//  Created by Dynasty Dream on 2023/8/14.
//

#import "QNMikuClientManager.h"

#define kMiku_APPKEY @"44zpao7x7vyw9ncu"
#define kMiku_APPSALT @"916c9boaawdlnxlle6k7472asee6h7y8"
#define CACHE_PATH @""
#define CACHE_SIZE_MB 100
#define MAX_WORKERS 8
#define IS_USE_HTTP_DNS false
@interface QNMikuClientManager()
@property (nonatomic , strong)MDClient * mMikuClient;
@end
@implementation QNMikuClientManager
+ (instancetype)sharedInstance {
    static QNMikuClientManager *mikuClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mikuClient = [[QNMikuClientManager alloc] initWithQN];
    });
    return mikuClient;
}
-(instancetype)initWithQN{
    self = [super init];
    if(self){
        int cacheSizeMb = CACHE_SIZE_MB;
        int maxWorkers = MAX_WORKERS;
        BOOL httpDNS = IS_USE_HTTP_DNS;
        MDConfig *config = [[MDConfig alloc]init];
        config.workers = maxWorkers;
        config.httpDNS = httpDNS;
        config.cacheConfig = [[MDCacheConfig alloc]init];
        config.cacheConfig.cacheSize = cacheSizeMb*1024*1024;
        self.mMikuClient = [MDClient createClient:kMiku_APPKEY appSalt:kMiku_APPSALT config:config];
        if(self.mMikuClient == nil){
            NSLog(@"mikuClient create failed");
        }
        
    }
    return self;
}
-(void)uninit{
    
    if(self.mMikuClient != nil){
        
        [self.mMikuClient close];
        self.mMikuClient = nil;
    }
}
-(MDClient *)getMikuClient{
    if(self.mMikuClient == nil){
        [self initWithQN];
    }
    return self.mMikuClient;
}

@end
