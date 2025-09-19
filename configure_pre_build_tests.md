# 配置构建前运行测试

## 方法 1：使用修改后的构建脚本（推荐）

已修改 `create_dmg.sh`，现在会在构建前自动运行测试：

```bash
./create_dmg.sh
```

## 方法 2：使用独立的测试脚本

```bash
./run_tests.sh
```

## 方法 3：在 Xcode 中手动配置 Build Phases

1. 打开 Xcode 项目
2. 选择 `neobee-session-player` target
3. 进入 "Build Phases" 标签
4. 点击 "+" 添加 "New Run Script Phase"
5. 将脚本放在 "Compile Sources" 之前
6. 添加以下脚本：

```bash
# 运行测试
echo "Running tests before build..."
xcodebuild test -workspace neobee-session-player.xcworkspace \
                -scheme neobee-session-player \
                -destination 'platform=macOS' \
                -derivedDataPath "${DERIVED_DATA_DIR}"

if [ $? -ne 0 ]; then
    echo "❌ Tests failed! Build aborted."
    exit 1
fi
echo "✅ All tests passed!"
```

## 方法 4：使用 Xcode Scheme 的 Pre-actions

1. 在 Xcode 中，点击 Scheme 选择器
2. 选择 "Edit Scheme..."
3. 选择 "Build" 标签
4. 展开 "Pre-actions"
5. 点击 "+" 添加 "New Run Script Action"
6. 添加测试脚本

## 方法 5：使用 CI/CD 配置

在 GitHub Actions 或其他 CI 系统中：

```yaml
- name: Run Tests
  run: |
    xcodebuild test -workspace neobee-session-player.xcworkspace \
                    -scheme neobee-session-player \
                    -destination 'platform=macOS'
```

## 推荐使用顺序

1. 开发时：使用独立的 `run_tests.sh`
2. 发布时：使用修改后的 `create_dmg.sh`
3. 团队协作：在 Xcode Build Phases 中配置
