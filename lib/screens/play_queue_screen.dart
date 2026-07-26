import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/subsonic_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

/// Listener 风格播放队列页面
class PlayQueueScreen extends ConsumerWidget {
  const PlayQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(currentPlaylistProvider).value ?? const <Song>[];
    final currentIndex = ref.watch(currentIndexProvider).value ?? -1;
    final currentSong = ref.watch(currentSongProvider).value;
    final isPlaying = ref.watch(playerStateProvider).value?.playing ?? false;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _QueueHeader(
                count: playlist.length,
                onGroupCast:
                    playlist.isEmpty ? null : () => context.push('/group-cast'),
              ),
              const SizedBox(height: 16),
              if (currentSong != null)
                _CurrentTrackCard(
                  song: currentSong,
                  isPlaying: isPlaying,
                  imageUrl: _coverUrl(ref, currentSong),
                  onToggle: () =>
                      ref.read(audioPlayerServiceProvider).playPause(),
                ),
              if (playlist.isNotEmpty) ...[
                const SizedBox(height: 16),
                _QueueActions(
                  onShuffle: () => _shuffleQueue(ref, playlist),
                  onRandom: () => _playRandom(ref, playlist),
                  onClear: () => _confirmClearQueue(context, ref),
                ),
                const SizedBox(height: 18),
              ],
              if (playlist.isEmpty)
                const SizedBox(
                  height: 260,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FLucideIcons.listMusic,
                          color: ListenerColors.muted,
                          size: 54,
                        ),
                        SizedBox(height: 14),
                        Text(
                          '暂无播放',
                          style: TextStyle(color: ListenerColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 1.02).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  onReorderItem: (oldIndex, newIndex) {
                    ref
                        .read(audioPlayerServiceProvider)
                        .moveInQueue(oldIndex, newIndex);
                  },
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final song = playlist[index];
                    return _QueueRow(
                      key: ValueKey('queue-${song.id}-$index'),
                      song: song,
                      index: index,
                      isCurrent: index == currentIndex,
                      imageUrl: _coverUrl(ref, song),
                      onPress: () => _playAt(ref, playlist, index),
                      onMore: () => _showQueueItemActions(
                        context,
                        ref,
                        playlist,
                        index,
                        currentIndex,
                      ),
                    );
                  },
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _QueueHeader extends StatelessWidget {
  final int count;
  final VoidCallback? onGroupCast;

  const _QueueHeader({
    required this.count,
    required this.onGroupCast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '播放队列',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '继续聆听',
                style: TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onGroupCast == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              boxShadow: ListenerShadows.soft,
            ),
            child: Text(
              '$count 首',
              style: const TextStyle(
                color: ListenerColors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          FButton(
            size: FButtonSizeVariant.sm,
            variant: FButtonVariant.secondary,
            onPress: onGroupCast,
            prefix: const Icon(FLucideIcons.radioTower, size: 16),
            child: const Text('同播'),
          ),
      ],
    );
  }
}

class _CurrentTrackCard extends StatelessWidget {
  final Song song;
  final String? imageUrl;
  final bool isPlaying;
  final VoidCallback onToggle;

  const _CurrentTrackCard({
    required this.song,
    required this.imageUrl,
    required this.isPlaying,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: ListenerGradients.darkPlayer,
        borderRadius: BorderRadius.circular(27),
        boxShadow: ListenerShadows.elevated,
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 64,
            child: ListenerCoverArt(imageUrl: imageUrl, borderRadius: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前播放',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist ?? song.album ?? '未知艺术家',
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
            variant: FButtonVariant.secondary,
            onPress: onToggle,
            child: Icon(
              isPlaying ? FLucideIcons.pause : FLucideIcons.play,
              color: ListenerColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueActions extends StatelessWidget {
  final VoidCallback onShuffle;
  final VoidCallback onRandom;
  final VoidCallback onClear;

  const _QueueActions({
    required this.onShuffle,
    required this.onRandom,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QueueAction(
            icon: FLucideIcons.shuffle, label: '打乱', onPress: onShuffle),
        const SizedBox(width: 11),
        _QueueAction(icon: FLucideIcons.play, label: '随机', onPress: onRandom),
        const SizedBox(width: 11),
        _QueueAction(icon: FLucideIcons.trash2, label: '清空', onPress: onClear),
      ],
    );
  }
}

class _QueueAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPress;

  const _QueueAction({
    required this.icon,
    required this.label,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FTappable(
        onPress: onPress,
        builder: (context, states, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(19),
              boxShadow: ListenerShadows.soft,
            ),
            child: Column(
              children: [
                Icon(icon, color: ListenerColors.foreground, size: 20),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: ListenerColors.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final Song song;
  final int index;
  final bool isCurrent;
  final String? imageUrl;
  final VoidCallback onPress;
  final VoidCallback onMore;

  const _QueueRow({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.imageUrl,
    required this.onPress,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(22),
            boxShadow: isCurrent ? ListenerShadows.soft : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ListenerColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox.square(
                dimension: 51,
                child: ListenerCoverArt(imageUrl: imageUrl, borderRadius: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 15,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? song.album ?? '未知艺术家',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FButton.icon(
                variant: FButtonVariant.ghost,
                size: FButtonSizeVariant.sm,
                onPress: onMore,
                child: const Icon(
                  FLucideIcons.ellipsis,
                  color: ListenerColors.muted,
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    FLucideIcons.gripVertical,
                    color: ListenerColors.muted,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String? _coverUrl(WidgetRef ref, Song song) {
  if (song.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(song.coverArt!);
}

Future<void> _playAt(WidgetRef ref, List<Song> songs, int index) async {
  final audioService = ref.read(audioPlayerServiceProvider);
  final subsonicService = ref.read(subsonicServiceProvider);
  await audioService.setPlaylist(songs, initialIndex: index);
  await audioService.playAtIndex(
    index,
    (songId) => subsonicService.getStreamUrl(songId),
  );
}

Future<void> _shuffleQueue(WidgetRef ref, List<Song> songs) async {
  final shuffled = List<Song>.from(songs)..shuffle();
  await _playAt(ref, shuffled, 0);
}

Future<void> _playRandom(WidgetRef ref, List<Song> songs) async {
  if (songs.isEmpty) return;
  final index = DateTime.now().microsecond % songs.length;
  await _playAt(ref, songs, index);
}

void _showQueueItemActions(
  BuildContext context,
  WidgetRef ref,
  List<Song> playlist,
  int index,
  int currentIndex,
) {
  final song = playlist[index];
  showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: 0.66,
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
              _QueueSheetAction(
                icon: FLucideIcons.listEnd,
                title: '移到下一首',
                enabled: index != currentIndex,
                onPress: () {
                  final targetIndex =
                      index < currentIndex ? currentIndex : currentIndex + 1;
                  final clampedTarget =
                      targetIndex.clamp(0, playlist.length - 1).toInt();
                  ref
                      .read(audioPlayerServiceProvider)
                      .moveInQueue(index, clampedTarget);
                  Navigator.pop(context);
                  showChansonToast(context, '已移到下一首');
                },
              ),
              _QueueSheetAction(
                icon: FLucideIcons.arrowUpToLine,
                title: '移到队首',
                enabled: index != 0,
                onPress: () {
                  ref.read(audioPlayerServiceProvider).moveInQueue(index, 0);
                  Navigator.pop(context);
                  showChansonToast(context, '已移到队首');
                },
              ),
              _QueueSheetAction(
                icon: FLucideIcons.play,
                title: '从这里开始播放',
                onPress: () {
                  Navigator.pop(context);
                  _playAt(ref, playlist, index);
                },
              ),
              _QueueSheetAction(
                icon: FLucideIcons.trash2,
                title: '从队列移除',
                destructive: true,
                enabled: index != currentIndex,
                onPress: () {
                  ref.read(audioPlayerServiceProvider).removeFromQueue(index);
                  Navigator.pop(context);
                  showChansonToast(context, '已从队列中移除 ${song.title}');
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QueueSheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onPress;
  final bool enabled;
  final bool destructive;

  const _QueueSheetAction({
    required this.icon,
    required this.title,
    required this.onPress,
    this.enabled = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFDC2626) : ListenerColors.foreground;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        boxShadow: ListenerShadows.soft,
      ),
      child: FTile(
        prefix: Icon(icon, color: enabled ? color : ListenerColors.muted),
        title: Text(
          title,
          style: TextStyle(color: enabled ? color : ListenerColors.muted),
        ),
        onPress: enabled ? onPress : null,
      ),
    );
  }
}

void _confirmClearQueue(BuildContext context, WidgetRef ref) {
  showFDialog(
    context: context,
    builder: (context, style, animation) => FDialog(
      animation: animation,
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('清空播放队列', style: style.titleTextStyle),
            const SizedBox(height: 8),
            Text('这会停止当前播放并移除队列中的全部歌曲。', style: style.bodyTextStyle),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                FButton(
                  variant: FButtonVariant.destructive,
                  onPress: () {
                    ref.read(audioPlayerServiceProvider).clearQueue();
                    Navigator.pop(context);
                    showChansonToast(context, '已清空播放队列');
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
