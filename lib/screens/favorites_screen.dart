import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/favorite_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

/// 我喜欢的音乐页面
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starredSongs = ref.watch(starredSongsProvider);

    return ChansonScaffold(
      title: '我喜欢的音乐',
      child: starredSongs.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const ChansonEmptyState(
              icon: FLucideIcons.heart,
              message: '还没有收藏任何歌曲',
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
          onRetry: () => ref.invalidate(starredSongsProvider),
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
      onMore: () => _showSongOptions(context, ref, song),
      onPress: () {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FCard(
            child: FTile(
              variant: FItemVariant.destructive,
              prefix: const Icon(FLucideIcons.heartOff),
              title: const Text('取消收藏'),
              onPress: () async {
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
          ),
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
