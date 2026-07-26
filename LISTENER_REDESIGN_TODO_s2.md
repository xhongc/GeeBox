# Listener 风格重构第二阶段 TODO

目标：本项目所有用户可见页面以 `/Users/macbookair/coding/music-tag-web-v2/web` 中 Listener 页面体系为准，Flutter 版 Chanson 只保留 Listener 风格需要的布局、导航、功能页面和数据能力；不再需要的旧布局与功能入口在确认无依赖后删除。

## 当前补充结论
已经完成./LISTENER_REDESIGN_TODO.md 改造了。

## 任务
现在还有一些优化点。

## 完成状态

已完成下面 8 个优化点，并通过 `flutter analyze` 与 `flutter test` 验证。

## 第二阶段安排

### P0：先修复影响使用的播放与布局问题

1. [x] 修复首页“热门艺术家”区域 bottom overflowed by 11 pixels
   - 涉及文件：`lib/screens/home_screen.dart`、必要时 `lib/widgets/listener_components.dart`。
   - 现状判断：热门艺术家使用 `ListenerArtistCard`，卡片内部头像、间距、标题高度固定，首页网格高度不足时容易在小屏或字体放大时溢出。
   - 执行安排：
     - 复查首页 `_ArtistGrid` 的 `childAspectRatio`、卡片固定尺寸和底部间距。
     - 优先通过提高热门艺术家网格单元高度、收紧卡片内部垂直间距或给标题区稳定高度解决。
     - 保持“热门艺术家”卡片视觉不变，不为了解 overflow 改成列表。
   - 验收：
     - iPhone 小屏宽度、默认字体和较大字体下首页不再出现 bottom overflow。
     - 热门艺术家标题仍能单行省略，卡片之间无明显跳动。

2. [x] 歌曲播放时避免一直重复调用封面接口
   - 涉及文件：`lib/widgets/listener_components.dart`、`lib/screens/player_screen.dart`、`lib/widgets/mini_player.dart`、各列表页的封面 URL 生成处。
   - 现状判断：`ListenerCoverArt` 直接使用 `Image.network`；播放页、迷你播放器和列表在 build 中重复拼接封面 URL。Flutter 图片缓存通常按 URL 缓存已解码图片，但若 URL 内含动态认证参数或组件频繁重建，仍可能造成重复请求。
   - 执行安排：
     - 先确认 `SubsonicService.getCoverArtUrl` 是否每次生成不同 query（尤其 token、salt、timestamp）。
     - 为封面 URL 增加稳定化策略：同一 `coverArtId + size` 返回相同 URL，必要时在 repository/service 层做内存缓存。
     - 为 `ListenerCoverArt` 增加稳定 `key` 或复用 `NetworkImage` 的入口，避免播放进度刷新导致封面 widget 被当作新图片加载。
     - 优先改共用封面组件，避免每个页面单独修补。
   - 验收：
     - 播放进度更新期间，同一首歌封面不持续触发新的 `getCoverArt` 网络请求。
     - 切歌后只请求新歌封面；返回已播放歌曲时应命中缓存。

3. [x] 歌词根据音乐播放进度滚动
   - 涉及文件：`lib/widgets/lyrics_widget.dart`、`lib/screens/player_screen.dart`、`lib/providers/lyrics_provider.dart`、必要时歌词 service。
   - 现状判断：`LyricsWidget` 只展示整段文本，未接入 `positionProvider`，也未解析 LRC 时间标签。
   - 执行安排：
     - 让播放页把当前播放进度传入歌词组件，或在 `LyricsWidget` 内 watch `positionProvider`。
     - 增加 LRC 解析：支持 `[mm:ss.xx]`、多时间标签同一句、无时间标签纯文本降级展示。
     - 使用 `ScrollController` 或 `Scrollable.ensureVisible` 将当前歌词行滚动到舞台中部。
     - 当前歌词行高亮，前后歌词降低透明度；纯文本歌词保持现在的居中滚动视图。
   - 验收：
     - 有 LRC 时间轴时，播放进度变化会自动滚动并高亮当前行。
     - seek 后歌词位置能在短时间内跳到对应行。
     - 无时间轴歌词不报错、不乱滚。

4. [x] 正在播放页面调整专辑封面和黑色碟片布局
   - 涉及文件：`lib/screens/player_screen.dart`。
   - 现状判断：`_CoverStage` 里碟片 `right: 36`、封面 `left: 20`，整体偏左；需求是专辑封面左右居中，黑色碟片只从一侧露出一部分。
   - 执行安排：
     - 将封面作为视觉中心：用 `Align(alignment: Alignment.center)` 固定封面位置。
     - 碟片放在封面右后侧，露出约 18%-28% 宽度；用 `Positioned` + `Transform.translate` 或居中坐标计算实现。
     - 保留旋转动画和阴影，但降低碟片抢占视觉中心的程度。
   - 验收：
     - 封面中心与页面内容中心对齐。
     - 碟片只露出一部分，不让封面看起来偏移。
     - 小屏下封面和碟片不越界。

### P1：统一卡片和页面视觉

5. [x] 风格浏览卡片改得更像热门艺术家卡片，去掉部分渐变样式
   - 涉及文件：`lib/screens/genres_screen.dart`、`lib/screens/home_screen.dart`、必要时 `lib/widgets/listener_components.dart`。
   - 现状判断：风格页 `_GenreLibraryCard` 内部 `_GenreArt` 使用明显渐变；首页 `ListenerGenreCard` 是更轻的白色卡片；热门艺术家卡片是白底/轻渐变、圆角、阴影、头像式中心内容。
   - 执行安排：
     - 将风格卡片背景调整为接近热门艺术家卡片的白色半透明卡片。
     - 弱化或移除 `_GenreArt` 的多色渐变，改成简单图标、浅色块或类似艺术家头像的中心视觉。
     - 保留风格名称、专辑数、歌曲数和右上播放按钮。
   - 验收：
     - 风格浏览不再像彩色渐变海报，整体更接近热门艺术家卡片语言。
     - 首页风格卡片与风格页卡片风格一致，但尺寸可按各自布局适配。

6. [x] 全部专辑“当前视图”的背景颜色改为暗色
   - 涉及文件：`lib/screens/albums_screen.dart`。
   - 现状判断：`_AlbumsSummary` 当前是白色半透明背景，和需求的暗色当前视图不一致。
   - 执行安排：
     - 将 `_AlbumsSummary` 容器改成暗色背景，文字改成白色/浅灰层级。
     - 两个操作按钮在暗色背景下保持可读：主按钮可使用白底深字，次按钮使用半透明描边或暗底浅字。
   - 验收：
     - “当前视图”卡片在全部专辑页面明显是暗色块。
     - 文本、按钮、禁用状态在暗色背景下对比度足够。

7. [x] 全部专辑、全部艺术家页面增加类似首页的背景，并让黑色和红色区域虚化
   - 涉及文件：`lib/screens/albums_screen.dart`、`lib/screens/artists_screen.dart`、`lib/widgets/listener_components.dart` 或 `lib/screens/main_navigation_screen.dart`。
   - 参考来源：必要时查看 `/Users/macbookair/coding/music-tag-web-v2/web` 中 Listener 页面背景实现，确认黑色/红色背景块的尺寸、位置和 blur 强度。
   - 执行安排：
     - 提取可复用的 Listener 背景容器或背景装饰，避免 albums/artists 各写一套。
     - 在全部专辑、全部艺术家页面底层加入与首页同系的背景。
     - 黑色和红色区域使用 `ImageFilter.blur` 或 `BackdropFilter`/模糊装饰层处理，避免硬边色块。
     - 确认暗色 summary 与背景之间有足够层次。
   - 验收：
     - 全部专辑、全部艺术家不再是单纯平面浅色背景。
     - 黑色和红色区域呈现柔化/虚化效果，没有生硬边缘。
     - 滚动列表时背景稳定，不影响性能和点击。

### P2：整理歌曲列表操作区

8. [x] 歌曲列表中的收藏和歌曲操作按钮放在同一行
   - 涉及文件：`lib/widgets/listener_components.dart`，调用处包括 `lib/screens/home_screen.dart`、`lib/screens/songs_screen.dart`、`lib/screens/album_detail_screen.dart`、`lib/screens/playlist_detail_screen.dart`、`lib/screens/genre_detail_screen.dart`、`lib/screens/search_screen.dart`。
   - 现状判断：`ListenerTrackRow` 右侧目前是竖向 `Column`，时长、收藏、更多按钮上下排列，收藏和更多按钮不在同一行。
   - 执行安排：
     - 将右侧操作区改成稳定宽度的纵向结构：第一行显示时长，第二行用 `Row` 横向放收藏按钮和更多按钮。
     - 若没有 `onMore`，收藏按钮仍对齐在操作行，不影响行高。
     - 检查各列表页传入 `onFavorite`、`onMore` 后的点击热区，避免与整行播放点击冲突。
   - 验收：
     - 收藏心形按钮和更多操作按钮在同一水平行。
     - 歌曲标题/艺术家区域不会被操作按钮挤压到不可读。
     - 没有更多按钮的列表行仍布局自然。

## 建议执行顺序

1. 先修 `ListenerTrackRow`、`ListenerCoverArt`、`LyricsWidget` 这类共用组件，减少页面重复修改。
2. 再处理 `player_screen.dart` 的封面/碟片和歌词舞台，因为它同时依赖封面缓存与歌词进度。
3. 然后处理 `home_screen.dart` 首页热门艺术家 overflow 和 `genres_screen.dart` 风格卡片。
4. 最后统一 `albums_screen.dart`、`artists_screen.dart` 的背景和全部专辑暗色当前视图。

## 验证清单

- 运行 `flutter analyze`。
- 运行 `flutter test`。
- 使用 `flutter run -d macos` 或目标设备检查：
  - 首页热门艺术家无 overflow。
  - 风格浏览卡片视觉接近热门艺术家卡片。
  - 歌曲行收藏/更多按钮同排。
  - 正在播放页封面居中，碟片仅露出一部分。
  - 播放时封面接口不因进度刷新重复请求。
  - LRC 歌词能随播放和 seek 滚动。
  - 全部专辑当前视图为暗色。
  - 全部专辑、全部艺术家背景与首页同系，黑色/红色区域已虚化。
