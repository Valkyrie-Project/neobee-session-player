# NeoBee KTV Session Player

一个专为 macOS 设计的专业 KTV 风格视频播放器，专门为拥有大量中国 KTV 资源的全球用户提供完美的唱歌体验。

## 🎤 项目背景

在 macOS 系统中，很难找到一款仿照国内 KTV 风格的应用，能够提供类似国内 KTV 的完整体验。作为一个收集了大量 KTV 格式文件的用户，我发现市面上缺乏专门针对这类需求的播放器软件。

因此，我开发了这款播放器，专门用于：

- 播放国内 KTV 常见的 MKV 和 MPG 格式文件
- 提供类似 KTV 包房的用户界面和交互体验
- 支持原唱/伴奏切换功能
- 提供流畅的全屏播放体验
- 服务全球华人社区和 KTV 爱好者

## ✨ 主要特性

### 🎵 核心功能

- **原唱/伴奏切换**: 支持双音轨文件的音轨切换
- **已点歌曲管理**: 显示当前播放和队列中的歌曲，支持删除和"顶到下一首"操作
- **全屏模式**: 沉浸式的 KTV 包房体验

### 📁 文件支持

- **格式支持**: 专门支持 MKV 和 MPG 格式（国内 KTV 标准格式）
- **库管理**: 可添加多个文件夹到音乐库

## 🛠 技术栈

- **语言**: Swift 5
- **框架**: SwiftUI + AppKit
- **媒体播放**: VLCKit
- **数据存储**: CoreData

## 📋 系统要求

- macOS 15.5 或更高版本
- Xcode 15 或更高版本（开发）
- 支持 Apple Silicon (M1/M2/M3) 和 Intel 处理器

## 🚀 安装和使用

### 开发环境设置

1. **获取项目**

   ```bash
   git clone [your-repo-url]
   cd neobee-ktv-session/neobee-session-player
   ```

2. **自动构建和分发**

   ```bash
   # 一键构建并创建DMG安装包（包含测试验证）
   ./create_dmg.sh
   ```

   脚本会自动：

   - 检查并安装 CocoaPods 依赖
   - **运行所有测试**（25 个单元测试 + 4 个 UI 测试）
   - 构建 Release 版本
   - 创建包含 VLCKit 的 DMG 安装包
   - 验证 VLCKit 正确嵌入

3. **手动开发环境设置**

   ```bash
   # 安装依赖
   pod install

   # 打开项目
   open neobee-session-player.xcworkspace
   ```

4. **运行测试**

   ```bash
   # 快速运行所有测试
   ./run_tests.sh
   ```

5. **构建和运行**
   - 在 Xcode 中选择 `neobee-session-player` scheme
   - 点击运行按钮或按 `Cmd+R`

### 使用方法

1. **添加音乐库**: 点击"添加文件夹"按钮，选择包含 MKV/MPG 文件的文件夹

2. **播放歌曲**: 从歌曲列表中双击选择歌曲，使用控制按钮播放

3. **音轨切换**: 对于双音轨文件，使用音轨选择器切换原唱/伴奏

4. **队列管理**: 在"已点歌曲"区域管理播放队列，支持删除和"顶到下一首"操作

5. **快捷键**: 空格键播放/暂停，F 键全屏切换

## 📦 分发方法

### 创建分发包

使用内置的构建脚本创建 DMG 安装包：

```bash
./create_dmg.sh
```

生成的 `NeoBee-KTV-Player.dmg` 文件包含：

- 完整的应用程序（约 38MB）
- 嵌入的 VLCKit 框架
- Applications 文件夹快捷方式
- 支持 Intel 和 Apple Silicon Mac

### 分发给朋友

1. **直接发送 DMG 文件**：将生成的 DMG 文件发送给朋友
2. **官网发布**：上传 DMG 到官网下载页面
3. **安装说明**：
   - 双击 DMG 文件
   - 将 app 拖拽到 Applications 文件夹
   - 右键点击 app → "打开"（绕过 Gatekeeper）

## 🏗 项目结构

```
neobee-session-player/
├── create_dmg.sh               # 构建和分发脚本（含测试验证）
├── run_tests.sh                # 独立测试脚本
├── configure_pre_build_tests.md # 测试配置指南
├── neobee-session-player/
│   ├── App/                     # 应用入口
│   │   └── neobee_session_playerApp.swift
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
│       ├── ContentView.swift
│       └── LibraryListView.swift
├── neobee-session-playerTests/ # 单元测试
├── Podfile                     # CocoaPods 依赖
└── README.md                   # 项目文档
```

## 🧪 测试

项目包含全面的测试覆盖，支持多种运行方式：

### 快速测试

```bash
# 使用便捷脚本运行所有测试
./run_tests.sh
```

### 手动测试

```bash
# 使用 xcodebuild 运行测试
xcodebuild test -workspace neobee-session-player.xcworkspace \
                -scheme neobee-session-player \
                -destination 'platform=macOS'
```

### 测试统计

- **单元测试**: 25 个测试，覆盖核心业务逻辑
- **UI 测试**: 4 个测试，验证用户界面和性能
- **总运行时间**: 约 30 秒

### 测试覆盖

- ✅ 队列管理逻辑
- ✅ 文件格式验证
- ✅ 播放器控制逻辑
- ✅ UI 组件状态管理
- ✅ 音轨选择逻辑
- ✅ 进度控制逻辑

### 构建前测试

- 发布构建会自动运行测试验证
- 测试失败时构建会立即停止
- 确保发布版本的质量和稳定性

## 📝 开发日志

### 主要特性

- **队列管理**: 已点歌曲区域，支持删除和"顶到下一首"操作
- **自动化构建**: 一键构建脚本，自动处理依赖和分发
- **测试保障**: 构建前自动运行测试，确保代码质量
- **多平台支持**: 支持 Intel 和 Apple Silicon Mac

## 📄 许可证

本项目为个人项目，仅供学习和个人使用。

## 📞 联系方式

如有问题或建议，欢迎通过邮件联系。

---

**享受你的 KTV 时光！** 🎤🎵
