import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/artist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

class ArtistsScreen extends ConsumerStatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ConsumerState<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends ConsumerState<ArtistsScreen> {
  String _sortValue = 'most-albums';
  String? _initialFilter;

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(artistsProvider);
    final filteredSnapshot = artistsAsync.valueOrNull == null
        ? const <Artist>[]
        : _filteredArtists(artistsAsync.valueOrNull!);

    return ListenerPageBackground(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ArtistsHero(
                  sortValue: _sortValue,
                  onSort: (value) => setState(() {
                    _sortValue = value;
                    if (value != 'a-z') _initialFilter = null;
                  }),
                  onRefresh: () => ref.invalidate(artistsProvider),
                  count: filteredSnapshot.length,
                  onPlayFirst: filteredSnapshot.isEmpty
                      ? null
                      : () => _playArtist(ref, filteredSnapshot.first),
                  onPlayRandom: filteredSnapshot.isEmpty
                      ? null
                      : () {
                          final shuffled = List<Artist>.from(filteredSnapshot)
                            ..shuffle();
                          _playArtist(ref, shuffled.first);
                        },
                ),
                const SizedBox(height: 18),
                if (_sortValue == 'a-z' && filteredSnapshot.isNotEmpty) ...[
                  _ArtistInitialIndex(
                    initials: _artistInitials(artistsAsync.valueOrNull ?? []),
                    selected: _initialFilter,
                    onSelect: (value) => setState(() {
                      _initialFilter = value == _initialFilter ? null : value;
                    }),
                    onAll: () => setState(() => _initialFilter = null),
                  ),
                  const SizedBox(height: 16),
                ],
                artistsAsync.when(
                  data: (artists) {
                    final filtered = _filteredArtists(artists);
                    if (filtered.isEmpty) {
                      return const _ArtistsEmpty();
                    }

                    return Column(
                      children: [
                        for (final artist in filtered)
                          _ArtistRow(
                            artist: artist,
                            imageUrl: artist.coverArt == null
                                ? null
                                : ref
                                    .read(musicRepositoryProvider)
                                    .getCoverArtUrl(
                                      artist.coverArt!,
                                      size: 180,
                                    ),
                            onOpen: () =>
                                context.push('/artist-detail', extra: {
                              'artistId': artist.id,
                              'artistName': artist.name,
                              'coverArtId': artist.coverArt,
                            }),
                            onPlay: () => _playArtist(ref, artist),
                          ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 260,
                    child: Center(child: FCircularProgress()),
                  ),
                  error: (_, __) => SizedBox(
                    height: 260,
                    child: Center(
                      child: FButton(
                        variant: FButtonVariant.ghost,
                        onPress: () => ref.invalidate(artistsProvider),
                        child: const Text('重新加载艺术家'),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Artist> _filteredArtists(List<Artist> artists) {
    final filtered = List<Artist>.from(artists);

    switch (_sortValue) {
      case 'a-z':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'less_cover':
        filtered.sort((a, b) {
          final aMissing = a.coverArt == null || a.coverArt!.isEmpty;
          final bMissing = b.coverArt == null || b.coverArt!.isEmpty;
          if (aMissing == bMissing) return a.name.compareTo(b.name);
          return aMissing ? -1 : 1;
        });
        break;
      default:
        filtered.sort(
          (a, b) => (b.albumCount ?? 0).compareTo(a.albumCount ?? 0),
        );
    }

    if (_initialFilter != null) {
      filtered.removeWhere(
          (artist) => _artistInitial(artist.name) != _initialFilter);
    }

    return filtered;
  }
}

class _ArtistInitialIndex extends StatelessWidget {
  final List<String> initials;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onAll;

  const _ArtistInitialIndex({
    required this.initials,
    required this.selected,
    required this.onSelect,
    required this.onAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _InitialPill(
            label: '全部',
            active: selected == null,
            onPress: onAll,
          ),
          const SizedBox(width: 8),
          for (final initial in initials) ...[
            _InitialPill(
              label: initial,
              active: selected == initial,
              onPress: () => onSelect(initial),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _InitialPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPress;

  const _InitialPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? ListenerColors.foreground
              : Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(999),
          boxShadow: ListenerShadows.soft,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : ListenerColors.softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ArtistsHero extends StatelessWidget {
  final String sortValue;
  final ValueChanged<String> onSort;
  final VoidCallback onRefresh;
  final int count;
  final VoidCallback? onPlayFirst;
  final VoidCallback? onPlayRandom;

  const _ArtistsHero({
    required this.sortValue,
    required this.onSort,
    required this.onRefresh,
    required this.count,
    required this.onPlayFirst,
    required this.onPlayRandom,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (sortValue) {
      'a-z' => 'A-Z排序',
      'less_cover' => '缺失封面',
      _ => '最多专辑',
    };
    final summary = switch (sortValue) {
      'a-z' => '按名称浏览艺术家列表，找人会更直接。',
      'less_cover' => '这里是还缺封面的艺术家，后续可以继续补全。',
      _ => '优先查看作品最多的艺术家，适合顺着专辑量往下听。',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '艺术家收藏',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ListenerCircleButton(
              icon: FLucideIcons.refreshCw,
              onPress: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ArtistTab(
              label: '最多专辑',
              value: 'most-albums',
              selected: sortValue,
              onSort: onSort,
            ),
            const SizedBox(width: 10),
            _ArtistTab(
              label: 'A-Z排序',
              value: 'a-z',
              selected: sortValue,
              onSort: onSort,
            ),
            const SizedBox(width: 10),
            _ArtistTab(
              label: '缺失封面',
              value: 'less_cover',
              selected: sortValue,
              onSort: onSort,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
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
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$summary 当前加载 $count 位。',
                style: const TextStyle(
                  color: ListenerColors.softText,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      onPress: onPlayFirst,
                      prefix: const Icon(FLucideIcons.play, size: 17),
                      child: const Text('播放第一位'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: onPlayRandom,
                      prefix: const Icon(FLucideIcons.shuffle, size: 17),
                      child: const Text('随机一位'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArtistTab extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSort;

  const _ArtistTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;

    return Expanded(
      child: FTappable(
        onPress: () => onSort(value),
        builder: (context, states, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? ListenerColors.foreground
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            boxShadow: ListenerShadows.soft,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : ListenerColors.softText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtistRow extends StatelessWidget {
  final Artist artist;
  final String? imageUrl;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  const _ArtistRow({
    required this.artist,
    required this.imageUrl,
    required this.onOpen,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        boxShadow: ListenerShadows.soft,
      ),
      child: FTappable(
        onPress: onOpen,
        builder: (context, states, child) => Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 58,
                child: ListenerCoverArt(
                  imageUrl: imageUrl,
                  fallbackIcon: FLucideIcons.userRound,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${artist.albumCount ?? 0} 张专辑',
                      style: const TextStyle(
                        color: ListenerColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FTappable(
                onPress: onPlay,
                builder: (context, states, child) {
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: states.contains(FTappableVariant.pressed) ? 0.94 : 1,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: ListenerColors.foreground,
                        shape: BoxShape.circle,
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
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _playArtist(WidgetRef ref, Artist artist) async {
  final context = ref.context;
  try {
    final repository = ref.read(musicRepositoryProvider);
    final songs = await repository.getArtistSongs(artist.id);
    if (!context.mounted) return;
    if (songs.isEmpty) {
      showChansonToast(context, '这位艺术家暂无歌曲');
      return;
    }
    await _playSongs(ref, songs);
  } catch (error) {
    if (!context.mounted) return;
    showChansonToast(context, '播放艺术家失败: $error', destructive: true);
  }
}

Future<void> _playSongs(WidgetRef ref, List<Song> songs) async {
  final player = ref.read(audioPlayerServiceProvider);
  final repository = ref.read(musicRepositoryProvider);
  await player.setPlaylist(songs);
  await player.playAtIndex(
    0,
    (songId) => repository.getStreamUrl(songId),
  );
}

List<String> _artistInitials(List<Artist> artists) {
  final initials = artists.map((artist) => _artistInitial(artist.name)).toSet()
    ..remove('');
  final sorted = initials.toList()
    ..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  return sorted;
}

String _artistInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final first = trimmed.characters.first.toUpperCase();
  return RegExp(r'^[A-Z]$').hasMatch(first) ? first : '#';
}

class _ArtistsEmpty extends StatelessWidget {
  const _ArtistsEmpty();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FLucideIcons.userRound, color: ListenerColors.muted, size: 54),
            SizedBox(height: 14),
            Text(
              '还没有艺术家',
              style: TextStyle(
                color: ListenerColors.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '这个分类下暂时没有内容，切换一个筛选看看。',
              textAlign: TextAlign.center,
              style: TextStyle(color: ListenerColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
