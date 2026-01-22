import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_repository_provider.dart';
import '../providers/audio_player_provider.dart';
import '../models/song.dart';

// 专辑详情 Provider
final albumDetailProvider = FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbum(albumId);
});

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  final String albumName;
  final String? albumArtist;
  final String? coverArtId;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    required this.albumName,
    this.albumArtist,
    this.coverArtId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(albumDetailProvider(albumId));
    final repository = ref.read(musicRepositoryProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                albumName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(128, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: coverArtId != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          repository.getCoverArtUrl(coverArtId!, size: 500),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.album,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        // 渐变遮罩
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.album,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          // 专辑信息
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (albumArtist != null)
                    Text(
                      albumArtist!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 16),
                  songsAsync.when(
                    data: (songs) => Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: songs.isEmpty
                                ? null
                                : () async {
                                    // 播放全部
                                    final playerService = ref.read(audioPlayerServiceProvider);
                                    await playerService.setPlaylist(songs);
                                    await playerService.playAtIndex(
                                      0,
                                      (songId) => repository.getStreamUrl(songId),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('播放全部'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: songs.isEmpty
                                ? null
                                : () async {
                                    // 随机播放
                                    final shuffledSongs = List<Song>.from(songs)..shuffle();
                                    final playerService = ref.read(audioPlayerServiceProvider);
                                    await playerService.setPlaylist(shuffledSongs);
                                    await playerService.playAtIndex(
                                      0,
                                      (songId) => repository.getStreamUrl(songId),
                                    );
                                  },
                            icon: const Icon(Icons.shuffle),
                            label: const Text('随机播放'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // 歌曲列表
          songsAsync.when(
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        '暂无歌曲',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return _buildSongItem(context, ref, song, index + 1, songs);
                  },
                  childCount: songs.length,
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    WidgetRef ref,
    Song song,
    int trackNumber,
    List<Song> allSongs,
  ) {
    final currentSongAsync = ref.watch(currentSongProvider);
    final currentSong = currentSongAsync.value;
    final isPlaying = currentSong?.id == song.id;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPlaying ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: isPlaying
              ? Icon(
                  Icons.volume_up,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                )
              : Text(
                  trackNumber.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        song.artist ?? '未知艺术家',
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.duration != null)
            Text(
              _formatDuration(song.duration!),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showSongOptions(context, ref, song);
            },
          ),
        ],
      ),
      onTap: () async {
        // 播放歌曲
        final playerService = ref.read(audioPlayerServiceProvider);
        await playerService.setPlaylist(allSongs, initialIndex: trackNumber - 1);
        await playerService.playAtIndex(
          trackNumber - 1,
          (songId) => ref.read(musicRepositoryProvider).getStreamUrl(songId),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('播放'),
              onTap: () async {
                Navigator.pop(context);
                final playerService = ref.read(audioPlayerServiceProvider);
                final repository = ref.read(musicRepositoryProvider);
                await playerService.playSong(song, repository.getStreamUrl(song.id));
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放列表'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现添加到播放列表功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现分享功能
              },
            ),
          ],
        ),
      ),
    );
  }
}
