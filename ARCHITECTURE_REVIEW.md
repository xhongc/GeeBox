# Flutter 架构评估（仅记录问题）

本文档仅整理当前 Flutter / Riverpod 架构中的风险与优化点，不做任何修复。

## 发现的问题

1. 播放状态不够响应式，存在多套“真相源”。
   - `AudioPlayerService` 是可变单例，`audioPlayerServiceProvider` 是普通
     `Provider`，状态变化不会触发订阅者刷新。
   - UI 通过 `ref.listen(currentSongProvider, ...)` 空回调“尝试刷新”，
     实际不会触发重建；`MiniPlayer` 与 `PlayerScreen` 直接读
     `audioService.currentSong`，歌曲切换可能不更新。
   - 播放队列/播放模式同时在服务内部与 `StateProvider`
     (`currentPlaylistProvider` / `currentIndexProvider` / `playModeProvider`)
     维护，容易产生漂移。
   - 相关文件：`lib/services/audio_player_service.dart`,
     `lib/providers/audio_player_provider.dart`,
     `lib/widgets/mini_player.dart`, `lib/screens/player_screen.dart`,
     `lib/screens/play_queue_screen.dart`

2. 路由体系混用（go_router + Navigator）。
   - 顶层用了 `go_router`，但大量页面仍直接 `Navigator.push`，
     会绕过路由状态。
   - 深链、URL 同步、返回行为容易出现不一致。
   - 相关文件：`lib/router/app_router.dart`, `lib/screens/*_screen.dart`

3. 服务器配置生命周期不稳健。
   - `SubsonicService` 使用 `late` 字段，未调用 `configure`
     时访问会崩溃（例如“跳过配置”后进入首页）。
   - 已保存配置没有在启动时注入服务。
   - 相关文件：`lib/services/subsonic_service.dart`,
     `lib/providers/subsonic_provider.dart`,
     `lib/screens/server_config_screen.dart`, `lib/main.dart`

4. 专辑缓存未区分列表类型。
   - `MusicRepository.getAlbumList` 将 newest/random/frequent
     全部写入同一个 Hive box，仅以专辑 id 区分。
   - 缓存有效性用第一条专辑的 `cacheTime` 判断，可能导致随机/最近
     列表互相污染或过期策略失效。
   - 相关文件：`lib/repositories/music_repository.dart`

5. 搜索历史非响应式，异步初始化与同步读取混用。
   - `SearchService` 构造函数里异步开箱，UI 可能在 box 就绪前读取，
     导致空数据。
   - `searchHistoryProvider` 是普通 `Provider<List>`，UI 需 `setState`
     手动刷新，和 Riverpod 的响应式混用。
   - 相关文件：`lib/services/search_service.dart`,
     `lib/providers/search_provider.dart`, `lib/screens/search_screen.dart`

6. 歌词 Provider 使用 `Map` 作为 family key，缓存失效。
   - `lyricsProvider` 的参数是 `Map<String, String?>`；
     Map 以引用判等，每次调用都是新 key，会频繁重新请求。
   - 相关文件：`lib/providers/lyrics_provider.dart`

7. 睡眠定时器状态仅用计数器“打点”刷新。
   - `sleepTimerStateProvider` 通过自增 `int` 触发刷新，
     无法表达剩余时间/运行状态，扩展性差。
   - 相关文件：`lib/providers/sleep_timer_provider.dart`,
     `lib/services/sleep_timer_service.dart`

## 需要你确认的方向

1. 播放状态要不要完全由 Riverpod 承担（StateNotifier/AsyncNotifier）？
   还是保持“服务 + streams”的模式？
2. 路由是否要统一到 `go_router`？
3. 服务器配置是否允许“跳过进入离线模式”，还是必须配置成功才能进入？

