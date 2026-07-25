import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/subsonic_provider.dart';

/// 底部迷你播放器
class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final audioService = ref.watch(audioPlayerServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final subsonicService = ref.watch(subsonicServiceProvider);
    final repository = ref.watch(musicRepositoryProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final isPlaying = playerState.value?.playing ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: FCard(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: currentSong.coverArt != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            repository.getCoverArtUrl(currentSong.coverArt!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                FLucideIcons.music,
                                color: theme.colors.mutedForeground,
                              );
                            },
                          ),
                        )
                      : Icon(
                          FLucideIcons.music,
                          color: theme.colors.mutedForeground,
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: theme.typography.body.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.artist ?? '未知艺术家',
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                FButton.icon(
                  size: FButtonSizeVariant.sm,
                  variant: FButtonVariant.ghost,
                  onPress: audioService.playPause,
                  child: Icon(
                    isPlaying ? FLucideIcons.pause : FLucideIcons.play,
                  ),
                ),
                FButton.icon(
                  size: FButtonSizeVariant.sm,
                  variant: FButtonVariant.ghost,
                  onPress: () {
                    audioService.next((id) => subsonicService.getStreamUrl(id));
                  },
                  child: const Icon(FLucideIcons.skipForward),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
