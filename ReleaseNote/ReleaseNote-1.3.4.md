# 1.3.4 ReleaseNote

- #### 能力

  - 新增解码失败回调 ：QIPlayerVideoDecodeListener 

    `-(**void**)onDecodeFailed:(QPlayerContext *)context retry:(**BOOL**)retry`

  
- #### 优化

  - 优化硬解降级方案。
  

- #### 修复问题

  - 修复冷启动情况下播放第一个视频为 rtmp 时，首帧卡死，音频只能播放2-3秒，且无法恢复的问题
