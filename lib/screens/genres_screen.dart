import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/genre.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

class GenresScreen extends ConsumerStatefulWidget {
  const GenresScreen({super.key});

  @override
  ConsumerState<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends ConsumerState<GenresScreen> {
  String _sort = 'a-z';

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider(_sort));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _GenresHeading(
                selected: _sort,
                onChanged: (value) {
                  setState(() => _sort = value);
                },
                onRefresh: () => ref.invalidate(genresProvider(_sort)),
              ),
              const SizedBox(height: 18),
              _GenresSummary(sort: _sort),
              const SizedBox(height: 22),
            ]),
          ),
        ),
        genresAsync.when(
          data: (genres) {
            if (genres.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _GenresEmpty(),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.86,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final genre = genres[index];
                    return _GenreLibraryCard(
                      genre: genre,
                      onOpen: () => _openGenre(context, genre),
                      onPlay: () => _playGenre(context, ref, genre),
                    );
                  },
                  childCount: genres.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: FCircularProgress()),
          ),
          error: (_, __) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: FButton(
                variant: FButtonVariant.ghost,
                onPress: () => ref.invalidate(genresProvider(_sort)),
                child: const Text('重新加载风格'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openGenre(BuildContext context, Genre genre) {
    context.push('/genre-detail', extra: {
      'genreName': genre.name,
      'albumCount': genre.albumCount,
      'trackCount': genre.trackCount,
    });
  }

  Future<void> _playGenre(
    BuildContext context,
    WidgetRef ref,
    Genre genre,
  ) async {
    final repository = ref.read(musicRepositoryProvider);
    final songs = await repository.getSongsByGenre(genre.name, count: 100);
    if (!context.mounted) return;
    if (songs.isEmpty) {
      showChansonToast(context, '这个风格暂无歌曲');
      return;
    }
    await _playSongs(ref, songs);
  }
}

class _GenresHeading extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  const _GenresHeading({
    required this.selected,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '风格',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '风格列表',
                    style: TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ListenerCircleButton(
              icon: FLucideIcons.refreshCcw,
              onPress: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SortPill(
                label: 'A-Z排序',
                value: 'a-z',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '最多专辑',
                value: 'most-albums',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '最多歌曲',
                value: 'most-tracks',
                selected: selected,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SortPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;

    return FTappable(
      onPress: () => onChanged(value),
      builder: (context, states, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? ListenerColors.foreground
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? ListenerShadows.soft : null,
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

class _GenresSummary extends StatelessWidget {
  final String sort;

  const _GenresSummary({required this.sort});

  @override
  Widget build(BuildContext context) {
    final title = switch (sort) {
      'most-albums' => '最多专辑',
      'most-tracks' => '最多歌曲',
      _ => 'A-Z排序',
    };
    final subtitle = switch (sort) {
      'most-albums' => '优先展示专辑量更多的风格，更适合整批浏览。',
      'most-tracks' => '优先展示歌曲更多的风格，适合快速开播。',
      _ => '按名称慢慢翻，适合直接找某个熟悉的风格。',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(26),
        boxShadow: ListenerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前视图',
            style: TextStyle(
              color: ListenerColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: ListenerColors.foreground,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: ListenerColors.softText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreLibraryCard extends StatelessWidget {
  final Genre genre;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  const _GenreLibraryCard({
    required this.genre,
    required this.onOpen,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FTappable(
            onPress: onOpen,
            builder: (context, states, child) {
              return AnimatedScale(
                scale: states.contains(FTappableVariant.pressed) ? 0.98 : 1,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: ListenerShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _GenreArt(name: genre.name)),
                      const SizedBox(height: 13),
                      Text(
                        genre.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ListenerColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${genre.albumCount} 张专辑',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ListenerColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${genre.trackCount} 首歌曲',
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
              );
            },
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: FTappable(
            onPress: onPlay,
            builder: (context, states, child) {
              return AnimatedScale(
                scale: states.contains(FTappableVariant.pressed) ? 0.94 : 1,
                duration: const Duration(milliseconds: 120),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ListenerColors.foreground,
                    shape: BoxShape.circle,
                    boxShadow: ListenerShadows.elevated,
                  ),
                  child: const Icon(
                    FLucideIcons.play,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GenreArt extends StatelessWidget {
  final String name;

  const _GenreArt({required this.name});

  @override
  Widget build(BuildContext context) {
    final seed = name.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final palettes = [
      const Color(0xFFEFF6FF),
      const Color(0xFFF8FAFC),
      const Color(0xFFF1F5F9),
      const Color(0xFFFDF2F8),
    ];
    final color = palettes[seed % palettes.length];

    return Center(
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: ListenerShadows.soft,
          ),
          child: Icon(
            FLucideIcons.audioLines,
            color: ListenerColors.foreground.withValues(alpha: 0.58),
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _GenresEmpty extends StatelessWidget {
  const _GenresEmpty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(FLucideIcons.audioLines, color: ListenerColors.muted, size: 48),
        SizedBox(height: 14),
        Text(
          '这里还没有风格',
          style: TextStyle(
            color: ListenerColors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '当前排序下暂时没有可浏览的内容。',
          style: TextStyle(color: ListenerColors.muted),
        ),
      ],
    );
  }
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
