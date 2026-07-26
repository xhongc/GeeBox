# Listener 源页面视觉规格记录

用途：记录 `/Users/macbookair/coding/music-tag-web-v2/web` 中 Listener 页面到 Flutter/Forui 的复刻依据。每行都对应一个源页面或源组件，验收时以“结构、入口、状态、差异”四类信息为准。

## 全局组件

| 源文件 | Flutter 目标 | 结构与视觉 | 交互入口 | 差异记录 |
| --- | --- | --- | --- | --- |
| `src/components/library/mobile/ListenerMobileShell.vue` | `lib/screens/main_navigation_screen.dart` | 浅色渐变背景、内容滚动区、底部浮动 dock、mini player 承载、安全距离 | 首页、专辑、播放、喜爱四栏导航 | Vue router 转为 `go_router`；Flutter 用 `CustomScrollView`/`Stack` 承接壳层 |
| `src/components/library/mobile/ListenerMiniPlayer.vue` | `lib/widgets/mini_player.dart` | 黑色渐变圆角条、封面、标题、艺术家、播放/下一首按钮 | 点按进入播放页，播放/暂停，下一首 | 图标由 SVG 转 `FLucideIcons`，点击反馈由 `FTappable`/`FButton.icon` 承接 |
| `src/components/library/mobile/ListenerTrackActionSheet.vue` | `lib/widgets/listener_track_action_sheet.dart` | 歌曲 hero、关闭按钮、分组动作列表、播放列表子面板 | 下一首、队列、播放列表、喜爱、专辑、艺术家 | 专辑/艺术家查看使用搜索跳转兼容当前数据 ID 缺口；Sheet 使用 `showFSheet` |

## 页面映射

| 源文件 | Flutter 目标 | 结构与视觉 | 交互入口 | 差异记录 |
| --- | --- | --- | --- | --- |
| `ListenerDiscover.vue` | `lib/screens/home_screen.dart` | `Music` 标题、搜索/账号按钮、大封面推荐卡、播放列表快捷入口、新专辑、热门艺术家、风格浏览、歌曲列表 | 搜索、账号、播放推荐、进入专辑/艺术家/风格/播放列表 | 数据来自 `listenerHomeProvider` 聚合 Subsonic；空状态使用 Listener 浅色体系 |
| `ListenerAlbumLibrary.vue`、`ListenerAlbumList.vue` | `lib/screens/albums_screen.dart` | `专辑收藏` eyebrow、当前视图摘要、排序/筛选入口、专辑网格 | 播放第一张、随机一张、进入详情 | Subsonic 排序能力不足时由 provider 兼容映射 |
| `ListenerAlbumDetails.vue` | `lib/screens/album_detail_screen.dart` | 背景封面、唱片式封面舞台、元信息、动作按钮、曲目列表 | 播放、随机、下一首、队列、曲目操作 | Flutter 使用共享 `ListenerCoverArt` 和 `ListenerTrackRow` |
| `ListenerArtistLibrary.vue` | `lib/screens/artists_screen.dart` | 艺术家收藏标题、当前视图摘要、艺术家列表/网格 | 播放第一位、随机一位、进入详情 | 源页面无页内搜索，Flutter 已移除旧搜索框 |
| `ListenerArtistDetails.vue` | `lib/screens/artist_detail_screen.dart` | 艺术家背景、头像舞台、统计、专辑列表 | 播放热门、随机、全部歌曲、专辑详情 | 艺术家歌曲通过兼容接口/provider 获取 |
| `ListenerArtistTracks.vue` | `lib/screens/artist_tracks_screen.dart` | 艺术家歌曲页、专辑/歌曲上下文、歌曲列表 | 播放全部、随机、加入队列、曲目操作 | Subsonic 无统一热门曲目时按艺术家专辑歌曲聚合 |
| `ListenerTrackLibrary.vue`、`ListenerTrackList.vue` | `lib/screens/songs_screen.dart`、`lib/widgets/listener_components.dart` | 歌曲馆标题、筛选、随手开播摘要、歌曲行列表 | 播放全部、打乱、收藏、更多操作 | 歌曲行统一为 `ListenerTrackRow`，复用曲目 Sheet |
| `ListenerGenreLibrary.vue` | `lib/screens/genres_screen.dart` | 风格列表标题、筛选、当前视图摘要、风格卡片 | 播放风格、进入风格详情 | 使用 `getGenres` 和 `genreSongsProvider` |
| `ListenerGenreDetails.vue` | `lib/screens/genre_detail_screen.dart` | 风格详情 hero、统计、播放动作、歌曲列表 | 播放全部、随机、曲目操作 | 风格详情来自 Subsonic `getSongsByGenre` |
| `ListenerPlaylistLibrary.vue` | `lib/screens/playlist_management_screen.dart` | 播放列表标题、数量徽标、tabs、歌单入口摘要、列表 | 打开第一份、直接播放、创建/编辑/删除 | 创建/编辑/删除是本项目必要播放列表能力，视觉按 Listener 卡片行承接 |
| `ListenerPlaylistDetails.vue` | `lib/screens/playlist_detail_screen.dart` | 歌单封面舞台、元信息、播放动作、歌曲列表 | 播放、随机、下一首、队列、编辑/删除 | 管理动作保留为 Flutter app 必要能力 |
| `ListenerFavourites.vue` | `lib/screens/favorites_screen.dart` | 喜爱标题、数量徽标、专辑/艺术家/歌曲 tabs、摘要卡、列表/网格 | 播放全部、打乱、进入详情、取消收藏 | 使用 `getStarred2` 支持歌曲/专辑/艺术家 |
| `ListenerSearch.vue` | `lib/screens/search_screen.dart` | 返回按钮、`Search` eyebrow、输入框、开始/加载/无结果状态、结果分区 | 搜索、播放歌曲、进入专辑/艺术家 | 结果分区映射到 Subsonic search 返回结构 |
| `ListenerPlayingDetails.vue` | `lib/screens/player_screen.dart` | 返回、正在播放 eyebrow、caption、收藏、封面/歌词切换、唱片舞台、进度、播放控制 | 收藏、切换歌词、进度 seek、循环/上一首/播放/下一首/队列 | 源页面没有的投放/睡眠按钮已移除；进度曲线用 Forui slider 等价承接 |
| `ListenerQueueDetails.vue` | `lib/screens/play_queue_screen.dart` | 播放队列 eyebrow、继续聆听标题、当前播放暗色卡、动作卡、队列行、空状态 | 同播、播放/暂停、打乱、随机、清空、播放指定行、移除 | 构建期不创建真实音频服务，动作回调内懒读取 provider |
| `ListenerGroupCast.vue` | `lib/screens/group_cast_screen.dart` | 顶部栏、多端同播摘要、创建/离开、加入房间、成员、同步列表、歌词、聊天 | 创建房间、离开房间、加入、发送消息 | 当前实现为本机同步面板；真实多端后端能力待接入 |
| `ListenerAccountEntry.vue`、`ListenerAccountPage.vue` | `lib/screens/settings_screen.dart` | Account/个人配置 hero、头像首字母、用户名、角色、服务器、语言、播放偏好、连接、账户 | 语言选择、循环/随机、切换服务器、退出登录 | 源页面没有的外观/关于区块已移除；服务器配置为 Flutter app 必要能力 |
| `server config` app 必要页 | `lib/screens/server_config_screen.dart` | Listener 浅色背景、连接配置卡片、测试/保存动作 | 输入服务器、测试连接、保存 | 源 Listener 登录依赖 Web app 模式；Flutter 保留独立 Subsonic 配置页 |

## 通用状态

- 加载态：保持 Listener 浅色背景，使用轻量进度提示，不回退旧版 Material 页面框架。
- 空状态：使用 muted 图标、短文案、居中或卡片内空态，已覆盖首页、专辑、艺术家、歌曲、风格、喜爱页。
- 错误态：保留 Forui/Listener 体系的 toast、dialog 或错误视图，不引入旧发现/浏览信息架构。
- 封面缺失：统一走 `ListenerCoverArt` fallback 图标，避免空白封面。
- 音频相关页：播放/队列/账号页构建时避免主动创建真实音频播放器，动作回调再读取服务。
