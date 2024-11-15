//
//  QNScanViewController.m
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/7/26.
//  Copyright © 2017年 qiniu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "QNScanViewController.h"

@interface QNScanViewController ()
<
 AVCaptureMetadataOutputObjectsDelegate
>

@property (nonatomic, strong) UIView *boxView;
@property (nonatomic, strong) CALayer *scanLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, strong) NSString *scanResult;

@property (nonatomic, strong) NSTimer *timer;
@end

@implementation QNScanViewController

- (void)dealloc {
    NSLog(@"QNScanViewController - dealloc");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopScanQrCode];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startScanQrCode];
    
    UILabel *titleLab = [[UILabel alloc] init];
    titleLab.font = PL_FONT_MEDIUM(16);
    titleLab.text = @"URL 地址二维码扫描";
    titleLab.textColor = [UIColor whiteColor];
    [self.view addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(160, 30));
        make.leftMargin.mas_equalTo(PL_SCREEN_WIDTH/2 - 80);
        make.topMargin.mas_equalTo(34);
    }];
    
    UIButton *closeButton = [[UIButton alloc] init];
    closeButton.layer.cornerRadius = 17;
    closeButton.backgroundColor = PL_BUTTON_BACKGROUNDCOLOR;
    [closeButton addTarget:self action:@selector(closeButtonSelected) forControlEvents:UIControlEventTouchDown];
    [closeButton setImage:[UIImage imageNamed:@"pl_back"] forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(34, 34));
        make.leftMargin.mas_equalTo(8);
        make.topMargin.mas_equalTo(32);
    }];
}

- (void)closeButtonSelected {
    if ([self.delegate respondsToSelector:@selector(scanQRResult:isLive:)]) {
        [self.delegate scanQRResult:nil isLive:NO];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)startScanQrCode {
    NSError *error;
    
    /// 初始化捕捉设备（AVCaptureDevice），类型为AVMediaTypeVideo
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /// 用captureDevice创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    /// 创建媒体数据输出流
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    /// 实例化捕捉会话
    _captureSession = [[AVCaptureSession alloc] init];
    
    /// 将添加输入流和媒体输出流到会话
    [_captureSession addInput:input];
    [_captureSession addOutput:captureMetadataOutput];
    
    /// 创建串行队列，并加媒体输出流添加到队列当中
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    /// 设置输出媒体数据类型为QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    /// 实例化预览图层
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    /// 设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:_videoPreviewLayer];
    
    /// 设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
    
    /// 扫描框
    CGSize size = self.view.bounds.size;
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(size.width * 0.2f, (size.height - (size.width - size.width * 0.4f))/2, size.width - size.width * 0.4f, size.width - size.width * 0.4f)];
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    
    [self.view addSubview:_boxView];
    
    /// 扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 1);
    _scanLayer.backgroundColor = PL_COLOR_RGB(16, 169, 235, 1).CGColor;
    
    [_boxView.layer addSublayer:_scanLayer];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer:) userInfo:nil repeats:YES];
    [self.timer fire];
    
    /// 开始扫描
    [_captureSession startRunning];
    return YES;
}

- (void)stopScanQrCode {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
}



#pragma mark - AVCaptureMetadataOutputObjectsDelegate

// 扫描二维码后逻辑处理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    // 判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        // 判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSLog(@"input QR: %@", [metadataObj stringValue]);
            self.scanResult = [metadataObj stringValue];
            [self performSelectorOnMainThread:@selector(stopScanQrCode) withObject:nil waitUntilDone:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentSelectionAlertWithUrl:self.scanResult];
                        });
        }
    }
}

- (void)presentSelectionAlertWithUrl:(NSString *)url {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择选项"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    // 直播或点播选择
    __block NSInteger selectedIndex = 0; // 默认选择 0代表点播
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"0 代表点播，1代表直播";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    // URL展示
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"URL";
        textField.text = url;
        textField.userInteractionEnabled = NO; // 只读
    }];

    // 清晰度选择
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"清晰度填入 1080/720/540/360";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    // 取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];

    // 确定按钮
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *isLive = alertController.textFields[0].text; // 获取直播/点播选择
        NSString *quality = alertController.textFields[2].text; // 获取清晰度选择
        [self saveToJSONWithUrl:url isLive:isLive quality:quality];
        
        // 返回上一个视图
        [self.navigationController popViewControllerAnimated:YES];
        if (self.delegate && [self.delegate respondsToSelector:@selector(scanQRResult:isLive:)]) {
                               [self.delegate scanQRResult:self.scanResult isLive:isLive];
                          }
    }];
    [alertController addAction:okAction];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)saveToJSONWithUrl:(NSString *)url isLive:(NSString *)isLive quality:(NSString *)quality {
    // 创建字典以符合 JSON 结构
    NSDictionary *streamElement = @{
        @"userType": @"", // 根据需要填充
        @"urlType": @(0), // 根据需要设置
        @"url": url,
        @"quality": @(quality.intValue), // 假设 quality 是 NSInteger 类型
        @"isSelected": @(1), // 默认选择
        @"backupUrl": @"", // 如果有备用 URL，填入
        @"referer": @"" // 如果有 referer，填入
    };

    NSDictionary *data = @{
        @"isLive": @(isLive ? [isLive isEqualToString:@"直播"] : YES), // 根据选项设置
        @"streamElements": @[streamElement]
    };

    //读取json文件
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [documentsDir stringByAppendingPathComponent:@"urls.json"];

    // 检查文件是否存在
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // 如果文件不存在，创建一个空文件
        [[NSData data] writeToFile:path atomically:YES];
        
        // 拷贝原有文件内容到新创建的json文件（原有json是可读文件，所以需要先拷贝，无法直接在里面做写入）
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"urls" ofType:@"json"]; // 读取原有json路径
        NSData *sourceData = [NSData dataWithContentsOfFile:sourcePath];
        if (sourceData) {
            NSError *error;
            // 将源数据写入目标文件
            BOOL success = [sourceData writeToFile:path atomically:YES];
            if (success) {
                NSLog(@"Successfully copied content to %@", path);
            } else {
                NSLog(@"Failed to write data to file: %@", error.localizedDescription);
            }
        } else {
            NSLog(@"Failed to read source file at path: %@", sourcePath);
        }
    }
    
    // 写入二维码数据到json文件
    // 读取新的JSON 数据
    NSData *existingData = [NSData dataWithContentsOfFile:path];
    NSMutableArray *jsonArray;
    
    if (existingData) {
        NSError *error;
        jsonArray = [NSJSONSerialization JSONObjectWithData:existingData options:NSJSONReadingMutableContainers error:&error];

        if (error) {
            NSLog(@"Error reading JSON: %@", error.localizedDescription);
            return;
        }
    } else {
        // 如果文件为空，初始化一个空的可变数组
        jsonArray = [NSMutableArray array];
    }
    
    // 更新数据到数组并写回文件
    [jsonArray addObject:data]; // 将整个 data 字典添加到数组中
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray options:NSJSONWritingPrettyPrinted error:&error];

    if (jsonData) {
        [jsonData writeToFile:path atomically:YES];
        NSLog(@"Data saved to %@", path);
    } else {
        NSLog(@"Error serializing data to JSON: %@", error.localizedDescription);
    }

}


- (void)moveScanLayer:(NSTimer *)timer {
    CGRect layerFrame = _scanLayer.frame;
    if (_boxView.frame.size.height < _scanLayer.frame.origin.y) {
        layerFrame.origin.y = 0;
        _scanLayer.frame = layerFrame;
    }else{
        layerFrame.origin.y += 5;
        [UIView animateWithDuration:0.1 animations:^{
            _scanLayer.frame = layerFrame;
        }];
    }
}

@end
