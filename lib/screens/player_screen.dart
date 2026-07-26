import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/play_history_provider.dart';
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
            Positioned(
              top: -80,
              left: -48,
              right: -48,
              height: 300,
              child: Opacity(
                opacity: 0.18,
                child: ListenerCoverArt(
                  imageUrl: coverUrl,
                  fallbackIcon: FLucideIcons.music,
                  borderRadius: 0,
                ),
              ),
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
                        )
                      else
                        _CoverStage(
                          coverUrl: coverUrl,
                          isPlaying: isPlaying,
                        ),
                      const SizedBox(height: 26),
                      _SongMeta(song: currentSong),
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
                      const SizedBox(height: 22),
                      _PlaybackControls(
                        isPlaying: isPlaying,
                        playMode: playMode,
                        onRepeat: () {
                          audioService.setPlayMode(
                            playMode == PlayMode.repeatOne
                                ? PlayMode.sequence
                                : PlayMode.repeatOne,
                          );
                        },
                        onPrevious: () => audioService.previous(
                          (id) => subsonicService.getStreamUrl(id),
                        ),
                        onPlayPause: audioService.playPause,
                        onNext: () => audioService.next(
                          (id) => subsonicService.getStreamUrl(id),
                        ),
                        onQueue: () => context.push('/play-queue'),
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

class _PlayingTopBar extends StatelessWidget {
  final Song song;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  const _PlayingTopBar({
    required this.song,
    required this.onBack,
    required this.onFavorite,
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
    final coverSize = width.clamp(0, 420) * 0.66;
    final resolvedCoverSize = coverSize.clamp(216.0, 252.0);
    final discSize = resolvedCoverSize * 0.94;

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(resolvedCoverSize * 0.24, 0),
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
                    width: 68,
                    height: 68,
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
            child: Container(
              width: resolvedCoverSize,
              height: resolvedCoverSize,
              decoration: BoxDecoration(boxShadow: ListenerShadows.elevated),
              child: ListenerCoverArt(
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

  const _LyricsStage({
    required this.song,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        boxShadow: ListenerShadows.soft,
      ),
      child: LyricsWidget(
        artist: song.artist,
        title: song.title,
        position: position,
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
  final VoidCallback onRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onQueue;

  const _PlaybackControls({
    required this.isPlaying,
    required this.playMode,
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
