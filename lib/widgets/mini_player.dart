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
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final playbackError = ref.watch(playbackErrorProvider).valueOrNull;

    final isPlaying = playerState.value?.playing ?? false;
    final hasTrack = currentSong != null;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
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
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                  if (playbackError != null) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      FLucideIcons.triangleAlert,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _ProgressPlayButton(
                    progress: hasTrack ? progress : 0,
                    isPlaying: isPlaying,
                    onPress: hasTrack
                        ? () => ref.read(audioPlayerServiceProvider).playPause()
                        : null,
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

class _ProgressPlayButton extends StatelessWidget {
  final double progress;
  final bool isPlaying;
  final VoidCallback? onPress;

  const _ProgressPlayButton({
    required this.progress,
    required this.isPlaying,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPress != null;

    return SizedBox.square(
      dimension: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.4,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Material(
            color:
                enabled ? Colors.white : Colors.white.withValues(alpha: 0.42),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkResponse(
              onTap: onPress,
              containedInkWell: true,
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: 34,
                child: Icon(
                  isPlaying ? FLucideIcons.pause : FLucideIcons.play,
                  color: enabled
                      ? ListenerColors.foreground
                      : ListenerColors.foreground.withValues(alpha: 0.48),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
