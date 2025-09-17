# Neobee KTV Session Player

一个专为 macOS 设计的 KTV 风格播放器，旨在为 Mac 用户提供类似国内 KTV 的娱乐体验。

## 🎤 项目背景

在 macOS 系统中，很难找到一款仿照国内 KTV 风格的应用，能够提供类似国内 KTV 的完整体验。作为一个收集了大量 KTV 格式文件的用户，我发现市面上缺乏专门针对这类需求的播放器软件。

因此，我开发了这款播放器，专门用于：

- 播放国内 KTV 常见的 MKV 和 MPG 格式文件
- 提供类似 KTV 包房的用户界面和交互体验
- 支持原唱/伴奏切换功能
- 提供流畅的全屏播放体验

## ✨ 主要特性

### 🎵 核心功能

- **原唱/伴奏切换**: 支持双音轨文件的音轨切换
- **已点歌曲管理**: 显示当前播放和队列中的歌曲，支持删除和"顶到下一首"操作
- **进度控制**: 可拖拽的播放进度条，支持精确跳转
- **全局音量**: 音量设置会保持到下一首歌
- **全屏模式**: 沉浸式的 KTV 包房体验

### 📁 文件支持

- **格式支持**: 专门支持 MKV 和 MPG 格式（国内 KTV 标准格式）
- **库管理**: 可添加多个文件夹到音乐库
- **智能扫描**: 自动扫描并识别支持的文件格式

## 🛠 技术栈

- **语言**: Swift 5
- **框架**: SwiftUI + AppKit
- **媒体播放**: VLCKit
- **数据存储**: CoreData
- **依赖管理**: CocoaPods
- **测试**: Swift Testing

## 📋 系统要求

- macOS 15.5 或更高版本
- Xcode 15 或更高版本（开发）
- 支持 Apple Silicon (M1/M2/M3) 和 Intel 处理器

## 🚀 安装和使用

### 开发环境设置

1. **获取项目**

   ```bash
   cd neobee-ktv-session/neobee-session-player
   ```

2. **安装依赖**

   ```bash
   pod install
   ```

3. **打开项目**

   ```bash
   open neobee-session-player.xcworkspace
   ```

4. **构建和运行**
   - 在 Xcode 中选择 `neobee-session-player` scheme
   - 点击运行按钮或按 `Cmd+R`

### 使用方法

1. **添加音乐库**: 点击"添加文件夹"按钮，选择包含 MKV/MPG 文件的文件夹

2. **播放歌曲**: 从歌曲列表中双击选择歌曲，使用控制按钮播放

3. **音轨切换**: 对于双音轨文件，使用音轨选择器切换原唱/伴奏

4. **队列管理**: 在"已点歌曲"区域管理播放队列，支持删除和"顶到下一首"操作

5. **快捷键**: 空格键播放/暂停，F 键全屏切换

## 🏗 项目结构

```
neobee-session-player/
├── neobee-session-player/
│   ├── App/                     # 应用入口
│   ├── Features/
│   │   ├── Player/             # 播放器相关组件
│   │   │   ├── PlayerView.swift          # 主播放器视图
│   │   │   ├── VLCPlayerController.swift # VLC 播放控制器
│   │   │   ├── PlayerControls.swift      # 播放控制组件
│   │   │   └── PlayerUIComponents.swift  # UI 组件
│   │   ├── Queue/              # 队列管理
│   │   │   ├── QueueManager.swift      # 队列管理器
│   │   │   └── QueueDisplayView.swift  # 队列显示组件
│   ├── Data/                   # 数据层
│   │   ├── LibraryScanner.swift         # 库扫描服务
│   │   └── Persistence.swift            # CoreData 配置
│   └── Views/                  # 主要视图
├── neobee-session-playerTests/ # 单元测试
└── Podfile                     # CocoaPods 依赖
```

## 🧪 测试

项目包含全面的单元测试覆盖：

```bash
# 运行所有测试
xcodebuild test -workspace neobee-session-player.xcworkspace \
                -scheme neobee-session-player \
                -destination 'platform=macOS'
```

测试覆盖：

- ✅ 队列管理逻辑
- ✅ 文件格式验证
- ✅ URL 处理逻辑
- ✅ UI 状态管理
- ✅ 音轨选择逻辑

## 📝 开发日志

### 主要特性

- **队列管理**: 已点歌曲区域，支持删除和"顶到下一首"操作
- **播放控制**: 进度条拖拽和全局音量控制
- **UI 优化**: 单行控制布局，优化视频显示区域
- **测试覆盖**: 全面的单元测试确保代码质量

## 📄 许可证

本项目为个人项目，仅供学习和个人使用。

## 📞 联系方式

如有问题或建议，欢迎通过邮件联系。

---

**享受你的 KTV 时光！** 🎤🎵
