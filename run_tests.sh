#!/bin/bash

# 运行测试脚本
echo "🧪 Running NeoBee KTV Player Tests..."

# 检查依赖
if [ ! -f "Podfile" ]; then
    echo "❌ Podfile not found. Please run this script from the project root directory."
    exit 1
fi

# 检查Pods目录是否存在
if [ ! -d "Pods" ]; then
    echo "📦 Pods directory not found. Running pod install..."
    pod install
    if [ $? -ne 0 ]; then
        echo "❌ pod install failed."
        exit 1
    fi
fi

# 运行测试
echo "Running unit and UI tests..."
xcodebuild test -workspace neobee-session-player.xcworkspace \
                -scheme neobee-session-player \
                -destination 'platform=macOS' \
                -derivedDataPath ./build

# 检查测试结果
if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Tests failed!"
    exit 1
fi
