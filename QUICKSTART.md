# Chanson 快速启动指南

## 项目状态

✅ 项目已成功创建并配置完成
✅ 所有依赖已安装
✅ Hive 适配器代码已生成
✅ 核心功能已实现

## 运行应用

### 🚀 最快启动方式（推荐）

使用提供的启动脚本，一键启动应用：

```bash
cd /Users/macbookair/coding/chanson
./start.sh
```

这个脚本会：
1. 自动启动禁用 CORS 的 Chrome
2. 启动 Chanson 应用
3. 可以正常连接 Subsonic 服务器

### ⚠️ 重要提示

1. **macOS/iOS 平台需要 Xcode**
   - macOS 和 iOS 平台需要安装完整的 Xcode（不是命令行工具）
   - 如果遇到 "xcrun: error: unable to find utility xcodebuild" 错误，请查看 `MACOS_SETUP.md`

2. **Web 平台受 CORS 限制**
   - Web 平台受浏览器 CORS（跨域资源共享）限制，无法直接连接大多数 Subsonic 服务器
   - 建议使用桌面平台或配置 CORS 代理

### 方法 1：使用桌面平台（推荐）

```bash
# macOS（推荐）
flutter run -d macos

# Linux
flutter run -d linux

# Windows
flutter run -d windows
```

### 方法 2：Web 平台（仅用于 UI 开发）

```bash
# Chrome（受 CORS 限制）
flutter run -d chrome
```

**注意**: Web 平台可能无法连接到 Subsonic 服务器，除非：
- 服务器配置了正确的 CORS 头
- 使用代理服务器
- 使用禁用安全策略的浏览器（仅开发环境）


## 首次使用

1. **启动应用**
   - 应用会自动打开服务器配置页面

2. **配置 Subsonic 服务器**
   - 输入服务器地址（例如：`https://demo.subsonic.org`）
   - 输入用户名和密码
   - 点击"测试连接"

3. **开始使用**
   - 连接成功后会自动跳转到首页
   - 可以浏览音乐、播放歌曲

## 测试服务器

如果您没有自己的 Subsonic 服务器，可以使用官方演示服务器：

- **服务器地址**: `https://demo.subsonic.org`
- **用户名**: `guest`
- **密码**: `guest`

## 开发命令

```bash
# 获取依赖
flutter pub get

# 生成代码（修改模型后需要运行）
dart run build_runner build --delete-conflicting-outputs

# 代码分析
flutter analyze

# 运行测试
flutter test

# 清理构建缓存
flutter clean
```

## 各平台打包（构建产物）

```bash
# Android APK（通用包）
flutter build apk

# Android App Bundle（上架 Google Play 推荐）
flutter build appbundle

# iOS（生成 Xcode 归档，需在 Xcode 中导出）
flutter build ios --release

# macOS
flutter build macos

# Linux
flutter build linux

# Windows
flutter build windows

# Web
flutter build web
```

**说明**:
- iOS 打包需要 macOS + 完整 Xcode，证书与签名在 Xcode 中配置。
- Android 打包需要已接受 SDK 许可证与正确的签名配置（发布包需配置 keystore）。
- Web 构建会受到 CORS 影响，仅适用于无跨域限制的环境或配套代理。

## 支持的平台

- ✅ macOS（已配置）
- ✅ Web/Chrome（已配置）
- ⚠️ Android（需要配置 Android SDK 许可证）
- ⚠️ iOS（需要完整安装 Xcode）
- ✅ Linux（已配置）
- ✅ Windows（已配置）

## 常见问题

### Q: Web 平台显示 "XMLHttpRequest onError" 或 CORS 错误
A: 这是浏览器的安全限制。解决方案：
1. **使用桌面应用**（推荐）：
   ```bash
   flutter run -d macos
   ```
2. **配置服务器支持 CORS**：在 Subsonic 服务器添加 CORS 头
3. **开发环境临时方案**：使用禁用安全策略的 Chrome
   ```bash
   open -na "Google Chrome" --args --disable-web-security --user-data-dir="/tmp/chrome_dev"
   ```
   ⚠️ 仅用于开发，不要用于日常浏览

### Q: 应用无法连接到服务器
A: 请检查：
- 服务器地址是否正确（必须包含 http:// 或 https://）
- 网络连接是否正常
- 服务器是否在运行

### Q: 如何切换服务器
A: 在首页点击设置图标，或直接访问 `/config` 路由

### Q: 缓存数据存储在哪里
A: 使用 Hive 存储在应用数据目录：
- macOS: `~/Library/Application Support/chanson/`
- Linux: `~/.local/share/chanson/`
- Windows: `%APPDATA%/chanson/`

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
├── services/                 # 业务服务
├── repositories/             # 数据仓库
├── providers/                # 状态管理
├── screens/                  # 页面
└── router/                   # 路由配置
```

## 下一步开发

查看 `PROJECT_SUMMARY.md` 了解详细的技术架构和开发计划。

## 技术支持

如有问题，请查看：
- `README.md` - 技术方案说明
- `PROJECT_SUMMARY.md` - 项目详细文档
- `subsonic_api_docs.md` - Subsonic API 文档
