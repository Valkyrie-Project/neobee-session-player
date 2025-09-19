#!/bin/bash

# 解析命令行参数
SKIP_TESTS=false
for arg in "$@"; do
    case $arg in
        --skip-test|-s)
            SKIP_TESTS=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  -s, --skip-test    跳过测试，直接构建"
            echo "  -h, --help         显示此帮助信息"
            exit 0
            ;;
        *)
            echo "未知选项: $arg"
            echo "使用 $0 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 创建DMG安装包的脚本
APP_NAME="NeoBee KTV播放器"
DMG_NAME="NeoBee-KTV-Player"
VOLUME_NAME="NeoBee KTV Player"

# 检查并安装依赖
echo "Checking dependencies..."

# 检查CocoaPods是否安装
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods not found. Please install CocoaPods first:"
    echo "   sudo gem install cocoapods"
    exit 1
fi

# 检查Podfile是否存在
if [ ! -f "Podfile" ]; then
    echo "❌ Podfile not found. Please run this script from the project root directory."
    exit 1
fi

# 检查Pods目录是否存在，如果不存在则运行pod install
if [ ! -d "Pods" ]; then
    echo "📦 Pods directory not found. Running pod install..."
    pod install
    if [ $? -ne 0 ]; then
        echo "❌ pod install failed. Please check your Podfile and try again."
        exit 1
    fi
    echo "✅ Dependencies installed successfully"
else
    echo "✅ Dependencies already installed"
fi

# 根据标志决定是否跳过测试
if [ "$SKIP_TESTS" = true ]; then
    echo "跳过测试，直接构建..."
else
    echo "运行测试..."
    xcodebuild test -workspace neobee-session-player.xcworkspace \
                    -scheme neobee-session-player \
                    -destination 'platform=macOS' \
                    -derivedDataPath ./build

    # 检查测试是否成功
    if [ $? -ne 0 ]; then
        echo "❌ 测试失败！构建中止。"
        echo "使用 $0 --skip-test 跳过测试"
        exit 1
    fi
    echo "✅ 所有测试通过！"
fi

# 构建Release版本
echo "Building Release version..."
xcodebuild -workspace neobee-session-player.xcworkspace \
           -scheme neobee-session-player \
           -configuration Release \
           -derivedDataPath ./build \
           -archivePath ./build/NeoBee-KTV-Player.xcarchive \
           archive

# 检查构建是否成功
if [ ! -d "./build/NeoBee-KTV-Player.xcarchive/Products/Applications/${APP_NAME}.app" ]; then
    echo "Build failed! App not found in archive."
    exit 1
fi

echo "构建成功！正在创建DMG..."

# 创建临时目录
TEMP_DIR="./temp_dmg"
DMG_DIR="${TEMP_DIR}"

# 清理并创建目录
rm -rf "${TEMP_DIR}"
mkdir -p "${DMG_DIR}"

# 复制app到DMG根目录
cp -R "./build/NeoBee-KTV-Player.xcarchive/Products/Applications/${APP_NAME}.app" "${DMG_DIR}/"

# 检查VLCKit是否被正确嵌入
if [ -d "${DMG_DIR}/${APP_NAME}.app/Contents/Frameworks/VLCKit.framework" ]; then
    echo "✅ VLCKit已正确嵌入"
else
    echo "⚠️  VLCKit未找到"
fi

# 创建Applications链接
ln -s /Applications "${DMG_DIR}/Applications"

# 不创建背景图片，保持简洁

# 创建并自定义DMG
echo "正在自定义DMG外观..."
TEMP_DMG="${DMG_NAME}_temp.dmg"
hdiutil create -srcfolder "${TEMP_DIR}" -volname "${VOLUME_NAME}" -fs HFS+ -format UDRW "${TEMP_DMG}"

# 挂载DMG进行自定义
hdiutil attach "${TEMP_DMG}" -readwrite -noverify -noautoopen
MOUNT_POINT="/Volumes/${VOLUME_NAME}"

# 等待挂载完成
sleep 3

# 使用AppleScript设置DMG外观
osascript << EOF
try
    tell application "Finder"
        tell disk "${VOLUME_NAME}"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {100, 100, 600, 400}
            set viewOptions to the icon view options of container window
            set arrangement of viewOptions to not arranged
            set icon size of viewOptions to 128
            set text size of viewOptions to 12
            -- 不设置背景图片，使用默认
            
            -- 尝试设置应用位置（可能因权限失败）
            try
                set position of item "${APP_NAME}.app" to {150, 110}
            on error
                -- 权限被拒绝，继续其他设置
            end try
            
            -- 尝试设置Applications链接位置
            try
                set position of item "Applications" to {350, 110}
            on error
                -- 权限被拒绝，继续其他设置
            end try
            
            -- 更新显示
            update
            close
            open
        end tell
    end tell
on error errorMessage
    -- 如果AppleScript失败，至少确保DMG可以正常使用
    display notification "DMG created successfully, but window layout couldn't be customized due to security restrictions." with title "DMG Creation"
end try
EOF

# 设置文件属性
chmod -Rf 755 "${MOUNT_POINT}/${APP_NAME}.app" 2>/dev/null || true
xattr -cr "${MOUNT_POINT}/${APP_NAME}.app" 2>/dev/null || true

# 完成并压缩DMG
sync
sleep 1
hdiutil detach "${MOUNT_POINT}" -force

# 创建最终压缩版本
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=6 -o "${DMG_NAME}_final.dmg"

# 重命名为最终文件
mv "${DMG_NAME}_final.dmg" "${DMG_NAME}.dmg"

# 删除临时DMG
rm -f "${TEMP_DMG}"

# 为DMG设置图标
echo "Setting DMG icon..."
APP_ICON_PATH="./build/NeoBee-KTV-Player.xcarchive/Products/Applications/${APP_NAME}.app/Contents/Resources/AppIcon.icns"

if [ -f "$APP_ICON_PATH" ]; then
    echo "Found app icon, setting DMG icon..."
    
    # 创建临时图标文件
    TEMP_ICON="/tmp/dmg_icon_$$.icns"
    cp "$APP_ICON_PATH" "$TEMP_ICON"
    
    # 方法1: 使用sips和DeRez/Rez
    if command -v DeRez >/dev/null 2>&1 && command -v Rez >/dev/null 2>&1; then
        echo "Using DeRez/Rez method..."
        sips -i "$TEMP_ICON" >/dev/null 2>&1
        DeRez -only icns "$TEMP_ICON" > /tmp/icon_$$.rsrc 2>/dev/null
        if [ -f /tmp/icon_$$.rsrc ] && [ -s /tmp/icon_$$.rsrc ]; then
            Rez -append /tmp/icon_$$.rsrc -o "${DMG_NAME}.dmg" 2>/dev/null
            SetFile -a C "${DMG_NAME}.dmg" 2>/dev/null
            echo "✅ DMG icon set successfully (DeRez/Rez)"
        fi
        rm -f /tmp/icon_$$.rsrc
    fi
    
    # 方法2: 使用fileicon（如果可用）
    if command -v fileicon >/dev/null 2>&1; then
        echo "Using fileicon method..."
        fileicon set "${DMG_NAME}.dmg" "$APP_ICON_PATH" 2>/dev/null && echo "✅ DMG icon set successfully (fileicon)"
    fi
    
    # 清理临时文件
    rm -f "$TEMP_ICON"
else
    echo "⚠️  App icon not found at: $APP_ICON_PATH"
fi

# 清理临时文件
rm -rf "${TEMP_DIR}"

echo ""
echo "🎉 DMG创建成功！"
echo ""
echo "📦 ${DMG_NAME}.dmg"
echo "✅ 专业安装界面，拖拽即可安装"
echo ""
echo "🚀 Ready to share!"
