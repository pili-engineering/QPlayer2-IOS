# 1.4.3 ReleaseNote

- #### 能力

  - 新增设置日志等级
  
    ```objective-c
    [self.mPlayerView.controlHandler setLogLevel:LOG_INFO];
    ```
  
  - 移除 QPlayer2 音频中断逻辑。
  
    中断逻辑参考 demo 的 QNotificationCenterHelper 
  
  - 移除本地重建时间轴逻辑，时间轴默认都从0开始
  
    

- #### 优化

  - 减少progress通知次数
  - 优化丢帧逻辑

- #### 修复问题

  - 修复某些视频seek崩溃
  - 屏蔽无效渲染
  - 修复直播音画不同步问题
