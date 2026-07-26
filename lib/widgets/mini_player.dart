import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/subsonic_provider.dart';
import 'listener_components.dart';

/// 底部迷你播放器
class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final subsonicService = ref.watch(subsonicServiceProvider);
    final repository = ref.watch(musicRepositoryProvider);
    final currentSong = ref.watch(currentSongProvider).value;

    final isPlaying = playerState.value?.playing ?? false;
    final hasTrack = currentSong != null;
    final imageUrl = currentSong?.coverArt == null
        ? null
        : repository.getCoverArtUrl(currentSong!.coverArt!, size: 160);

    return Opacity(
      opacity: hasTrack ? 1 : 0.94,
      child: FTappable(
        onPress: () {
          if (hasTrack) onTap();
        },
        builder: (context, states, child) {
          return AnimatedScale(
            scale: states.contains(FTappableVariant.pressed) ? 0.99 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                gradient: ListenerGradients.darkPlayer,
                borderRadius: BorderRadius.circular(26),
                boxShadow: ListenerShadows.elevated,
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 51,
                    child: ListenerCoverArt(
                      imageUrl: imageUrl,
                      borderRadius: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong?.title ?? '暂无播放内容',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currentSong?.artist ??
                              currentSong?.album ??
                              '选择一首歌开始播放',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FButton.icon(
                    size: FButtonSizeVariant.sm,
                    variant: FButtonVariant.secondary,
                    onPress: hasTrack
                        ? () => ref.read(audioPlayerServiceProvider).playPause()
                        : null,
                    child: Icon(
                      isPlaying ? FLucideIcons.pause : FLucideIcons.play,
                      color: ListenerColors.foreground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  FButton.icon(
                    size: FButtonSizeVariant.sm,
                    variant: FButtonVariant.ghost,
                    onPress: hasTrack
                        ? () => ref.read(audioPlayerServiceProvider).next(
                              (id) => subsonicService.getStreamUrl(id),
                            )
                        : null,
                    child: const Icon(
                      FLucideIcons.skipForward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
