  # 1.2.2 ReleaseNote

#### 新增能力

- 新增接口：resumeAudioSessionCategory 恢复播放器所需 AudioSessionCategory 配置

  ```objective-c
  [self.myPlayerView.controlHandler resumeAudioSessionCategory];
  ```

- 新增 demo SEI 解析代码

#### 修复问题

- 修复收不到七牛推流端/RTC端发送的SEI数据
- 修复创建播放器时 AudioSessionCategory 状态不符合播放器条件
