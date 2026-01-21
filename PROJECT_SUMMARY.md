# Chanson - Subsonic 音乐客户端

一个基于 Flutter 开发的跨平台 Subsonic 音乐客户端应用。

## 项目概述

Chanson 是一个功能完整的 Subsonic 音乐流媒体客户端，支持 Android、iOS、macOS、Linux 和 Windows 平台。

## 技术栈

### 核心框架
- **Flutter SDK 3.4.0+** - 跨平台 UI 框架
- **Dart 3.4.0+** - 编程语言

### 主要依赖

#### 路由管理
- **go_router ^14.6.2** - 声明式路由，支持深层链接和嵌套导航

#### 网络层
- **dio ^5.7.0** - HTTP 客户端，用于与 Subsonic API 通信
- **crypto ^3.0.6** - 加密库，用于 Subsonic API 认证

#### 音频播放
- **just_audio ^0.9.42** - 音频播放引擎
- **audio_service ^0.18.15** - 后台播放和系统媒体控制集成

#### 状态管理
- **flutter_riverpod ^2.6.1** - 响应式状态管理

#### 本地存储
- **hive ^2.2.3** - 轻量级 NoSQL 数据库
- **hive_flutter ^1.1.0** - Hive 的 Flutter 集成
- **path_provider ^2.1.5** - 获取文件系统路径

#### 开发工具
- **hive_generator ^2.0.1** - Hive 类型适配器代码生成
- **build_runner ^2.4.11** - Dart 代码生成工具

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── song.dart            # 歌曲模型
│   ├── song.g.dart          # Hive 适配器（自动生成）
│   ├── album.dart           # 专辑模型
│   └── album.g.dart         # Hive 适配器（自动生成）
├── services/                 # 业务服务
│   ├── subsonic_service.dart      # Subsonic API 服务
│   └── audio_player_service.dart  # 音频播放服务
├── repositories/             # 数据仓库层
│   └── music_repository.dart      # 音乐数据仓库（缓存+网络）
├── providers/                # Riverpod Providers
│   ├── subsonic_provider.dart           # Subsonic 服务 Provider
│   ├── audio_player_provider.dart       # 音频播放 Provider
│   └── music_repository_provider.dart   # 数据仓库 Provider
├── screens/                  # 页面
│   ├── home_screen.dart            # 首页
│   ├── browse_screen.dart          # 浏览页面
│   ├── player_screen.dart          # 播放器页面
│   └── server_config_screen.dart   # 服务器配置页面
└── router/                   # 路由配置
    └── app_router.dart       # 应用路由定义
```

## 核心功能

### 已实现功能

1. **服务器配置**
   - Subsonic 服务器连接配置
   - 服务器连接测试
   - 配置持久化存储

2. **基础 UI 框架**
   - 首页
   - 浏览页面
   - 播放器页面
   - 页面导航

3. **Subsonic API 集成**
   - 服务器 Ping 测试
   - 获取随机歌曲
   - 获取专辑列表
   - 获取专辑详情
   - 搜索功能
   - 流媒体 URL 生成
   - 封面图片 URL 生成

4. **音频播放**
   - 基础播放控制（播放/暂停/上一首/下一首）
   - 播放列表管理
   - 播放进度跟踪

5. **数据缓存**
   - 歌曲数据缓存
   - 专辑数据缓存
   - 缓存过期机制（24小时）
   - 缓存优先策略

6. **状态管理**
   - Riverpod 状态管理
   - 播放状态流
   - 服务器配置状态

## 数据流架构

```
UI Layer (Screens)
    ↓
State Management (Riverpod Providers)
    ↓
Repository Layer (MusicRepository)
    ↓
Service Layer (SubsonicService, AudioPlayerService)
    ↓
Data Sources (Network API, Hive Cache)
```

## 开发指南

### 环境要求

- Flutter SDK 3.4.0 或更高版本
- Dart SDK 3.4.0 或更高版本

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
# 桌面平台
flutter run -d macos
flutter run -d linux
flutter run -d windows

# 移动平台
flutter run -d android
flutter run -d ios
```

### 构建应用

```bash
# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios

# macOS
flutter build macos

# Linux
flutter build linux

# Windows
flutter build windows
```

## 下一步开发计划

### 功能增强

1. **完善播放器功能**
   - 实时显示播放进度
   - 拖动进度条
   - 显示封面图片
   - 显示歌曲信息
   - 播放模式（顺序/随机/单曲循环）

2. **浏览功能**
   - 专辑列表展示
   - 艺术家列表
   - 播放列表管理
   - 收藏功能

3. **搜索功能**
   - 全局搜索
   - 搜索历史
   - 搜索结果展示

4. **用户体验优化**
   - 加载状态提示
   - 错误处理
   - 离线模式
   - 主题切换（深色/浅色）

5. **高级功能**
   - 歌词显示
   - 均衡器
   - 睡眠定时器
   - 跨设备同步

## 技术特点

1. **渐进式开发** - 按需引入依赖，避免过度工程
2. **清晰的架构** - 分层设计，关注点分离
3. **缓存优先** - 智能缓存策略，提升用户体验
4. **响应式状态管理** - 使用 Riverpod 实现响应式 UI
5. **类型安全** - 使用 Hive 类型适配器确保数据安全

## 许可证

本项目仅供学习和个人使用。
