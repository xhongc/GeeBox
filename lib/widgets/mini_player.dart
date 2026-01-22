import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';

/// 底部迷你播放器
class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final audioService = ref.watch(audioPlayerServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final subsonicService = ref.watch(subsonicServiceProvider);
    final repository = ref.watch(musicRepositoryProvider);

    // 直接从 service 获取当前歌曲，并监听 stream 来触发重建
    ref.listen(currentSongProvider, (previous, next) {
      // 这会在 stream 发送新值时触发重建
    });

    final currentSong = audioService.currentSong;

    // 如果没有正在播放的歌曲，不显示迷你播放器
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playerState.value?.playing ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 封面
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
              child: currentSong.coverArt != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        repository.getCoverArtUrl(currentSong.coverArt!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.music_note,
                      color: Colors.grey,
                    ),
            ),

            // 歌曲信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentSong.artist ?? '未知艺术家',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // 控制按钮
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 32,
              color: colorScheme.primary,
              onPressed: () {
                audioService.playPause();
              },
            ),

            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () {
                audioService.next((id) => subsonicService.getStreamUrl(id));
              },
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
