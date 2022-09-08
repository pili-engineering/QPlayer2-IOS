# 1.0.2 ReleaseNote
#### 接口变动

- 渲染视图（RenderView）中播放器和渲染视图绑定接口改动。由绑定RenderHandler改为绑定PlayerContext

  `[renderView attachRenderHandler:qplayerContext.renderHandler];`
  
  改为 
  
  ` [renderView attachPlayerContext:qplayerContext];`
  
  

#### 修复问题

- 修复内存泄漏

