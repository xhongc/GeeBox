import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/play_history_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';
import '../widgets/error_view.dart';

/// 最近播放页面
class PlayHistoryScreen extends ConsumerWidget {
  const PlayHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('最近播放'),
      ),
      body: recentlyPlayed.when(
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '还没有播放记录',
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
          onRetry: () => ref.invalidate(recentlyPlayedProvider),
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
      trailing: song.duration != null
          ? Text(
              _formatDuration(song.duration!),
              style: TextStyle(color: Colors.grey[600]),
            )
          : null,
      onTap: () {
        final audioService = ref.read(audioPlayerServiceProvider);
        final subsonicService = ref.read(subsonicServiceProvider);
        final streamUrl = subsonicService.getStreamUrl(song.id);
        audioService.playSong(song, streamUrl);
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
