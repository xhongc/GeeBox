import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/media_type_settings_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';
import 'settings_screen.dart';

// 音乐库统计 Provider
final libraryStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getLibraryStats();
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => false; // 不保持状态，每次都重新构建

  TabController? _tabController;
  List<String> _enabledTabs = [];

  @override
  void initState() {
    super.initState();
    _updateTabs();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabs() {
    final mediaSettings = ref.read(mediaTypeSettingsProvider);
    _enabledTabs = [];

    if (mediaSettings.musicEnabled) _enabledTabs.add('music');
    if (mediaSettings.podcastEnabled) _enabledTabs.add('podcast');
    if (mediaSettings.audiobookEnabled) _enabledTabs.add('audiobook');
    if (mediaSettings.radioEnabled) _enabledTabs.add('radio');

    // 如果有多个类型，创建 TabController
    if (_enabledTabs.length > 1) {
      _tabController?.dispose();
      _tabController = TabController(
        length: _enabledTabs.length,
        vsync: this,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    final mediaSettings = ref.watch(mediaTypeSettingsProvider);
    final playlistsAsync = ref.watch(playlistsProvider);
    final statsAsync = ref.watch(libraryStatsProvider);

    // 更新 tabs（如果设置改变）
    final newEnabledTabs = <String>[];
    if (mediaSettings.musicEnabled) newEnabledTabs.add('music');
    if (mediaSettings.podcastEnabled) newEnabledTabs.add('podcast');
    if (mediaSettings.audiobookEnabled) newEnabledTabs.add('audiobook');
    if (mediaSettings.radioEnabled) newEnabledTabs.add('radio');

    if (newEnabledTabs.toString() != _enabledTabs.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _updateTabs();
        });
      });
    }

    // 如果只有一个类型，直接显示内容，不显示 Tab
    if (_enabledTabs.length == 1) {
      return _buildSingleTypeView(
          _enabledTabs.first, playlistsAsync, statsAsync);
    }

    // 如果有多个类型，显示 TabBar
    return _buildMultiTypeView(playlistsAsync, statsAsync);
  }

  Widget _buildSingleTypeView(
    String type,
    AsyncValue playlistsAsync,
    AsyncValue<Map<String, int>> statsAsync,
  ) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            floating: true,
            title: Text(
              _getTypeTitle(type),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (type == 'music')
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    context.push('/playlist-management');
                  },
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 根据类型显示不同内容
          ..._buildTypeContent(type, playlistsAsync, statsAsync),

          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  Widget _buildMultiTypeView(
    AsyncValue playlistsAsync,
    AsyncValue<Map<String, int>> statsAsync,
  ) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 顶部应用栏
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text(
                '音乐库',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    context.push('/playlist-management');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
              bottom: _tabController != null
                  ? TabBar(
                      controller: _tabController,
                      tabs: _enabledTabs.map((type) {
                        return Tab(text: _getTypeTitle(type));
                      }).toList(),
                    )
                  : null,
            ),
          ];
        },
        body: _tabController != null
            ? TabBarView(
                controller: _tabController,
                children: _enabledTabs.map((type) {
                  return CustomScrollView(
                    slivers: [
                      ..._buildTypeContent(type, playlistsAsync, statsAsync),
                      const SliverToBoxAdapter(child: SizedBox(height: 150)),
                    ],
                  );
                }).toList(),
              )
            : const SizedBox(),
      ),
    );
  }

  String _getTypeTitle(String type) {
    switch (type) {
      case 'music':
        return '音乐';
      case 'podcast':
        return '播客';
      case 'audiobook':
        return '有声书';
      case 'radio':
        return '电台';
      default:
        return '音乐库';
    }
  }

  List<Widget> _buildTypeContent(
    String type,
    AsyncValue playlistsAsync,
    AsyncValue<Map<String, int>> statsAsync,
  ) {
    switch (type) {
      case 'music':
        return _buildMusicContent(playlistsAsync, statsAsync);
      case 'podcast':
        return _buildPodcastContent();
      case 'audiobook':
        return _buildAudiobookContent();
      case 'radio':
        return _buildRadioContent();
      default:
        return [];
    }
  }

  List<Widget> _buildMusicContent(
    AsyncValue playlistsAsync,
    AsyncValue<Map<String, int>> statsAsync,
  ) {
    return [
      // 统计卡片
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '歌曲',
                    '${stats['songs'] ?? 0}',
                    Icons.music_note,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '专辑',
                    '${stats['albums'] ?? 0}',
                    Icons.album,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: playlistsAsync.when(
                    data: (playlists) => _buildStatCard(
                      '歌单',
                      '${playlists.length}',
                      Icons.playlist_play,
                      Colors.green,
                    ),
                    loading: () => _buildStatCard(
                      '歌单',
                      '0',
                      Icons.playlist_play,
                      Colors.green,
                    ),
                    error: (_, __) => _buildStatCard(
                      '歌单',
                      '0',
                      Icons.playlist_play,
                      Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '歌曲',
                    '...',
                    Icons.music_note,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '专辑',
                    '...',
                    Icons.album,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '歌单',
                    '...',
                    Icons.playlist_play,
                    Colors.green,
                  ),
                ),
              ],
            ),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '歌曲',
                    '0',
                    Icons.music_note,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '专辑',
                    '0',
                    Icons.album,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '歌单',
                    '0',
                    Icons.playlist_play,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 快速访问
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '浏览',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBrowseCard(
                      context,
                      '艺术家',
                      Icons.person,
                      Colors.orange,
                      () {
                        context.push('/artists');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBrowseCard(
                      context,
                      '专辑',
                      Icons.album,
                      Colors.purple,
                      () {
                        context.push('/albums');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 24)),

      // 我的歌单
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '我的歌单',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/playlist-management');
                },
                child: const Text('管理'),
              ),
            ],
          ),
        ),
      ),

      // 歌单列表
      playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '还没有歌单',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final playlist = playlists[index];
                return _buildPlaylistItem(context, playlist);
              },
              childCount: playlists.length > 5 ? 5 : playlists.length,
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, stack) => SliverToBoxAdapter(
          child: error.toErrorWidget(
            onRetry: () => ref.invalidate(playlistsProvider),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPodcastContent() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.mic,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  '播客功能即将推出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '敬请期待',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildAudiobookContent() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  '有声书功能即将推出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '敬请期待',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRadioContent() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.radio,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  '电台功能即将推出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '敬请期待',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return FCard(
      child: FTappable(
        onPress: onTap,
        builder: (context, variants, child) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistItem(BuildContext context, playlist) {
    return FTile(
      prefix: SizedBox.square(
        dimension: 56,
        child: ChansonCoverArt(
          fallbackIcon: FLucideIcons.listMusic,
          borderRadius: 8,
        ),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${playlist.songIds.length} 首歌曲'),
      suffix: FButton.icon(
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        onPress: () {},
        child: const Icon(FLucideIcons.ellipsisVertical),
      ),
      onPress: () {
        context.push('/playlist-detail', extra: {
          'playlistId': playlist.id,
        });
      },
    );
  }
}
