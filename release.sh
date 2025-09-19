#!/bin/bash

# 版本发布脚本
# 用法: ./release.sh [版本号]
# 例如: ./release.sh 0.0.1

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "请提供版本号"
    echo "用法: $0 <版本号>"
    echo "例如: $0 0.0.1"
    exit 1
fi

# 验证版本号格式 (x.y.z)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ 版本号格式不正确，应为 x.y.z 格式"
    exit 1
fi

echo "🚀 准备发布版本 $VERSION"

# 1. 检查工作目录是否干净
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ 工作目录有未提交的更改，请先提交或暂存"
    git status --short
    exit 1
fi

# 2. 确保在main分支
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ 请在main分支上发布版本，当前分支: $CURRENT_BRANCH"
    exit 1
fi

# 3. 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 4. 更新版本号
echo "📝 更新版本号到 $VERSION..."
sed -i '' "s/MARKETING_VERSION = [0-9]*\.[0-9]*\.[0-9]*/MARKETING_VERSION = $VERSION/g" neobee-session-player.xcodeproj/project.pbxproj
sed -i '' "s/INFOPLIST_KEY_CFBundleShortVersionString = [0-9]*\.[0-9]*\.[0-9]*/INFOPLIST_KEY_CFBundleShortVersionString = $VERSION/g" neobee-session-player.xcodeproj/project.pbxproj

# 5. 提交版本号更改
git add neobee-session-player.xcodeproj/project.pbxproj
git commit -m "chore: 更新版本号到 $VERSION"

# 6. 创建标签
echo "🏷️  创建标签 v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION

## 更新内容
- KTV风格视频播放器
- 支持MKV和MPG格式
- 原唱/伴奏音轨切换
- 播放队列管理

## 安装方法
下载DMG文件，拖拽到Applications文件夹即可使用。"

# 7. 推送到远程
echo "📤 推送到远程仓库..."
git push origin main
git push origin "v$VERSION"

echo ""
echo "✅ 版本 $VERSION 发布成功！"
echo ""
echo "🎯 接下来的步骤："
echo "1. GitHub Actions 将自动构建和发布"
echo "2. 访问 https://github.com/你的用户名/neobee-session-player/releases 查看发布状态"
echo "3. 构建完成后，用户可以下载 DMG 文件"
echo ""
echo "📊 发布信息："
echo "   版本号: $VERSION"
echo "   标签: v$VERSION"
echo "   分支: main"
echo "   提交: $(git rev-parse --short HEAD)"
