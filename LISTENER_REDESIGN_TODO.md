# Listener 风格重构 TODO

目标：本项目所有用户可见页面以 `/Users/macbookair/coding/music-tag-web-v2/web` 中 Listener 页面体系为准，Flutter 版 Chanson 只保留 Listener 风格需要的布局、导航、功能页面和数据能力；不再需要的旧布局与功能入口在确认无依赖后删除。

## 当前补充结论

- [x] 已确认需要把 Forui 文档检查写入计划：本项目 UI 框架采用 Forui，页面层优先使用 Forui 组件，Listener 的特殊视觉只在共享 Listener 组件层用 Flutter 自定义样式承接。
- [x] 已确认需要把 Listener 源项目逐页对照写入计划：不能只凭当前页面印象改，要按源项目 `Listener*.vue` 文件逐项复刻信息结构、页面层级和交互入口。
- [x] 已确认需要增加“视觉规格提取”步骤：每个页面动手前先从 Listener 源文件记录标题文案、分区顺序、卡片比例、按钮动作、空状态和响应式差异，作为复刻验收依据。
- [x] 已确认需要增加“Forui API 复核”步骤：涉及 Scaffold、Button、Tile、Card、Tabs、Sheet、Dialog、Toast、Tooltip、图标时，先按 Forui 文档确认当前版本 API，再落到实现。
- [x] 已确认需要增加“截图级 UI 验收”步骤：仅代码可构建不算完成，关键页面需要在桌面和移动尺寸截图检查间距、遮挡、文字溢出、底部 dock/mini player 安全距离。
- [x] 需要补齐尚未覆盖的 Listener 页面/弹层：Group Cast/投放页。
- [x] 需要把旧页面删除拆成独立验收：旧发现/浏览/媒体类型/播放历史页面与入口已删除，scrobble 服务能力保留。
- [x] 需要补齐数据接口验收：艺术家歌曲/热门曲目、歌曲库分页或精确排序，否则相关页面只能使用兼容方案。
- [x] 需要补齐跨页面验收：每完成一组页面必须运行 `dart format`、`flutter analyze`，关键功能完成后运行 `flutter test`。

## 0. 复刻与 Forui 实现准则

- [x] 建立源页面视觉规格记录：
  - 每个 Listener 源文件至少记录一次页面标题、eyebrow、副标题、统计徽标、主操作按钮、筛选/页签、列表/网格顺序、空/加载/错误状态。
  - 对移动壳层、迷你播放器、曲目操作 Sheet 单独记录固定高度、底部安全距离、遮挡规则和点击区域。
  - 对与 Flutter 现有能力不完全一致的交互写明等价转换，例如 Web 端路由跳转改为 `go_router`、CSS 毛玻璃改为 Flutter 半透明/模糊层。
  - 证据：已新增 `LISTENER_SOURCE_VISUAL_SPEC.md`，逐项记录源 Listener 文件、Flutter 目标、结构视觉、交互入口和差异。
- [x] 每个页面实现前先查看源项目对应 Listener 文件：
  - 页面结构看 `src/views/library/**/Listener*.vue`
  - 全局移动壳层看 `src/components/library/mobile/ListenerMobileShell.vue`
  - 迷你播放器看 `src/components/library/mobile/ListenerMiniPlayer.vue`
  - 曲目操作弹层看 `src/components/library/mobile/ListenerTrackActionSheet.vue`
  - 通用卡片/网格看 `src/components/library/Tile.vue`、`src/components/library/Tiles.vue`、`src/components/library/Hero.vue`
- [x] Flutter 实现必须以 Forui 为主：
  - 页面壳层优先用 `FScaffold`
  - 顶部动作优先用 `FHeader`、`FHeaderAction`
  - 按钮优先用 `FButton`、`FButton.icon`
  - 列表项优先用 `FTile`、`FTileGroup`
  - 卡片容器优先用 `FCard`，但 Listener 首页的封面 Hero、浮动 dock、半透明快捷卡片可用 `Container`/`DecoratedBox` 自定义实现
  - 点击反馈优先用 `FTappable`
  - Toast、Dialog、Sheet、Tooltip 使用 Forui 对应组件
  - 图标统一使用 `FLucideIcons`
- [x] 不直接照搬 Vue/Tailwind/DaisyUI 组件，只复刻视觉结果、信息结构和交互节奏。
- [x] 建立 `Listener` 风格 Flutter 组件层，避免每个页面重复写样式：
  - `ListenerShell`
  - `ListenerMiniPlayer`
  - `ListenerSectionHeader`
  - `ListenerHeroCard`
  - `ListenerAlbumCard`
  - `ListenerArtistCard`
  - `ListenerGenreCard`
  - `ListenerTrackRow`
  - `ListenerDockNav`
- [x] Forui 文档使用约定：
  - 不确定组件 API 时查看 `.codex/skills/forui-docs/references/llms.txt`
  - 需要具体示例/API 时查看 `.codex/skills/forui-docs/references/llms-full.txt`
  - 改主题或响应式行为前先查 Forui Themes、Responsive、Scaffold、Button、Card、Tile、Navigation 相关文档
  - 弹层/菜单/提示优先查 Forui Sheet、Dialog、Toast、Popover、Tooltip 文档
  - Tab 页面优先查 Forui Tabs 文档，避免自行拼接不可访问的分段控件
- [x] Forui 落地边界：
  - 页面级结构优先 Forui；Listener 专属视觉如封面舞台、唱片动效、浮动 dock、黑色 mini player 可用自定义 Flutter widget。
  - 自定义 widget 内部仍优先复用 `FTappable`、`FButton.icon`、`FLucideIcons`，避免点击反馈和图标风格割裂。
  - Material 控件只作为 Flutter 基础能力或 Forui 缺口补充，使用前必须在 TODO 证据中说明原因。
  - 证据：已复核 Forui 文档索引和 `llms-full.txt` 中 `FScaffold`、`FButton`、`FCard`、`FTile`、`FTappable`、`showFDialog`、`FLucideIcons`、Responsive 相关 API；页面层保留 Forui 壳层/按钮/弹层，Listener 专属封面、dock、mini player 使用共享自定义组件。
- [x] Material 组件只在 Forui 没有合适替代时使用，并封装在 Listener 组件内部，避免页面层混杂两套风格。
- [x] 对源项目中不适合 Flutter/Forui 的实现做等价转换：
  - SVG 图标转换为 `FLucideIcons`
  - CSS `backdrop-filter` 转换为 `BackdropFilter` 或半透明渐变
  - Tailwind 间距/圆角/阴影转换为统一 Dart 常量
  - Vue router 行为转换为 `go_router`

## 1. 页面与功能盘点

- [x] 梳理源项目 Listener 页面清单：
  - 首页：`ListenerDiscover`
  - 移动壳层：`ListenerMobileShell`
  - 迷你播放器：`ListenerMiniPlayer`
  - 曲目操作：`ListenerTrackActionSheet`
  - 专辑：`ListenerAlbumLibrary`、`ListenerAlbumList`、`ListenerAlbumDetails`
  - 艺术家：`ListenerArtistLibrary`、`ListenerArtistDetails`、`ListenerArtistTracks`
  - 歌曲：`ListenerTrackLibrary`、`ListenerTrackList`
  - 播放列表：`ListenerPlaylistLibrary`、`ListenerPlaylistDetails`
  - 播放队列/正在播放：`ListenerPlayingDetails`、`ListenerQueueDetails`
  - 投放/分组播放：`ListenerGroupCast`
  - 搜索：`ListenerSearch`
  - 喜爱：`ListenerFavourites`
  - 账号：`ListenerAccountEntry`、`ListenerAccountPage`
  - 风格：`ListenerGenreLibrary`、`ListenerGenreDetails`
- [x] 梳理 Chanson 当前页面清单，并标记保留、替换、删除：
  - 保留但重做风格：`home_screen.dart`、`albums_screen.dart`、`album_detail_screen.dart`、`artists_screen.dart`、`artist_detail_screen.dart`、`search_screen.dart`、`favorites_screen.dart`、`playlist_management_screen.dart`、`playlist_detail_screen.dart`、`play_queue_screen.dart`、`player_screen.dart`
  - 待删除或并入 Listener 体系：`discover_screen.dart`、`browse_screen.dart`、旧 `library_screen.dart`、`media_type_settings_screen.dart`、`play_history_screen.dart`
  - 仅作为必要配置保留并改成 Listener/Forui 风格：`server_config_screen.dart`、`settings_screen.dart`
- [x] 确认旧功能中不属于 Listener 的内容移除：
  - 播客
  - 有声书
  - 电台
  - 下载管理占位
  - 旧版“发现/浏览内容/我的音乐”信息架构
- [x] 建立页面映射表并逐项验收：
  - `ListenerDiscover` -> `home_screen.dart`
  - `ListenerAlbumLibrary/List/Details` -> `albums_screen.dart`、`album_detail_screen.dart`
  - `ListenerArtistLibrary/Details/Tracks` -> `artists_screen.dart`、`artist_detail_screen.dart`、`artist_tracks_screen.dart`
  - `ListenerTrackLibrary/List` -> `songs_screen.dart`、`ListenerTrackRow`
  - `ListenerGenreLibrary/Details` -> 新增 `genres_screen.dart`、`genre_detail_screen.dart`
  - `ListenerPlaylistLibrary/Details` -> `playlist_management_screen.dart`、`playlist_detail_screen.dart`
  - `ListenerPlayingDetails/QueueDetails` -> `player_screen.dart`、`play_queue_screen.dart`
  - `ListenerSearch` -> `search_screen.dart`
  - `ListenerFavourites` -> `favorites_screen.dart`
  - `ListenerAccountEntry/Page` -> `settings_screen.dart`
  - `ListenerTrackActionSheet` -> `listener_track_action_sheet.dart`
  - `ListenerGroupCast` -> `group_cast_screen.dart`

## 2. Listener 全局壳层

- [x] 重构 `MainNavigationScreen` 为 Listener Shell：
  - 浅色渐变背景
  - 页面内容区
  - 底部浮动 dock
  - 黑色圆角迷你播放器
  - 四栏导航：首页、专辑、播放、喜爱
- [x] 改造 `MiniPlayer`：
  - 对齐源项目尺寸、圆角、暗色渐变、按钮样式
  - 无播放内容时可选择隐藏或显示 idle 状态
  - 播放/暂停、下一首保持可用
- [x] 统一页面底部安全距离，避免内容被 dock 和迷你播放器遮挡。
- [x] 移除旧 Forui `FBottomNavigationBar` 的视觉依赖。

## 3. 首页复刻

- [x] 将 `HomeScreen` 改为 Listener 首页：
  - 顶部标题区：`Music`、`为你打开今天的旋律`
  - 搜索按钮
  - 账号/设置按钮
  - 大封面 Hero 推荐卡片
  - 播放列表快捷入口
  - 新专辑 3 列卡片
  - 热门艺术家 3 列圆形头像卡片
  - 风格浏览 2 列卡片
  - 歌曲列表
- [x] 首页数据源映射：
  - Hero：优先随机歌曲第一首
  - 新专辑：`recentAlbumsProvider`
  - 热门艺术家：新增/复用 artists provider
  - 风格：新增 genres provider
  - 歌曲列表：`randomSongsProvider`
- [x] 首页交互：
  - Hero 点击播放推荐歌曲
  - 歌曲行点击播放随机歌曲队列
  - 专辑卡进入专辑详情
  - 艺术家卡进入艺术家详情
  - 风格卡进入风格详情或风格歌曲列表
  - 搜索按钮进入搜索
  - 播放列表入口进入播放列表页
- [x] 首页 Forui/Listener 验收：
  - 搜索、设置等图标按钮使用 `FButton.icon` 或封装后的 `ListenerCircleButton`
  - 卡片点击反馈使用 `FTappable`
  - 风格卡必须接真实 `genresProvider`，不能长期使用随机歌曲 genre 推断
  - 空数据、加载、错误状态视觉必须与 Listener 浅色体系一致

## 4. 音乐库页面体系

- [x] 专辑页按 Listener 风格重做：
  - 最近添加/A-Z/随机等排序入口
  - 网格卡片样式与源项目一致
  - 详情页 Hero 使用封面背景
  - 播放全部、随机播放、歌曲列表
- [x] 艺术家页按 Listener 风格重做：
  - 艺术家网格/列表
  - 艺术家详情 Hero
  - 艺术家专辑入口
  - 艺术家歌曲入口（待补数据接口）
- [x] 艺术家歌曲页补齐：
  - 对照 `ListenerArtistTracks.vue`
  - 补数据接口或明确 Subsonic 兼容方案
  - 播放全部、随机播放、加入队列保持可用
- [x] 歌曲页按 Listener 风格重做：
  - 对照 `ListenerTrackLibrary.vue`、`ListenerTrackList.vue`
  - 歌曲列表行样式
  - 时长、封面、艺术家信息
  - 喜爱按钮
  - 播放、加入队列、加入播放列表
- [x] 风格页补齐：
  - 对照 `ListenerGenreLibrary.vue`、`ListenerGenreDetails.vue`
  - `SubsonicService.getGenres`
  - repository/provider
  - 风格列表
  - 风格详情歌曲列表
- [x] 播放列表页按 Listener 风格重做：
  - 播放列表库
  - 播放列表详情
  - 创建/编辑/删除保留，但视觉改为 Listener/Forui 风格
- [x] 喜爱页按 Listener 风格重做：
  - 喜爱歌曲
  - 喜爱专辑
  - 喜爱艺术家，如后端接口支持
  - 未补真实 `getStarred2` 前，专辑/艺术家页签不能标记完成
- [x] 搜索页按 Listener 风格重做：
  - 搜索输入
  - 歌曲、专辑、艺术家结果分区
  - 点击结果进入对应详情或播放
- [x] 播放队列页按 Listener 风格重做：
  - 当前播放卡片
  - 打乱、随机、清空动作
  - 队列歌曲列表
- [x] 正在播放页按 Listener 风格重做：
  - 大封面
  - 歌曲信息
  - 播放进度
  - 播放控制
  - 当前队列
- [x] 账号/设置页按 Listener 风格重做：
  - 对照 `ListenerAccountEntry.vue`、`ListenerAccountPage.vue`
  - 保留服务器配置入口、退出/清理本地配置等必要能力
  - 移除多媒体类型设置入口
- [x] 曲目操作 Sheet 补齐：
  - 对照 `ListenerTrackActionSheet.vue`
  - 使用 Forui `showFSheet`
  - 支持播放、下一首播放、加入队列、加入播放列表、收藏/取消收藏、查看专辑/艺术家

## 5. 数据层补齐

- [x] 补齐标准 Subsonic 接口：
  - [x] `getGenres`
  - [x] `getSongsByGenre`
  - [x] `star`
  - [x] `unstar`
  - [x] `getStarred2`
  - [x] 艺术家热门歌曲或艺术家歌曲列表兼容接口
  - [x] 歌曲库列表接口与排序/分页参数
  - [x] 必要时补 `getSong`
- [x] 整理 provider：
  - [x] `genresProvider`
  - [x] `genreSongsProvider`
  - [x] `artistsProvider`
  - [x] `starredProvider`
  - [x] `artistSongsProvider` 或 `artistTopTracksProvider`
  - [x] `songsLibraryProvider`
  - [x] Listener 首页聚合 provider
- [x] 检查缓存策略：
  - 避免不同列表共用同一个 Hive box 导致互相覆盖
  - 为专辑、歌曲、艺术家列表增加按类型区分的缓存 key
- [x] 确保播放服务支持：
  - 设置队列
  - 从指定 index 播放
  - 下一首/上一首
  - 当前队列展示

## 6. 删除旧布局与入口

- [x] 删除或停止引用旧页面：
  - [x] `discover_screen.dart`
  - [x] `browse_screen.dart`
  - [x] 旧版 `library_screen.dart`
  - [x] `media_type_settings_screen.dart`
  - [x] `play_history_screen.dart`，除非能映射到 Listener 页面并完成视觉重做
- [x] 删除旧路由：
  - [x] `/media-type-settings`
  - [x] `/play-history`，除非保留为 Listener 风格历史页
  - 旧发现页入口
  - 旧浏览页入口
  - 不再需要的多媒体类型入口
- [x] 清理设置页旧入口：
  - 删除 `settings_screen.dart` 中跳转 `/media-type-settings` 的入口
  - 账号/设置页改为 Listener Account 体系
- [x] 清理旧 UI 组件：
  - 不再使用的旧卡片 builder
  - 旧 quick access 入口
  - 旧多媒体占位组件
- [x] 检查 `pubspec.yaml` 依赖，确认是否有未使用依赖可移除。
- [x] 保留必要基础能力：
  - 服务器配置
  - 设置
  - 播放服务
  - 收藏服务
  - 播放列表服务
  - Subsonic API 服务

## 7. 视觉一致性检查

- [x] 每个页面完成后对照源 Listener 文件检查，并在验收时记录对应源文件：
  - 页面层级是否一致
  - 标题、分区、入口顺序是否一致
  - 卡片比例、圆角、阴影、间距是否一致
  - 点击目标和导航路径是否一致
- [x] 每个页面记录复刻差异：
  - 完全一致项：结构、文案、入口、视觉层级。
  - Flutter/Forui 等价转换项：组件替换、路由替换、平台能力差异。
  - 暂不复刻项：必须说明原因，例如源项目依赖后端能力但本项目暂缺接口。
  - 证据：`LISTENER_SOURCE_VISUAL_SPEC.md` 已记录每个源页面/组件的 Flutter 映射与差异；`LISTENER_REDESIGN_TODO.md` 的逐页复核清单已写入页面级证据。
- [x] Listener 源文件逐页复核清单：
  - [x] `ListenerMobileShell.vue` -> `main_navigation_screen.dart`
    - 证据：已对照源页面浅色渐变背景、顶部/底部 glow、内容区底部安全距离、底部浮动 dock、四栏首页/专辑/播放/喜爱导航和迷你播放器承载结构。
  - [x] `ListenerMiniPlayer.vue` -> `mini_player.dart`
    - 证据：已对照源页面 idle/播放态文案、暗色渐变圆角容器、封面、标题/艺术家、播放/暂停和下一首按钮。
  - [x] `ListenerDiscover.vue` -> `home_screen.dart`
    - 证据：已对照源页面 `Music` 标题、搜索/账号动作、大封面推荐卡、播放列表快捷入口、新专辑、热门艺术家、风格浏览和歌曲列表结构。
  - [x] `ListenerAlbumLibrary.vue`、`ListenerAlbumDetails.vue` -> `albums_screen.dart`、`album_detail_screen.dart`
    - 进展：已对照 `ListenerAlbumLibrary.vue`，补齐 `专辑收藏` eyebrow、`当前视图` 摘要卡、`播放第一张`/`随机一张` 动作、最近播放/最多播放/缺失封面筛选入口。
    - 证据：已对照 `ListenerAlbumDetails.vue`，详情页具备背景封面、唱片式封面舞台、专辑元信息、播放/随机/下一首/队列动作和曲目列表。
  - [x] `ListenerArtistLibrary.vue`、`ListenerArtistDetails.vue`、`ListenerArtistTracks.vue` -> `artists_screen.dart`、`artist_detail_screen.dart`、`artist_tracks_screen.dart`
    - 进展：已对照 `ListenerArtistLibrary.vue`，补齐 `当前视图` 摘要卡、`播放第一位`/`随机一位` 动作，移除源页面没有的页面内搜索框，并让行尾播放按钮真实播放艺术家歌曲。
    - 证据：已对照 `ListenerArtistDetails.vue`，详情页具备背景封面、艺术家封面舞台、播放热门/随机/全部歌曲动作、专辑列表；已对照 `ListenerArtistTracks.vue` 的专辑/歌曲切换与列表结构。
  - [x] `ListenerTrackLibrary.vue`、`ListenerTrackList.vue` -> `songs_screen.dart`、`ListenerTrackRow`
    - 证据：已对照源页面标题、筛选、`随手开播` 摘要卡、`播放全部`/`打乱` 动作、歌曲列表和空状态结构。
  - [x] `ListenerGenreLibrary.vue`、`ListenerGenreDetails.vue` -> `genres_screen.dart`、`genre_detail_screen.dart`
    - 证据：已对照源页面风格筛选、`当前视图` 摘要卡、风格卡片、播放风格入口、风格详情歌曲列表和空状态结构。
  - [x] `ListenerPlaylistLibrary.vue`、`ListenerPlaylistDetails.vue` -> `playlist_management_screen.dart`、`playlist_detail_screen.dart`
    - 证据：已对照源页面播放列表标题/数量徽标、最近添加/A-Z tabs、`歌单入口` 摘要卡、`打开第一份`/`直接播放` 动作、列表行播放入口、详情页封面舞台、播放/随机/队列和歌曲列表结构。
  - [x] `ListenerPlayingDetails.vue`、`ListenerQueueDetails.vue` -> `player_screen.dart`、`play_queue_screen.dart`
    - 证据：已对照 `ListenerPlayingDetails.vue`，播放页保留返回、正在播放 eyebrow、专辑/艺术家 caption、收藏按钮、封面/歌词切换、唱片封面舞台、歌词舞台、歌曲元信息、进度、循环/上一首/播放/下一首/队列控制；已移除源页面没有的投放和睡眠定时器顶部按钮。
    - 证据：已对照 `ListenerQueueDetails.vue`，队列页具备播放队列 eyebrow、继续聆听标题、非空时 `同播` 入口、当前播放暗色卡片、打乱/随机/清空动作、队列行、当前项高亮、移除按钮和空状态。
  - [x] `ListenerSearch.vue` -> `search_screen.dart`
    - 证据：已对照源页面返回按钮、`Search` eyebrow、搜索输入、加载/开始搜索/无结果状态、艺术家/专辑/歌曲结果分区结构。
  - [x] `ListenerFavourites.vue` -> `favorites_screen.dart`
    - 证据：已对照源页面喜爱标题/数量徽标、专辑/艺术家/歌曲 tabs、`我的收藏` 摘要卡、歌曲播放全部/打乱、专辑网格、艺术家列表、歌曲列表和空状态结构。
  - [x] `ListenerAccountEntry.vue`、`ListenerAccountPage.vue` -> `settings_screen.dart`
    - 证据：已对照源页面，账号页保留 Account/个人配置 hero、头像首字母、用户名、听众角色、服务器地址、语言、播放偏好、连接/切换服务器、账户/退出登录结构；已移除源页面没有的外观和关于区块。
  - [x] `ListenerTrackActionSheet.vue` -> `listener_track_action_sheet.dart`
    - 证据：已对照源页面歌曲操作 hero、关闭按钮、添加下一首、添加到队列、添加到播放列表、添加/移出喜爱、播放列表子面板和空播放列表状态；Flutter 版保留查看专辑/艺术家入口为搜索跳转兼容方案。
  - [x] `ListenerGroupCast.vue` -> `group_cast_screen.dart`
    - 证据：已对照源页面顶部栏、`多端同播` 摘要、创建/离开房间、加入房间、成员、同步列表、滚动歌词和房间聊天结构；当前实现为本机同步面板，待后端同步能力接入后再补真实多端状态。
- [x] 每个页面完成后检查 Forui 使用：
  - 页面壳层是否用 `FScaffold` 或被 Listener Shell 统一承载
  - 主要按钮是否用 `FButton`/`FButton.icon`
  - 列表项是否优先用 `FTile`/`FTileGroup` 或统一 `ListenerTrackRow`
  - 页签是否使用 `FTabs` 或封装后的 Listener 等价组件
  - Toast/Dialog/Sheet/Tooltip 是否使用 Forui 对应 API
- [x] Forui 文档/API 复核清单：
  - [x] 复核 `FScaffold`、`FHeader`、`FHeaderAction` 用法，避免页面壳层和导航语义不一致
  - [x] 复核 `FButton`、`FButton.icon`、`FTappable` 用法，确保点击反馈和禁用状态一致
  - [x] 复核 `FTile`、`FTileGroup`、`FCard` 用法，避免在页面层混入旧 Material 视觉
  - [x] 复核 `showFSheet`、`showFDialog`、`showFToast` 用法，统一弹层、确认框、提示反馈
  - [x] 复核 `FTabs` 或 Listener 等价页签封装，确保喜爱/搜索等分区切换可访问
  - [x] 复核 `FLucideIcons` 图标映射，确保所有页面动作图标风格统一
  - [x] 复核 Forui 主题/颜色 token，确认 Listener 浅色背景、文字色、边框、阴影不会被全局主题破坏
  - [x] 复核 Forui 响应式文档，确认桌面宽屏和手机窄屏布局策略一致
  - 证据：已使用 `.codex/skills/forui-docs/references/llms.txt` 与 `llms-full.txt` 复核组件 API，并用 `rg` 检查页面/组件中的 `FScaffold`、`FButton`、`FTappable`、`FTile`、`FCard`、`showFSheet`、`showFDialog`、`showFToast`、`FTabs`/等价封装、`FLucideIcons` 使用。
- [x] 建立 Listener 风格常量：
  - 背景渐变
  - 主文字色 `#111827`
  - 次级文字色 `#94a3b8`
  - 卡片白色半透明背景
  - 圆角尺寸
  - 阴影
  - 页面间距
- [x] 全页面检查：
  - 圆角、阴影、按钮尺寸一致
  - 卡片不嵌套卡片
  - 移动端文字不溢出
  - 底部 dock 不遮挡内容
  - 深色模式策略明确：先以 Listener 浅色风格为准，必要时后续补深色适配
  - 证据：已用 `rg` 复核 `ListenerShadows`、`borderRadius`、`TextOverflow.ellipsis`、`SafeArea`、底部 padding、`FCard`/`Card` 使用；页面卡片主要由 `listener_components.dart` 统一承接，`FCard` 仅保留在弹层/配置表单等框定工具中；动态标题/歌曲/专辑/艺术家文本均使用 `maxLines`/`ellipsis`；主页面滚动区底部保留 32px padding，壳层另有 dock/mini player 安全距离。
- [x] 统一图标：
  - 优先使用 `FLucideIcons`
  - 移除手写 SVG 思路，Flutter 中使用图标库表达相同含义

## 8. 验证与收尾

- [x] 每完成一组页面运行：
  - `dart format` 仅格式化本次改动的 Dart 文件
  - `flutter analyze`
- [x] 功能验证：
  - [x] 登录/服务器配置
  - [x] 首页加载
  - [x] 搜索
  - [x] 专辑详情
  - [x] 艺术家详情
  - [x] 播放歌曲
  - [x] 迷你播放器
  - [x] 播放队列
  - [x] 收藏/取消收藏
  - [x] 播放列表详情
  - 备注：已补充 `test/widget_test.dart` 页面级 smoke tests，覆盖服务器配置页、Listener 首页、专辑/艺术家/歌曲/风格/喜爱/播放列表/GroupCast/搜索库页、专辑/艺术家/艺术家曲库/风格/播放列表详情页在 fake Subsonic 数据下可构建。
  - 备注：播放页、队列页、账号页直接 widget pump 会触发音频服务 stream，当前未纳入 smoke tests；后续如需测试这些页面，应先抽象 fake audio provider，避免测试进程挂起。
  - 备注：已将账号页播放偏好和队列页播放/清空/移除动作改为点击回调内懒读取 `audioPlayerServiceProvider`，避免页面构建期创建真实 `just_audio` 服务。
  - 备注：播放页、曲目操作 Sheet、喜爱页、艺术家详情页已检查收藏接口返回值，接口返回 `false` 时显示失败 toast，成功时才刷新收藏数据。
  - 备注：`test/widget_test.dart` 已用 fake audio stream providers 覆盖 mini player 有歌曲态、播放中图标、队列页非空态、当前播放卡、`同播` 入口和队列歌曲行。
  - 备注：`AudioPlayerService` 已抽象 `AudioPlaybackBackend`；`test/widget_test.dart` 使用 fake backend 覆盖 `setPlaylist` -> `playAtIndex` -> 当前歌曲/队列/索引更新 -> 后端 `setUrl`/`play` 调用链路。
  - 备注：`test/widget_test.dart` 已覆盖喜爱页收藏取消成功反馈和接口失败反馈。
- [ ] UI 验证：
  - macOS 桌面窗口
  - iPhone 尺寸
  - Android 常见尺寸
  - Web Chrome，如仍需支持
  - 关键截图必须覆盖：首页、专辑详情、艺术家详情、歌曲库、播放列表详情、播放页、队列页、搜索页、账号页、GroupCast。
  - 截图检查项：首屏信息密度、底部 dock/mini player 遮挡、长标题换行、按钮文字溢出、封面缺失 fallback、空状态是否仍是 Listener 浅色体系。
  - 备注：`flutter build macos --debug` 已尝试，但当前环境缺少 `xcodebuild`，无法完成 macOS 构建验证；命令已触发 Flutter macOS 工程兼容迁移。
  - 备注：`flutter build web --debug` 已尝试，但当前项目未配置 web 平台目录。
- [x] 删除确认：
  - `rg` 检查被删除页面无引用
  - 路由表无死路由
  - import 无废弃引用
- [x] 空/加载/错误状态验证：
  - [x] 未连接服务器：已用 widget test 覆盖未配置服务器时显示服务器配置页
  - [x] API 返回空列表：已用 widget test 覆盖首页、专辑、艺术家、歌曲、风格、喜爱页空状态
  - [x] 封面缺失：页面统一使用 `ListenerCoverArt` fallback；fake Subsonic 数据不提供 cover URL，现有页面 smoke tests 覆盖无封面可构建
  - [x] 搜索无结果
    - 证据：`SearchScreen` 已增加 `initialQuery`，并在已有 `searchResultProvider` 状态时只预填、不覆盖结果；`test/widget_test.dart` 已覆盖空 `SearchResult` 下展示 `没有找到结果`。
  - [x] 收藏接口失败
    - 证据：播放页、曲目操作 Sheet、喜爱页、艺术家详情页已补失败 toast 和成功后再 invalidate 的行为；`test/widget_test.dart` 已用 fake Subsonic `favoriteSucceeds = false` 覆盖喜爱页取消收藏失败反馈。
- [x] 最终运行：
  - `flutter test`
  - `flutter analyze`

## 建议实施顺序

1. 先做 Shell、底部 dock、迷你播放器。
2. 再做首页，因为首页能验证整体视觉基调和核心数据链路。
3. 接着做专辑、艺术家、搜索、播放页、队列页。
4. 再补风格库和歌曲库，因为它们依赖新增接口/provider。
5. 再补播放列表、喜爱、曲目操作 Sheet、账号/设置页。
6. 最后删除旧页面和旧路由，并做全量验证。

删除旧页面应放在主要 Listener 页面跑通之后执行，避免中途破坏导航与验证路径。
