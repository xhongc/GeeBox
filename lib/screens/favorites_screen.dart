import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorite_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';
import '../widgets/error_view.dart';

/// 我喜欢的音乐页面
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starredSongs = ref.watch(starredSongsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我喜欢的音乐'),
      ),
      body: starredSongs.when(
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '还没有收藏任何歌曲',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return _buildSongItem(context, ref, songs[index], theme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => error.toErrorWidget(
          onRetry: () => ref.invalidate(starredSongsProvider),
        ),
      ),
    );
  }

  Widget _buildSongItem(BuildContext context, WidgetRef ref, Song song, ThemeData theme) {
    final repository = ref.read(musicRepositoryProvider);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: song.coverArt != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  repository.getCoverArtUrl(song.coverArt!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.music_note, color: Colors.grey);
                  },
                ),
              )
            : const Icon(Icons.music_note, color: Colors.grey),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? '未知艺术家',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.duration != null)
            Text(
              _formatDuration(song.duration!),
              style: TextStyle(color: Colors.grey[600]),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showSongOptions(context, ref, song),
          ),
        ],
      ),
      onTap: () {
        final audioService = ref.read(audioPlayerServiceProvider);
        final subsonicService = ref.read(subsonicServiceProvider);
        final streamUrl = subsonicService.getStreamUrl(song.id);
        audioService.playSong(song, streamUrl);
      },
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('取消收藏'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final service = ref.read(favoriteServiceProvider);
                await service.unstarSong(song.id);
                ref.invalidate(starredSongsProvider);
                messenger.showSnackBar(
                  const SnackBar(content: Text('已取消收藏')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
