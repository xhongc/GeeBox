import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/play_history_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

/// 最近播放页面
class PlayHistoryScreen extends ConsumerWidget {
  const PlayHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);

    return ChansonScaffold(
      title: '最近播放',
      child: recentlyPlayed.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const ChansonEmptyState(
              icon: FLucideIcons.history,
              message: '还没有播放记录',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return _buildSongItem(context, ref, songs[index]);
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

  Widget _buildSongItem(BuildContext context, WidgetRef ref, Song song) {
    final repository = ref.read(musicRepositoryProvider);

    return ChansonSongTile(
      coverUrl: song.coverArt == null
          ? null
          : repository.getCoverArtUrl(song.coverArt!),
      title: song.title,
      subtitle: song.artist ?? '未知艺术家',
      duration: song.duration == null ? null : _formatDuration(song.duration!),
      onPress: () {
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
