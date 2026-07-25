import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';
import '../widgets/forui_components.dart';

/// 播放队列页面
class PlayQueueScreen extends ConsumerWidget {
  const PlayQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final playlistAsync = ref.watch(currentPlaylistProvider);
    final currentIndexAsync = ref.watch(currentIndexProvider);
    final playlist = playlistAsync.value ?? const <Song>[];
    final currentIndex = currentIndexAsync.value ?? -1;

    return ChansonScaffold(
      title: '播放队列 (${playlist.length})',
      suffixes: [
        if (playlist.isNotEmpty)
          FHeaderAction(
            icon: const Icon(FLucideIcons.listX),
            onPress: () => _showClearQueueDialog(context, ref),
          ),
      ],
      child: playlist.isEmpty
          ? const Center(
              child: ChansonEmptyState(
                icon: FLucideIcons.listMusic,
                message: '播放队列为空',
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: playlist.length,
              onReorderItem: (oldIndex, newIndex) {
                audioService.moveInQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = playlist[index];
                final isCurrentSong = index == currentIndex;

                return _buildSongItem(
                  context,
                  ref,
                  song,
                  index,
                  isCurrentSong,
                );
              },
            ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    WidgetRef ref,
    Song song,
    int index,
    bool isCurrentSong,
  ) {
    final repository = ref.read(musicRepositoryProvider);
    final audioService = ref.read(audioPlayerServiceProvider);
    final subsonicService = ref.read(subsonicServiceProvider);
    final theme = context.theme;

    return Dismissible(
      key: Key('${song.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colors.destructive,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          FLucideIcons.trash2,
          color: theme.colors.destructiveForeground,
        ),
      ),
      confirmDismiss: (direction) async {
        if (isCurrentSong) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法删除正在播放的歌曲')),
          );
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        audioService.removeFromQueue(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已从队列中移除 ${song.title}')),
        );
      },
      child: FTile(
        selected: isCurrentSong,
        prefix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FLucideIcons.gripVertical,
                color: theme.colors.mutedForeground),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 46,
              child: ChansonCoverArt(
                imageUrl: song.coverArt == null
                    ? null
                    : repository.getCoverArtUrl(song.coverArt!),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            if (isCurrentSong) ...[
              Icon(
                FLucideIcons.play,
                color: theme.colors.primary,
                size: 18,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isCurrentSong ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrentSong ? theme.colors.primary : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(song.artist ?? '未知艺术家'),
        details: song.duration == null
            ? null
            : Text(_formatDuration(song.duration!)),
        onPress: () {
          if (!isCurrentSong) {
            audioService.playAtIndex(
              index,
              (songId) => subsonicService.getStreamUrl(songId),
            );
          }
        },
      ),
    );
  }

  void _showClearQueueDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空队列'),
        content: const Text('确定要清空播放队列吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final audioService = ref.read(audioPlayerServiceProvider);
              audioService.clearQueue();
              Navigator.pop(context);
              Navigator.pop(context); // 关闭队列页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空播放队列')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
