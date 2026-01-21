# Chanson 🎵

一个优雅的跨平台 Subsonic 音乐客户端，使用 Flutter 开发。

![Flutter](https://img.shields.io/badge/Flutter-3.4.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.4.0+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Linux%20%7C%20Windows%20%7C%20Web-lightgrey.svg)

## ✨ 特性

- 🎵 **完整的 Subsonic API 支持** - 浏览、搜索、播放音乐
- 🎨 **现代化 UI** - Material Design 3 设计语言
- 💾 **智能缓存** - 本地缓存提升体验
- 🔄 **响应式状态管理** - 使用 Riverpod
- 🌐 **跨平台支持** - 一套代码，多平台运行
- 🎧 **后台播放** - 支持后台播放和系统媒体控制

## 🚀 快速开始

### 一键启动（推荐）

```bash
cd /Users/macbookair/coding/chanson
./start.sh
```

### 首次使用

1. 启动应用后，输入您的 Subsonic 服务器信息
2. 或使用演示服务器快速体验：
   - 服务器: `https://demo.subsonic.org`
   - 用户名: `guest`
   - 密码: `guest`

## 📖 文档

- [快速启动指南](QUICKSTART.md) - 详细的运行说明
- [项目文档](PROJECT_SUMMARY.md) - 技术架构和开发计划
- [macOS 设置](MACOS_SETUP.md) - macOS 平台配置指南
- [技术方案](README.md) - 原始技术方案说明

## 🛠️ 技术栈

| 类别 | 技术 | 用途 |
|------|------|------|
| 路由 | go_router | 页面导航 |
| 网络 | dio | HTTP 请求 |
| 播放 | just_audio + audio_service | 音频播放 |
| 状态 | flutter_riverpod | 状态管理 |
| 缓存 | hive | 本地存储 |

## 📱 支持平台

| 平台 | 状态 | 说明 |
|------|------|------|
| Web | ✅ 可用 | 使用提供的脚本绕过 CORS |
| macOS | ⚠️ 需要 Xcode | 需要完整安装 Xcode |
| iOS | ⚠️ 需要 Xcode | 需要完整安装 Xcode |
| Android | ⚠️ 需要配置 | 需要接受 SDK 许可证 |
| Linux | ✅ 可用 | 直接运行 |
| Windows | ✅ 可用 | 直接运行 |

## 🏗️ 项目结构

```
lib/
├── main.dart              # 应用入口
├── models/                # 数据模型
├── services/              # 业务服务
├── repositories/          # 数据仓库
├── providers/             # 状态管理
├── screens/               # 页面
└── router/                # 路由配置
```

## 🔧 开发

### 安装依赖

```bash
flutter pub get
```

### 生成代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
# 使用启动脚本（推荐）
./start.sh

# 或手动运行
flutter run -d chrome
flutter run -d macos  # 需要 Xcode
```

## 🎯 开发路线图

- [x] 基础框架搭建
- [x] Subsonic API 集成
- [x] 音频播放功能
- [x] 数据缓存
- [x] 状态管理
- [ ] 完善播放器 UI
- [ ] 专辑/艺术家浏览
- [ ] 搜索功能
- [ ] 播放列表管理
- [ ] 歌词显示
- [ ] 主题切换

## 📝 许可证

本项目仅供学习和个人使用。

## 🙏 致谢

- [Subsonic](http://www.subsonic.org/) - 优秀的音乐流媒体服务器
- [Flutter](https://flutter.dev/) - 强大的跨平台框架
- 所有开源依赖的作者和贡献者

---

**享受您的音乐之旅！** 🎵
