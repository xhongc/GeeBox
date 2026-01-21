import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../providers/music_repository_provider.dart';
import 'playlist_management_screen.dart';
import 'playlist_detail_screen.dart';

// 音乐库统计 Provider
final libraryStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getLibraryStats();
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // 不保持状态，每次都重新构建

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    final playlistsAsync = ref.watch(playlistsProvider);
    final statsAsync = ref.watch(libraryStatsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            floating: true,
            title: const Text(
              '我的音乐',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlaylistManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaylistManagementScreen(),
                        ),
                      );
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('加载失败: $error'),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
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

  Widget _buildPlaylistItem(BuildContext context, playlist) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.playlist_play, color: Colors.grey),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${playlist.songIds.length} 首歌曲'),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {},
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
    );
  }
}
