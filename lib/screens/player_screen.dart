import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/play_history_provider.dart';
import '../providers/sleep_timer_provider.dart';
import '../providers/subsonic_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/lyrics_widget.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    final audioService = ref.read(audioPlayerServiceProvider);
    final playHistoryService = ref.read(playHistoryServiceProvider);
    audioService.setScrobbleCallback(playHistoryService.scrobble);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final subsonicService = ref.watch(subsonicServiceProvider);
    final repository = ref.watch(musicRepositoryProvider);
    final currentSong = ref.watch(currentSongProvider).value;
    final playMode = ref.watch(playModeProvider).value ?? PlayMode.sequence;
    final playbackError = ref.watch(playbackErrorProvider).valueOrNull;
    final sleepTimer = ref.watch(sleepTimerControllerProvider);

    if (currentSong == null) {
      return FScaffold(
        childPad: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: ListenerGradients.shell),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      ListenerCircleButton(
                        icon: FLucideIcons.chevronLeft,
                        onPress: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FLucideIcons.music,
                          color: ListenerColors.muted,
                          size: 58,
                        ),
                        SizedBox(height: 14),
                        Text(
                          '暂无播放内容',
                          style: TextStyle(color: ListenerColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPlaying = playerState.value?.playing ?? false;
    final currentPosition = position.value ?? Duration.zero;
    final totalDuration = duration.value ?? Duration.zero;
    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;
    final coverUrl = currentSong.coverArt == null
        ? null
        : repository.getCoverArtUrl(currentSong.coverArt!, size: 700);

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: Stack(
          children: [
            ListenerCoverBackdrop(
              imageUrl: coverUrl,
              fallbackIcon: FLucideIcons.music,
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  child: Column(
                    children: [
                      _PlayingTopBar(
                        song: currentSong,
                        onBack: () => Navigator.pop(context),
                        onFavorite: () => _toggleFavorite(context, currentSong),
                        onMore: () => _showPlayerOptionsSheet(
                          context,
                          ref,
                          sleepTimer.remaining,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DisplaySwitch(
                        showLyrics: _showLyrics,
                        onChanged: (value) {
                          setState(() => _showLyrics = value);
                        },
                      ),
                      const SizedBox(height: 22),
                      if (_showLyrics)
                        _LyricsStage(
                          song: currentSong,
                          position: currentPosition,
                          onSeek: audioService.seek,
                        )
                      else
                        _CoverStage(
                          coverUrl: coverUrl,
                          isPlaying: isPlaying,
                        ),
                      const SizedBox(height: 26),
                      _SongMeta(song: currentSong),
                      const SizedBox(height: 12),
                      _PlaybackDetails(
                        song: currentSong,
                        totalDuration: totalDuration,
                      ),
                      const SizedBox(height: 22),
                      _ProgressBlock(
                        progress: progress.clamp(0.0, 1.0),
                        currentPosition: currentPosition,
                        totalDuration: totalDuration,
                        onSeek: (value) {
                          audioService.seek(
                            Duration(
                              milliseconds:
                                  (value * totalDuration.inMilliseconds)
                                      .round(),
                            ),
                          );
                        },
                      ),
                      if (playbackError != null) ...[
                        const SizedBox(height: 12),
                        _PlaybackErrorBanner(
                          message: playbackError,
                          onRetry: () => audioService.playAtIndex(
                            audioService.currentIndex,
                            (id) => subsonicService.getStreamUrl(id),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _PlaybackControls(
                        isPlaying: isPlaying,
                        playMode: playMode,
                        onShuffle: () => audioService.setPlayMode(
                          playMode == PlayMode.shuffle
                              ? PlayMode.sequence
                              : PlayMode.shuffle,
                        ),
                        onRepeat: () => audioService.setPlayMode(
                          playMode == PlayMode.repeatOne
                              ? PlayMode.sequence
                              : PlayMode.repeatOne,
                        ),
                        onPrevious: () => audioService.previous(
                          (id) => subsonicService.getStreamUrl(id),
                        ),
                        onPlayPause: audioService.playPause,
                        onNext: () => audioService.next(
                          (id) => subsonicService.getStreamUrl(id),
                        ),
                        onQueue: () => _openQueueTab(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQueueTab(BuildContext context) {
    ref.read(mainNavigationIndexProvider.notifier).state = 2;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/');
  }

  Future<void> _toggleFavorite(BuildContext context, Song song) async {
    final service = ref.read(favoriteServiceProvider);
    final isStarred = await ref.read(isSongStarredProvider(song.id).future);
    bool ok;
    if (isStarred) {
      ok = await service.unstarSong(song.id);
      if (!context.mounted) return;
      showChansonToast(context, ok ? '已取消收藏' : '取消收藏失败', destructive: !ok);
    } else {
      ok = await service.starSong(song.id);
      if (!context.mounted) return;
      showChansonToast(context, ok ? '已添加到我喜欢的音乐' : '收藏失败', destructive: !ok);
    }
    if (ok) {
      ref.invalidate(starredSongsProvider);
      ref.invalidate(isSongStarredProvider(song.id));
    }
  }
}

void _showPlayerOptionsSheet(
  BuildContext context,
  WidgetRef ref,
  Duration? sleepRemaining,
) {
  showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: 0.42,
    builder: (sheetContext) => DecoratedBox(
      decoration: const BoxDecoration(gradient: ListenerGradients.shell),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '更多',
                style: TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _PlayerOptionTile(
                icon: FLucideIcons.timer,
                title: '睡眠定时器',
                subtitle: sleepRemaining == null
                    ? '设置自动暂停播放'
                    : '${sleepRemaining.inMinutes.clamp(1, 999)} 分钟后暂停',
                onPress: () async {
                  Navigator.pop(sheetContext);
                  await Future<void>.delayed(const Duration(milliseconds: 120));
                  if (context.mounted) {
                    _showSleepTimerSheet(context, ref);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlayerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const _PlayerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: states.contains(FTappableVariant.pressed) ? 0.88 : 0.74,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: ListenerShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ListenerColors.foreground.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ListenerColors.foreground, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.softText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                FLucideIcons.chevronRight,
                color: ListenerColors.muted,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
  final controller = ref.read(sleepTimerControllerProvider.notifier);
  final audioService = ref.read(audioPlayerServiceProvider);
  showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: 0.52,
    builder: (context) => DecoratedBox(
      decoration: const BoxDecoration(gradient: ListenerGradients.shell),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '睡眠定时器',
                  style: TextStyle(
                    color: ListenerColors.foreground,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final minutes in [15, 30, 45, 60])
                    FButton(
                      variant: FButtonVariant.secondary,
                      onPress: () {
                        controller.setTimer(
                          Duration(minutes: minutes),
                          audioService.pause,
                        );
                        Navigator.pop(context);
                        showChansonToast(context, '$minutes 分钟后暂停播放');
                      },
                      child: Text('$minutes 分钟'),
                    ),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () {
                      controller.cancel();
                      Navigator.pop(context);
                      showChansonToast(context, '已取消睡眠定时器');
                    },
                    child: const Text('取消定时'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlaybackErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PlaybackErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(
            FLucideIcons.triangleAlert,
            color: Color(0xFFD97706),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ListenerColors.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FButton(
            size: FButtonSizeVariant.sm,
            variant: FButtonVariant.ghost,
            onPress: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _PlayingTopBar extends StatelessWidget {
  final Song song;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onMore;

  const _PlayingTopBar({
    required this.song,
    required this.onBack,
    required this.onFavorite,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ListenerCircleButton(icon: FLucideIcons.chevronLeft, onPress: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              const Text(
                '正在播放',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                song.album ?? song.artist ?? '未知来源',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ListenerCircleButton(icon: FLucideIcons.heart, onPress: onFavorite),
        const SizedBox(width: 8),
        ListenerCircleButton(
          icon: FLucideIcons.ellipsis,
          tooltip: '更多',
          onPress: onMore,
        ),
      ],
    );
  }
}

class _DisplaySwitch extends StatelessWidget {
  final bool showLyrics;
  final ValueChanged<bool> onChanged;

  const _DisplaySwitch({
    required this.showLyrics,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(999),
        boxShadow: ListenerShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DisplayPill(
            label: '封面',
            active: !showLyrics,
            onPress: () => onChanged(false),
          ),
          _DisplayPill(
            label: '歌词',
            active: showLyrics,
            onPress: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _DisplayPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPress;

  const _DisplayPill({
    required this.label,
    required this.active,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: active ? ListenerColors.foreground : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : ListenerColors.softText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CoverStage extends StatelessWidget {
  final String? coverUrl;
  final bool isPlaying;

  const _CoverStage({
    required this.coverUrl,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final maxCoverSize = (height * 0.34).clamp(180.0, 288.0);
    final resolvedCoverSize = (width * 0.74).clamp(180.0, maxCoverSize);
    final discSize = resolvedCoverSize * 0.72;

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(resolvedCoverSize * 0.30, 0),
            child: AnimatedRotation(
              turns: isPlaying ? 1 : 0,
              duration: const Duration(seconds: 12),
              child: Container(
                width: discSize,
                height: discSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ListenerColors.foreground,
                  boxShadow: ListenerShadows.elevated,
                ),
                child: Center(
                  child: Container(
                    width: discSize * 0.30,
                    height: discSize * 0.30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF7F6F3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: resolvedCoverSize,
              height: resolvedCoverSize,
              child: ListenerPlayingArtCard(
                imageUrl: coverUrl,
                fallbackIcon: FLucideIcons.music,
                borderRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsStage extends StatelessWidget {
  final Song song;
  final Duration position;
  final ValueChanged<Duration> onSeek;

  const _LyricsStage({
    required this.song,
    required this.position,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: LyricsWidget(
            artist: song.artist,
            title: song.title,
            position: position,
            onSeek: onSeek,
          ),
        ),
      ),
    );
  }
}

class _SongMeta extends StatelessWidget {
  final Song song;

  const _SongMeta({required this.song});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          song.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ListenerColors.foreground,
            fontSize: 29,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          song.artist ?? song.album ?? '未知艺术家',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ListenerColors.softText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlaybackDetails extends StatelessWidget {
  final Song song;
  final Duration totalDuration;

  const _PlaybackDetails({
    required this.song,
    required this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (song.album?.isNotEmpty == true) song.album!,
      if (song.year != null) '${song.year}',
      if (song.genre?.isNotEmpty == true) song.genre!,
      if (song.bitRate != null) '${song.bitRate} kbps',
      if (song.contentType != null) _formatContentType(song.contentType!),
      _formatDuration(totalDuration),
    ];

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final detail in details)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: ListenerShadows.soft,
                ),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ListenerColors.softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final double progress;
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<double> onSeek;

  const _ProgressBlock({
    required this.progress,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FSlider(
          control: FSliderControl.liftedContinuous(
            value: FSliderValue(max: progress),
            onChange: (value) => onSeek(value.max),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(currentPosition),
              style: const TextStyle(
                color: ListenerColors.muted,
                fontSize: 12,
              ),
            ),
            Text(
              _formatDuration(totalDuration),
              style: const TextStyle(
                color: ListenerColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final PlayMode playMode;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onQueue;

  const _PlaybackControls({
    required this.isPlaying,
    required this.playMode,
    required this.onShuffle,
    required this.onRepeat,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundControl(
          icon: FLucideIcons.shuffle,
          active: playMode == PlayMode.shuffle,
          onPress: onShuffle,
        ),
        _RoundControl(
          icon: playMode == PlayMode.repeatOne
              ? FLucideIcons.repeat1
              : FLucideIcons.repeat,
          active: playMode == PlayMode.repeatOne,
          onPress: onRepeat,
        ),
        _RoundControl(icon: FLucideIcons.skipBack, onPress: onPrevious),
        FButton.icon(
          size: FButtonSizeVariant.lg,
          onPress: onPlayPause,
          child: Icon(isPlaying ? FLucideIcons.pause : FLucideIcons.play),
        ),
        _RoundControl(icon: FLucideIcons.skipForward, onPress: onNext),
        _RoundControl(icon: FLucideIcons.listMusic, onPress: onQueue),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;
  final bool active;

  const _RoundControl({
    required this.icon,
    required this.onPress,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      variant: FButtonVariant.ghost,
      onPress: onPress,
      child: Icon(
        icon,
        color: active ? ListenerColors.foreground : ListenerColors.softText,
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatContentType(String contentType) {
  final value = contentType.toLowerCase();
  if (value.contains('flac')) return 'FLAC';
  if (value.contains('aac')) return 'AAC';
  if (value.contains('ogg')) return 'OGG';
  if (value.contains('wav')) return 'WAV';
  if (value.contains('mpeg') || value.contains('mp3')) return 'MP3';
  return contentType.toUpperCase();
}
