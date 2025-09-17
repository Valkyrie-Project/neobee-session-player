#!/bin/bash

# 创建DMG安装包的脚本
APP_NAME="NeoBee KTV播放器"
DMG_NAME="NeoBee-KTV-Player"
VOLUME_NAME="NeoBee KTV Player"

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

echo "Build successful! Creating DMG..."

# 创建临时目录
TEMP_DIR="./temp_dmg"
DMG_DIR="${TEMP_DIR}/${VOLUME_NAME}"

# 清理并创建目录
rm -rf "${TEMP_DIR}"
mkdir -p "${DMG_DIR}"

# 复制app到DMG目录
cp -R "./build/NeoBee-KTV-Player.xcarchive/Products/Applications/${APP_NAME}.app" "${DMG_DIR}/"

# 检查VLCKit是否被正确嵌入
echo "Checking VLCKit embedding..."
if [ -d "${DMG_DIR}/${APP_NAME}.app/Contents/Frameworks/VLCKit.framework" ]; then
    echo "✅ VLCKit is properly embedded in the app bundle"
else
    echo "⚠️  VLCKit not found in app bundle - this may cause issues on other machines"
    echo "   You may need to install VLCKit separately or use a different approach"
fi

# 创建Applications链接
ln -s /Applications "${DMG_DIR}/Applications"

# 创建DMG
hdiutil create -srcfolder "${TEMP_DIR}" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDZO "${DMG_NAME}.dmg"

# 清理临时文件
rm -rf "${TEMP_DIR}"

echo "DMG created: ${DMG_NAME}.dmg"
echo "You can now share this file with your friends!"
