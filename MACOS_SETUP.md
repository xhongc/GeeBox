# macOS 平台运行问题解决方案

## 问题

运行 `flutter run -d macos` 时出现错误：
```
xcrun: error: unable to find utility "xcodebuild", not a developer tool or in PATH
```

## 原因

macOS 平台需要完整的 **Xcode** 来构建应用，仅安装命令行工具（Command Line Tools）是不够的。

## 解决方案

### 方案 1：安装完整的 Xcode（推荐用于 macOS/iOS 开发）

1. **从 App Store 安装 Xcode**
   - 打开 App Store
   - 搜索 "Xcode"
   - 点击"获取"或"安装"
   - 等待下载完成（约 12-15 GB）

2. **配置 Xcode**
   ```bash
   # 设置 Xcode 路径
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

   # 运行首次启动
   sudo xcodebuild -runFirstLaunch

   # 接受许可协议
   sudo xcodebuild -license accept
   ```

3. **验证安装**
   ```bash
   flutter doctor
   ```

4. **运行应用**
   ```bash
   cd /Users/macbookair/coding/chanson
   flutter run -d macos
   ```

### 方案 2：使用 Web 平台（临时方案）

如果不想安装 Xcode，可以使用 Web 平台进行 UI 开发：

```bash
cd /Users/macbookair/coding/chanson
flutter run -d chrome
```

**注意**：Web 平台受 CORS 限制，无法连接到大多数 Subsonic 服务器。

#### Web 平台 CORS 解决方案

使用禁用安全策略的 Chrome（仅开发环境）：

```bash
# 1. 启动禁用安全策略的 Chrome
open -na "Google Chrome" --args --disable-web-security --user-data-dir="/tmp/chrome_dev"

# 2. 在新终端运行应用
cd /Users/macbookair/coding/chanson
flutter run -d chrome
```

### 方案 3：使用 Android 模拟器

如果您已配置 Android SDK：

```bash
# 1. 接受 Android 许可证
flutter doctor --android-licenses

# 2. 创建并启动模拟器
flutter emulators --launch <emulator_id>

# 3. 运行应用
flutter run -d <device_id>
```

## 平台支持状态

| 平台 | 状态 | 说明 |
|------|------|------|
| macOS | ⚠️ 需要 Xcode | 需要安装完整的 Xcode |
| iOS | ⚠️ 需要 Xcode | 需要安装完整的 Xcode |
| Web | ✅ 可用 | 受 CORS 限制 |
| Android | ⚠️ 需要配置 | 需要接受 SDK 许可证 |
| Linux | ✅ 可用 | 如果在 Linux 系统上 |
| Windows | ✅ 可用 | 如果在 Windows 系统上 |

## 推荐方案

### 对于 macOS 用户

1. **最佳方案**：安装 Xcode，获得完整的 macOS/iOS 开发能力
2. **临时方案**：使用 Web 平台进行 UI 开发（注意 CORS 限制）

### 对于其他平台用户

- **Linux**：直接运行 `flutter run -d linux`
- **Windows**：直接运行 `flutter run -d windows`

## 验证环境

运行以下命令检查 Flutter 环境：

```bash
flutter doctor -v
```

查看详细的环境配置信息和问题。

## 下一步

安装 Xcode 后，您就可以：
- 在 macOS 上运行应用
- 开发 iOS 应用
- 使用 iOS 模拟器测试

如果只是想快速测试应用功能，建议使用 Web 平台配合禁用安全策略的 Chrome。
