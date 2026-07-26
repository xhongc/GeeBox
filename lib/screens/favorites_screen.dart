import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../models/starred_items.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/subsonic_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

/// Listener 风格喜爱页面
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _tab = 'tracks';

  @override
  Widget build(BuildContext context) {
    final starredItems = ref.watch(starredItemsProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              starredItems.when(
                data: (items) => _FavoritesHero(
                  tab: _tab,
                  count: _countForTab(items, _tab),
                  onTab: (tab) {
                    setState(() {
                      _tab = tab;
                    });
                  },
                  onPlay: items.songs.isEmpty
                      ? null
                      : () => _playSongs(ref, items.songs),
                  onShuffle: items.songs.isEmpty
                      ? null
                      : () => _shuffleSongs(ref, items.songs),
                ),
                loading: () => _FavoritesHero(
                  tab: _tab,
                  count: 0,
                  onTab: (tab) {
                    setState(() {
                      _tab = tab;
                    });
                  },
                ),
                error: (_, __) => _FavoritesHero(
                  tab: _tab,
                  count: 0,
                  onTab: (tab) {
                    setState(() {
                      _tab = tab;
                    });
                  },
                ),
              ),
              const SizedBox(height: 22),
              starredItems.when(
                data: (items) {
                  return switch (_tab) {
                    'albums' => _FavoriteAlbums(albums: items.albums),
                    'artists' => _FavoriteArtists(artists: items.artists),
                    _ => _FavoriteSongs(songs: items.songs),
                  };
                },
                loading: () => const SizedBox(
                  height: 220,
                  child: Center(child: FCircularProgress()),
                ),
                error: (_, __) => SizedBox(
                  height: 220,
                  child: Center(
                    child: FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () => ref.invalidate(starredItemsProvider),
                      child: const Text('重新加载收藏'),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  int _countForTab(StarredItems items, String tab) {
    return switch (tab) {
      'albums' => items.albums.length,
      'artists' => items.artists.length,
      _ => items.songs.length,
    };
  }
}

class _FavoritesHero extends StatelessWidget {
  final String tab;
  final int count;
  final ValueChanged<String> onTab;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const _FavoritesHero({
    required this.tab,
    required this.count,
    required this.onTab,
    this.onPlay,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final activeLabel = switch (tab) {
      'albums' => '专辑',
      'artists' => '艺术家',
      _ => '歌曲',
    };

    final title = switch (tab) {
      'albums' => '喜爱的专辑',
      'artists' => '喜爱的艺术家',
      _ => '喜爱的歌曲',
    };

    final summary = switch (tab) {
      'albums' => '把常听专辑集中放在这里，随时继续播放。',
      'artists' => '收藏过的艺术家会整理在这里，方便继续探索。',
      _ => '你标记过的歌曲会留在这里，适合直接开播。',
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
                    '喜爱',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ListenerColors.foreground,
                shape: BoxShape.circle,
                boxShadow: ListenerShadows.soft,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _FavouriteTab(
              label: '专辑',
              value: 'albums',
              selected: tab,
              onTab: onTab,
            ),
            const SizedBox(width: 10),
            _FavouriteTab(
              label: '艺术家',
              value: 'artists',
              selected: tab,
              onTab: onTab,
            ),
            const SizedBox(width: 10),
            _FavouriteTab(
              label: '歌曲',
              value: 'tracks',
              selected: tab,
              onTab: onTab,
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                '我的收藏',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '已收录 $count 个$activeLabel',
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary,
                style: const TextStyle(
                  color: ListenerColors.softText,
                  fontSize: 13,
                ),
              ),
              if (tab == 'tracks' && count > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    FButton(
                      onPress: onPlay,
                      prefix: const Icon(FLucideIcons.play),
                      child: const Text('播放全部'),
                    ),
                    const SizedBox(width: 10),
                    FButton(
                      variant: FButtonVariant.secondary,
                      onPress: onShuffle,
                      prefix: const Icon(FLucideIcons.shuffle),
                      child: const Text('打乱'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FavouriteTab extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTab;

  const _FavouriteTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;

    return Expanded(
      child: FTappable(
        onPress: () => onTab(value),
        builder: (context, states, child) {
          return AnimatedContainer(
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
              style: TextStyle(
                color: active ? Colors.white : ListenerColors.softText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteAlbums extends ConsumerWidget {
  final List<Album> albums;

  const _FavoriteAlbums({required this.albums});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (albums.isEmpty) {
      return const _FavoritesEmpty(message: '还没有喜爱的专辑，去发现页收下几张吧。');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: albums.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        return Stack(
          children: [
            Positioned.fill(
              child: ListenerAlbumCard(
                album: album,
                imageUrl: _albumCoverUrl(ref, album),
                onPress: () => context.push('/album-detail', extra: {
                  'albumId': album.id,
                  'albumName': album.name,
                  'albumArtist': album.artist,
                  'coverArtId': album.coverArt,
                }),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _FavouriteCircleButton(
                onPress: () async {
                  final ok = await ref
                      .read(favoriteServiceProvider)
                      .unstarAlbum(album.id);
                  if (!context.mounted) return;
                  if (!ok) {
                    showChansonToast(context, '取消收藏专辑失败', destructive: true);
                    return;
                  }
                  ref.invalidate(starredItemsProvider);
                  showChansonToast(context, '已取消收藏专辑');
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FavoriteArtists extends ConsumerWidget {
  final List<Artist> artists;

  const _FavoriteArtists({required this.artists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (artists.isEmpty) {
      return const _FavoritesEmpty(message: '还没有喜爱的艺术家，先去挑几个喜欢的声音。');
    }

    return Column(
      children: [
        for (final artist in artists)
          FTappable(
            onPress: () => context.push('/artist-detail', extra: {
              'artistId': artist.id,
              'artistName': artist.name,
              'coverArtId': artist.coverArt,
            }),
            builder: (context, states, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: ListenerShadows.soft,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 58,
                      child: ClipOval(
                        child: ListenerCoverArt(
                          imageUrl: _artistCoverUrl(ref, artist),
                          fallbackIcon: FLucideIcons.userRound,
                          borderRadius: 999,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 4),
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
                    _FavouriteCircleButton(
                      onPress: () async {
                        final ok = await ref
                            .read(favoriteServiceProvider)
                            .unstarArtist(artist.id);
                        if (!context.mounted) return;
                        if (!ok) {
                          showChansonToast(context, '取消收藏艺术家失败',
                              destructive: true);
                          return;
                        }
                        ref.invalidate(starredItemsProvider);
                        showChansonToast(context, '已取消收藏艺术家');
                      },
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      FLucideIcons.chevronRight,
                      color: ListenerColors.muted,
                      size: 19,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _FavoriteSongs extends ConsumerWidget {
  final List<Song> songs;

  const _FavoriteSongs({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) {
      return const _FavoritesEmpty(message: '还没有喜爱的歌曲，点亮心形后会出现在这里。');
    }

    return Column(
      children: [
        for (final (index, song) in songs.indexed)
          Builder(
            builder: (context) {
              final imageUrl = _coverUrl(ref, song);
              return ListenerTrackRow(
                song: song,
                imageUrl: imageUrl,
                onPress: () => _playSongs(
                  ref,
                  songs,
                  initialIndex: index,
                ),
                onFavorite: () async {
                  final ok = await ref
                      .read(favoriteServiceProvider)
                      .unstarSong(song.id);
                  if (!context.mounted) return;
                  if (!ok) {
                    showChansonToast(context, '取消收藏失败', destructive: true);
                    return;
                  }
                  ref.invalidate(starredItemsProvider);
                  showChansonToast(context, '已取消收藏');
                },
                onMore: () => showListenerTrackActionSheet(
                  context: context,
                  ref: ref,
                  song: song,
                  imageUrl: imageUrl,
                  queue: songs,
                  index: index,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _FavouriteCircleButton extends StatelessWidget {
  final VoidCallback onPress;

  const _FavouriteCircleButton({required this.onPress});

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: ListenerShadows.soft,
          ),
          child: const Icon(
            FLucideIcons.heart,
            color: Color(0xFFEF4444),
            size: 18,
          ),
        );
      },
    );
  }
}

class _FavoritesEmpty extends StatelessWidget {
  final String message;

  const _FavoritesEmpty({
    this.message = '点亮心形后会出现在这里。',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FLucideIcons.heart,
                color: ListenerColors.muted, size: 54),
            const SizedBox(height: 14),
            const Text(
              '这里还没有内容',
              style: TextStyle(
                color: ListenerColors.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ListenerColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

String? _coverUrl(WidgetRef ref, Song song) {
  if (song.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(song.coverArt!);
}

String? _albumCoverUrl(WidgetRef ref, Album album) {
  if (album.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(album.coverArt!);
}

String? _artistCoverUrl(WidgetRef ref, Artist artist) {
  if (artist.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(artist.coverArt!);
}

Future<void> _playSongs(
  WidgetRef ref,
  List<Song> songs, {
  int initialIndex = 0,
}) async {
  if (songs.isEmpty) return;
  final audioService = ref.read(audioPlayerServiceProvider);
  final subsonicService = ref.read(subsonicServiceProvider);
  await audioService.setPlaylist(songs, initialIndex: initialIndex);
  await audioService.playAtIndex(
    initialIndex,
    (songId) => subsonicService.getStreamUrl(songId),
  );
}

Future<void> _shuffleSongs(WidgetRef ref, List<Song> songs) async {
  final shuffled = List<Song>.from(songs)..shuffle();
  await _playSongs(ref, shuffled);
}
