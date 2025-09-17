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

### 🎵 KTV 体验

- **原唱/伴奏切换**: 支持双音轨文件的音轨切换
- **全屏模式**: 沉浸式的 KTV 包房体验
- **智能控制**: 鼠标悬停显示控制界面，自动隐藏
- **歌曲信息显示**: 实时显示当前播放状态和歌曲信息

### 📁 文件管理

- **格式支持**: 专门支持 MKV 和 MPG 格式（国内 KTV 标准格式）
- **库管理**: 可添加多个文件夹到音乐库
- **智能扫描**: 自动扫描并识别支持的文件格式
- **持久化存储**: 使用 CoreData 管理歌曲库

### 🎮 播放控制

- **队列管理**: 支持播放队列和下一首切换
- **播放状态**: 播放/暂停/停止控制
- **全屏切换**: 一键切换全屏模式

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

1. **克隆仓库**

   ```bash
   git clone <repository-url>
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

1. **添加音乐库**

   - 点击"添加文件夹"按钮
   - 选择包含 MKV/MPG 文件的文件夹
   - 应用会自动扫描并添加支持的文件

2. **播放歌曲**

   - 从歌曲列表中双击选择歌曲
   - 使用播放控制按钮控制播放
   - 点击全屏按钮进入 KTV 模式

3. **音轨切换**
   - 对于双音轨文件，使用音轨选择器切换原唱/伴奏
   - 支持实时切换，无需重新加载

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
│   │   └── Queue/              # 队列管理
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

### 重要里程碑

- **代码重构**: 将大文件拆分为模块化组件，提高可维护性
- **测试覆盖**: 添加 14 个单元测试，确保代码质量
- **格式专一**: 专注支持 MKV 和 MPG 格式，符合国内 KTV 标准
- **用户体验**: 优化全屏模式和控制交互

### 技术决策

- **SwiftUI**: 选择现代 UI 框架，提供流畅的用户体验
- **VLCKit**: 使用成熟的媒体播放框架，支持多音轨切换
- **模块化设计**: 采用单一职责原则，便于维护和扩展

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 开发指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🎯 未来规划

- [ ] 支持更多音频格式
- [ ] 添加歌词显示功能
- [ ] 实现播放历史记录
- [ ] 支持自定义主题
- [ ] 添加快捷键支持
- [ ] 实现播放列表导入/导出

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 创建 [Issue](../../issues)
- 发送邮件至 [your-email@example.com]

---

**享受你的 KTV 时光！** 🎤🎵
