# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Chanson 是一个基于 Flutter 开发的跨平台 Subsonic 音乐客户端，支持 Android、iOS、macOS、Linux 和 Windows 平台。

## 常用开发命令

### flutter PATH
/Users/macbookair/coding/flutter/flutter/bin

### 依赖管理
```bash
# 安装依赖
flutter pub get

# 生成 Hive 适配器代码（修改模型后必须运行）
dart run build_runner build --delete-conflicting-outputs

# 监听模式生成代码（开发时推荐）
dart run build_runner watch --delete-conflicting-outputs
```

### 运行应用
```bash
# macOS（推荐用于开发）
flutter run -d macos

# Web（受 CORS 限制，仅用于 UI 开发）
flutter run -d chrome

# 其他平台
flutter run -d linux
flutter run -d windows
flutter run -d android
flutter run -d ios
```

### 代码质量
```bash
# 代码分析
flutter analyze

# 运行测试
flutter test

# 清理构建缓存
flutter clean
```

### 构建发布版本
```bash
flutter build macos
flutter build apk
flutter build appbundle
flutter build ios
flutter build linux
flutter build windows
```

## 核心架构

### 数据流架构
项目采用清晰的分层架构：

```
UI Layer (Screens/Widgets)
    ↓
State Management (Riverpod Providers)
    ↓
Repository Layer (MusicRepository)
    ↓
Service Layer (SubsonicService, AudioPlayerService)
    ↓
Data Sources (Network API via Dio, Hive Cache)
```

### 关键设计模式

1. **缓存优先策略**
   - 使用 Hive 进行本地数据持久化
   - 缓存有效期为 24 小时（在 `MusicRepository` 中配置）
   - 数据获取流程：检查缓存 → 验证有效性 → 返回缓存或从网络获取
   - 使用 Subsonic API 返回的 `id` 作为 Hive Box 的 Key

2. **状态管理**
   - 使用 Riverpod 进行响应式状态管理
   - 所有 Provider 定义在 `lib/providers/` 目录
   - 播放器状态通过 `AudioPlayerService` 的 Stream 暴露

3. **音频播放服务**
   - `AudioPlayerService` 是单例模式
   - 封装了 `just_audio` 的播放控制逻辑
   - 通过 `audio_player_provider.dart` 暴露给 UI 层

4. **Subsonic API 认证**
   - 使用 MD5 token + salt 认证方式
   - 在 `SubsonicService._getAuthParams()` 中实现
   - API 版本：1.16.1

## 代码生成

项目使用 `build_runner` 生成以下代码：

1. **Hive 适配器** (`*.g.dart`)
   - 为所有带 `@HiveType()` 注解的模型生成
   - 当前模型：`Song`, `Album`, `SearchHistory`, `Playlist`
   - 修改模型后必须重新生成

2. **模型注意事项**
   - 所有模型必须包含 `cacheTime` 字段用于缓存管理
   - 使用 `part` 指令引入生成的文件：`part 'model_name.g.dart';`
   - 在 `main.dart` 中注册所有适配器

## 路由配置

- 使用 `go_router` 进行声明式路由
- 路由定义在 `lib/router/app_router.dart`
- 初始路由：`/config`（服务器配置页面）
- 主导航：`/`（包含首页、发现、搜索、音乐库）

## 主题系统

- 支持浅色/深色/跟随系统三种模式
- 使用 Material 3 设计规范
- 主题配置在 `lib/theme/app_theme.dart`
- 通过 `themeSettingsProvider` 管理主题状态
- 支持自定义种子颜色（Seed Color）

## 平台特定注意事项

### Web 平台
- 受浏览器 CORS 限制，无法直接连接大多数 Subsonic 服务器
- 开发时可使用 `start.sh` 脚本启动禁用 CORS 的 Chrome
- 生产环境需要服务器配置 CORS 头或使用代理

### macOS/iOS
- 需要完整安装 Xcode（不是命令行工具）
- 如遇到 "xcrun: error" 请查看 `MACOS_SETUP.md`

### Android
- 需要配置 Android SDK 许可证

## 测试服务器

官方演示服务器（用于开发测试）：
- 服务器地址：`https://demo.subsonic.org`
- 用户名：`guest`
- 密码：`guest`

## 开发最佳实践

1. **添加新模型时**
   - 添加 `@HiveType(typeId: N)` 注解（N 为唯一 ID）
   - 为所有字段添加 `@HiveField(N)` 注解
   - 包含 `cacheTime` 字段
   - 实现 `fromJson` 和 `toJson` 方法
   - 运行 `dart run build_runner build --delete-conflicting-outputs`
   - 在 `main.dart` 中注册适配器并打开对应的 Box

2. **添加新的 Subsonic API 调用**
   - 在 `SubsonicService` 中添加方法
   - 使用 `_getAuthParams()` 获取认证参数
   - 在 `MusicRepository` 中添加缓存逻辑（如需要）
   - 通过 Provider 暴露给 UI 层

3. **状态管理**
   - 优先使用 Riverpod Provider
   - 避免在 Widget 中直接调用 Service
   - 通过 Repository 层统一数据访问

4. **错误处理**
   - Service 层捕获异常并返回空列表/默认值
   - UI 层检查返回值并显示适当的提示

5. **Dart/Flutter 常见错误避免**
   - **void 返回值误用**：不要将 `void` 返回类型的方法用于条件判断
     ```dart
     // ❌ 错误：void 方法不能用于条件判断
     void _ensureConfigured() { ... }
     if (!_ensureConfigured()) return false;  // use_of_void_result 错误

     // ✅ 正确：使用 bool 属性或返回 bool 的方法
     bool get isConfigured => _isConfigured;
     if (!isConfigured) return false;

     // 或者：void 方法仅用于抛出异常，不用于条件判断
     void _ensureConfigured() {
       if (!_isConfigured) throw Exception();
     }
     _ensureConfigured();  // 直接调用，不用于条件判断
     ```

   - **异步方法必须处理返回值**：所有 `Future` 返回的方法必须用 `await` 或 `.then()` 处理

   - **空安全检查**：使用 `?.`、`??` 和 `!` 时要确保逻辑正确，避免运行时空指针异常

   - **修改代码后必须运行分析**：每次修改代码后运行 `flutter analyze` 确保没有引入新错误

## 项目文档

- `README.md` - 技术栈和项目结构
- `QUICKSTART.md` - 快速启动指南
- `PROJECT_SUMMARY.md` - 技术方案详解
- `subsonic_api_docs.md` - Subsonic API 文档
- `UI_DESIGN.md` - UI 设计规范
- `MACOS_SETUP.md` - macOS 平台配置指南
