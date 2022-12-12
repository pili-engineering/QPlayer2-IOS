  # 1.2.0 ReleaseNote

#### 新增能力

- demo添加短视频功能
- 新增静音播放功能
- 新增截图功能
- 新增数据构造类：QMediaModelBuilder

#### 能力变更

- 预加载（QMediaItemContext）构造方法参数变动：新增参数 QMediaModel、startPos
- 开始预加载方法参数变动：start方法不再接收任何参数
- demo 关闭扫码播放功能
- 关闭 QMediaModel 构造方法，需通过 QMediaModelBuilder 的 build 方法创建

#### 修复问题

- 优化渲染模块，暂停情况下实时更新画面效果

- 优化VR视频视角调整延迟问题

- 暂停情况下，修改色盲模式可实时响应

- seek操作不做postion的[0-duration]的修正，用户传的是多少就是多少

- 精准seek到点播视频的最后，不会再进度回弹

- 修复断网切清晰度引发崩溃

- 修复带旋转角度的视频渲染时没有处理旋转
  
- 修复m3u8带EXT-X-DISCONTINUITY 标签的资源seek异常

- 修复点播/直播立即切换清晰度异常
