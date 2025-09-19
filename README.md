# NeoBee KTV Session Player

一款专为 macOS 设计的 KTV 风格视频播放器，专门为拥有大量中国 KTV 资源的用户提供完美的唱歌体验。

## 项目背景

在 macOS 系统中，很难找到一款仿照国内 KTV 风格的应用，能够提供类似国内 KTV 的完整体验。因此开发了这款播放器，专门用于：

- 播放国内 KTV 常见的 MKV 和 MPG 格式文件
- 提供类似 KTV 包房的用户界面和交互体验
- 支持原唱/伴奏切换功能
- 提供流畅的全屏播放体验

## 功能特性

- **双音轨支持**: 原唱/伴奏切换
- **KTV 风格界面**: 全屏播放体验
- **播放队列管理**: 添加、删除和排序歌曲
- **格式支持**: MKV 和 MPG 文件
- **音乐库管理**: 扫描和管理多个文件夹

## 系统要求

- macOS 15.5+
- Xcode 15+（开发用）

## 技术栈

- Swift 5 + SwiftUI
- VLCKit 媒体播放
- CoreData 数据管理

## 构建运行

```bash
# 克隆和设置
git clone [your-repo-url]
cd neobee-session-player
pod install

# 在 Xcode 中打开
open neobee-session-player.xcworkspace

# 或者构建 DMG 包
./create_dmg.sh
```

## 使用方法

1. **添加音乐库**: 点击"添加文件夹"按钮，选择包含 MKV/MPG 文件的文件夹
2. **播放歌曲**: 从歌曲列表中选择歌曲，使用控制按钮播放
3. **音轨切换**: 对于双音轨文件，使用音轨选择器切换原唱/伴奏
4. **队列管理**: 在"已点歌曲"区域管理播放队列，支持删除和"顶到下一首"操作
5. **快捷键**: 空格键播放/暂停，F 键全屏切换

## 项目结构

```
neobee-session-player/
├── create_dmg.sh               # 构建和分发脚本
├── run_tests.sh                # 测试脚本
├── neobee-session-player/
│   ├── App/                    # 应用入口
│   ├── Features/
│   │   ├── Player/             # 播放器相关组件
│   │   │   ├── PlayerView.swift          # 主播放器视图
│   │   │   ├── VLCPlayerController.swift # VLC 播放控制器
│   │   │   ├── PlayerControls.swift      # 播放控制组件
│   │   │   └── PlayerUIComponents.swift  # UI 组件
│   │   └── Queue/              # 队列管理
│   │       ├── QueueManager.swift       # 队列管理器
│   │       └── QueueDisplayView.swift   # 队列显示组件
│   ├── Data/                   # 数据层
│   │   ├── LibraryScanner.swift         # 库扫描服务
│   │   └── Persistence.swift            # CoreData 配置
│   └── Views/                  # 主要视图
│       ├── ContentView.swift
│       └── LibraryListView.swift
├── neobee-session-playerTests/ # 单元测试
└── Podfile                     # CocoaPods 依赖
```

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 发布流程

项目使用 GitHub Actions 实现完全自动化的版本管理和发布流程：

### 自动版本升级

每次推送代码到 `main` 分支时，系统会根据提交消息自动升级版本号：

- `feat:` 开头 → 升级 minor 版本 (0.1.0 → 0.2.0)
- `fix:` 开头 → 升级 patch 版本 (0.1.0 → 0.1.1)
- `BREAKING CHANGE` → 升级 major 版本 (0.1.0 → 1.0.0)
- 其他提交 → 升级 patch 版本

### 手动发布版本

使用 `release.sh` 脚本手动创建发布版本：

```bash
# 发布新版本（会自动更新版本号并创建 tag）
./release.sh 0.2.0

# 脚本会自动：
# 1. 更新项目版本号
# 2. 创建 Git tag
# 3. 推送 tag 触发构建
# 4. 构建美观的 DMG 文件
# 5. 发布到 GitHub Releases
```

### 发布流程说明

1. **版本号更新**: 自动或手动更新 `project.pbxproj` 中的版本号
2. **Tag 创建**: 创建 `v{版本号}` 格式的 Git tag
3. **自动构建**: GitHub Actions 检测到 tag 推送，触发构建流程
4. **DMG 生成**: 使用 `create_dmg.sh` 脚本生成专业的 DMG 安装包
5. **发布**: 自动上传 DMG 到 GitHub Releases，包含详细的发布说明

### 查看发布状态

- **GitHub Actions**: 访问仓库的 Actions 页面查看构建状态
- **GitHub Releases**: 访问 Releases 页面下载最新版本的 DMG 文件
- **构建产物**: 每次构建都会生成 `NeoBee-KTV-Player.dmg` 文件

## 注意事项

本项目使用 VLCKit（GPL 许可证）作为媒体播放依赖。虽然本项目采用 MIT 许可证，但使用 VLCKit 的应用程序需要遵守 GPL 条款。如需商业分发，请考虑 VLCKit 的商业许可选项。
