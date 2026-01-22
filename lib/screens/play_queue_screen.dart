import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';

/// 播放队列页面
class PlayQueueScreen extends ConsumerWidget {
  const PlayQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final playlist = audioService.playlist;
    final currentIndex = audioService.currentIndex;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('播放队列 (${playlist.length})'),
        actions: [
          if (playlist.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                _showClearQueueDialog(context, ref);
              },
              tooltip: '清空队列',
            ),
        ],
      ),
      body: playlist.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '播放队列为空',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: playlist.length,
              onReorder: (oldIndex, newIndex) {
                // ReorderableListView 的 newIndex 需要调整
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                audioService.moveInQueue(oldIndex, newIndex);
                // 强制刷新 UI
                ref.read(currentPlaylistProvider.notifier).state = List.from(playlist);
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
                  theme,
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
    ThemeData theme,
  ) {
    final repository = ref.read(musicRepositoryProvider);
    final audioService = ref.read(audioPlayerServiceProvider);
    final subsonicService = ref.read(subsonicServiceProvider);

    return Dismissible(
      key: Key('${song.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
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
        ref.read(currentPlaylistProvider.notifier).state = List.from(audioService.playlist);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已从队列中移除 ${song.title}')),
        );
      },
      child: Container(
        color: isCurrentSong ? theme.colorScheme.primary.withOpacity(0.1) : null,
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动手柄
              const Icon(Icons.drag_handle, color: Colors.grey),
              const SizedBox(width: 8),
              // 封面
              Container(
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
            ],
          ),
          title: Row(
            children: [
              if (isCurrentSong)
                Icon(
                  Icons.play_arrow,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              if (isCurrentSong) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentSong ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ],
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
            if (!isCurrentSong) {
              final streamUrl = subsonicService.getStreamUrl(song.id);
              audioService.playSong(song, streamUrl);
              ref.read(currentIndexProvider.notifier).state = index;
            }
          },
        ),
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
              ref.read(currentPlaylistProvider.notifier).state = [];
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
