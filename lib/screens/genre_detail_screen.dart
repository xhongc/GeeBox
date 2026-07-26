import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

class GenreDetailScreen extends ConsumerStatefulWidget {
  final String genreName;
  final int albumCount;
  final int trackCount;

  const GenreDetailScreen({
    super.key,
    required this.genreName,
    this.albumCount = 0,
    this.trackCount = 0,
  });

  @override
  ConsumerState<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends ConsumerState<GenreDetailScreen> {
  bool _showOverview = false;

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(genreSongsProvider(widget.genreName));

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                top: -76,
                left: -36,
                right: -36,
                height: 310,
                child: Opacity(
                  opacity: 0.36,
                  child: _GenreBackdrop(name: widget.genreName),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _GenreTopBar(
                          name: widget.genreName,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 18),
                        _ModeSwitch(
                          showOverview: _showOverview,
                          onChanged: (value) {
                            setState(() => _showOverview = value);
                          },
                        ),
                        const SizedBox(height: 22),
                        songsAsync.when(
                          data: (songs) => _GenreHero(
                            name: widget.genreName,
                            songs: songs,
                            albumCount: widget.albumCount,
                            trackCount: _displayTrackCount(songs),
                            showOverview: _showOverview,
                            onPlay: songs.isEmpty
                                ? null
                                : () => _playSongs(ref, songs),
                            onShuffle: songs.isEmpty
                                ? null
                                : () => _shuffleSongs(ref, songs),
                          ),
                          loading: () => _GenreHero(
                            name: widget.genreName,
                            songs: const [],
                            albumCount: widget.albumCount,
                            trackCount: widget.trackCount,
                            showOverview: _showOverview,
                            loading: true,
                            onPlay: null,
                            onShuffle: null,
                          ),
                          error: (_, __) => _GenreHero(
                            name: widget.genreName,
                            songs: const [],
                            albumCount: widget.albumCount,
                            trackCount: widget.trackCount,
                            showOverview: _showOverview,
                            onPlay: null,
                            onShuffle: null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _SectionSwitch(),
                        const SizedBox(height: 22),
                        songsAsync.when(
                          data: (songs) => _GenreTracks(
                            songs: songs,
                            onRetry: () => ref.invalidate(
                              genreSongsProvider(widget.genreName),
                            ),
                          ),
                          loading: () => const _TracksLoading(),
                          error: (_, __) => _TracksError(
                            onRetry: () => ref.invalidate(
                              genreSongsProvider(widget.genreName),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _displayTrackCount(List<Song> songs) {
    if (widget.trackCount > 0) return widget.trackCount;
    return songs.length;
  }
}

class _GenreTopBar extends StatelessWidget {
  final String name;
  final VoidCallback onBack;

  const _GenreTopBar({
    required this.name,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ListenerCircleButton(
          icon: FLucideIcons.chevronLeft,
          onPress: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '风格详情',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool showOverview;
  final ValueChanged<bool> onChanged;

  const _ModeSwitch({
    required this.showOverview,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(999),
          boxShadow: ListenerShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModePill(
              label: '封面',
              active: !showOverview,
              onPress: () => onChanged(false),
            ),
            _ModePill(
              label: '概览',
              active: showOverview,
              onPress: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPress;

  const _ModePill({
    required this.label,
    required this.active,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
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
        );
      },
    );
  }
}

class _GenreHero extends StatelessWidget {
  final String name;
  final List<Song> songs;
  final int albumCount;
  final int trackCount;
  final bool showOverview;
  final bool loading;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const _GenreHero({
    required this.name,
    required this.songs,
    required this.albumCount,
    required this.trackCount,
    required this.showOverview,
    required this.onPlay,
    required this.onShuffle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: showOverview
              ? _GenreOverview(
                  key: const ValueKey('overview'),
                  name: name,
                  songs: songs,
                  albumCount: albumCount,
                  trackCount: trackCount,
                  loading: loading,
                )
              : _GenreCoverStage(
                  key: const ValueKey('cover'),
                  name: name,
                ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Genre',
          style: TextStyle(
            color: ListenerColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ListenerColors.foreground,
            fontSize: 34,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$albumCount 张专辑 · $trackCount 首歌曲',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ListenerColors.softText,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FButton(
                onPress: onPlay,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FLucideIcons.play, size: 17),
                    SizedBox(width: 8),
                    Text('播放风格'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: onShuffle,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FLucideIcons.shuffle, size: 17),
                    SizedBox(width: 8),
                    Text('随机'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenreCoverStage extends StatelessWidget {
  final String name;

  const _GenreCoverStage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 255,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(38, 3),
            child: Container(
              width: 184,
              height: 184,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ListenerColors.foreground,
                boxShadow: ListenerShadows.elevated,
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -pi / 28,
            child: Container(
              width: 196,
              height: 196,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: _genreGradient(name),
                boxShadow: ListenerShadows.elevated,
              ),
              child: Center(
                child: Icon(
                  FLucideIcons.audioLines,
                  color: ListenerColors.foreground.withValues(alpha: 0.66),
                  size: 62,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreOverview extends StatelessWidget {
  final String name;
  final List<Song> songs;
  final int albumCount;
  final int trackCount;
  final bool loading;

  const _GenreOverview({
    super.key,
    required this.name,
    required this.songs,
    required this.albumCount,
    required this.trackCount,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuration = songs.fold<int>(
      0,
      (sum, song) => sum + (song.duration ?? 0),
    );
    final artists = songs
        .map((song) => song.artist?.trim())
        .whereType<String>()
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .length;

    return Container(
      height: 255,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: ListenerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '库内信息',
            style: TextStyle(
              color: ListenerColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: '风格名称', value: name),
          _InfoRow(label: '专辑数量', value: '$albumCount'),
          _InfoRow(label: '歌曲数量', value: '$trackCount'),
          _InfoRow(label: '当前加载', value: loading ? '加载中' : '${songs.length} 首'),
          _InfoRow(label: '代表艺术家', value: artists == 0 ? '--' : '$artists 位'),
          _InfoRow(
            label: '总时长',
            value:
                totalDuration == 0 ? '--' : formatSongDuration(totalDuration),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ListenerColors.softText,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: ListenerColors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        boxShadow: ListenerShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '专辑',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: ListenerColors.foreground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '歌曲',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreTracks extends ConsumerWidget {
  final List<Song> songs;
  final VoidCallback onRetry;

  const _GenreTracks({
    required this.songs,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) {
      return const _EmptyTracks();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${songs.length} 首歌曲',
          style: const TextStyle(
            color: ListenerColors.foreground,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(songs.length, (index) {
          final song = songs[index];
          final imageUrl = _songCoverUrl(ref, song);
          return ListenerTrackRow(
            song: song,
            imageUrl: imageUrl,
            onPress: () => _playSongs(ref, songs, initialIndex: index),
            onFavorite: () => showChansonToast(context, '收藏功能将在喜爱页统一管理'),
            onMore: () => showListenerTrackActionSheet(
              context: context,
              ref: ref,
              song: song,
              imageUrl: imageUrl,
              queue: songs,
              index: index,
            ),
          );
        }),
      ],
    );
  }
}

class _TracksLoading extends StatelessWidget {
  const _TracksLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: FCircularProgress()),
    );
  }
}

class _TracksError extends StatelessWidget {
  final VoidCallback onRetry;

  const _TracksError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
      ),
      child: FButton(
        variant: FButtonVariant.ghost,
        onPress: onRetry,
        child: const Text('重新加载歌曲'),
      ),
    );
  }
}

class _EmptyTracks extends StatelessWidget {
  const _EmptyTracks();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        '暂无歌曲',
        style: TextStyle(color: ListenerColors.muted),
      ),
    );
  }
}

class _GenreBackdrop extends StatelessWidget {
  final String name;

  const _GenreBackdrop({required this.name});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _genreGradient(name)),
    );
  }
}

LinearGradient _genreGradient(String name) {
  final seed = name.codeUnits.fold<int>(0, (sum, value) => sum + value);
  final palettes = [
    [const Color(0xFFBFDBFE), const Color(0xFFF8FAFC)],
    [const Color(0xFFFBCFE8), const Color(0xFFE0F2FE)],
    [const Color(0xFFBBF7D0), const Color(0xFFFFEDD5)],
    [const Color(0xFFDDD6FE), const Color(0xFFE2E8F0)],
  ];
  final colors = palettes[seed % palettes.length];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  );
}

String? _songCoverUrl(WidgetRef ref, Song song) {
  if (song.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(song.coverArt!);
}

Future<void> _playSongs(
  WidgetRef ref,
  List<Song> songs, {
  int initialIndex = 0,
}) async {
  if (songs.isEmpty) return;
  final player = ref.read(audioPlayerServiceProvider);
  final repository = ref.read(musicRepositoryProvider);
  await player.setPlaylist(songs, initialIndex: initialIndex);
  await player.playAtIndex(
    initialIndex,
    (songId) => repository.getStreamUrl(songId),
  );
}

Future<void> _shuffleSongs(WidgetRef ref, List<Song> songs) async {
  final shuffled = List<Song>.from(songs)..shuffle();
  await _playSongs(ref, shuffled);
}
