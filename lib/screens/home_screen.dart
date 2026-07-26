import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/genre.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/subsonic_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(listenerHomeProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _HomeHeading(
                onSearch: () => context.push('/search'),
                onAccount: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              homeAsync.when(
                data: (home) => _ListenerHero(
                  song:
                      home.randomSongs.isEmpty ? null : home.randomSongs.first,
                  imageUrl: _songCoverUrl(
                    ref,
                    home.randomSongs.isEmpty ? null : home.randomSongs.first,
                  ),
                  onPlay: home.randomSongs.isEmpty
                      ? null
                      : () => _playSongs(
                            ref,
                            home.randomSongs,
                            initialIndex: 0,
                          ),
                ),
                loading: () => const _HeroLoading(),
                error: (_, __) => const _ListenerHero(
                  song: null,
                  imageUrl: null,
                  onPlay: null,
                ),
              ),
              const SizedBox(height: 26),
              ListenerSectionHeader(
                title: '播放列表',
                actionLabel: '全部',
                onAction: () => context.push('/playlist-management'),
              ),
              _PlaylistShortcuts(
                onOpen: () => context.push('/playlist-management'),
              ),
              const SizedBox(height: 28),
              ListenerSectionHeader(
                title: '新专辑',
                actionLabel: '全部',
                onAction: () => context.push('/albums'),
              ),
              homeAsync.when(
                data: (home) => _AlbumGrid(albums: home.recentAlbums, ref: ref),
                loading: () => const _ThreeColumnLoading(),
                error: (_, __) => _InlineError(
                  label: '无法加载专辑',
                  onRetry: () => ref.invalidate(listenerHomeProvider),
                ),
              ),
              const SizedBox(height: 28),
              ListenerSectionHeader(
                title: '热门艺术家',
                actionLabel: '全部',
                onAction: () => context.push('/artists'),
              ),
              homeAsync.when(
                data: (home) => _ArtistGrid(artists: home.artists, ref: ref),
                loading: () => const _ThreeColumnLoading(round: true),
                error: (_, __) => _InlineError(
                  label: '无法加载艺术家',
                  onRetry: () => ref.invalidate(listenerHomeProvider),
                ),
              ),
              const SizedBox(height: 28),
              ListenerSectionHeader(
                title: '风格浏览',
                actionLabel: '全部',
                onAction: () => context.push('/genres'),
              ),
              homeAsync.when(
                data: (home) => _GenreGrid(genres: home.genres),
                loading: () => const _GenreLoading(),
                error: (_, __) => _InlineError(
                  label: '无法加载风格',
                  onRetry: () => ref.invalidate(listenerHomeProvider),
                ),
              ),
              const SizedBox(height: 28),
              ListenerSectionHeader(
                title: '歌曲列表',
                actionLabel: '全部',
                onAction: () => context.push('/songs'),
              ),
              homeAsync.when(
                data: (home) => _SongList(songs: home.randomSongs, ref: ref),
                loading: () => const _TrackListLoading(),
                error: (_, __) => _InlineError(
                  label: '无法加载歌曲',
                  onRetry: () => ref.invalidate(listenerHomeProvider),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HomeHeading extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onAccount;

  const _HomeHeading({required this.onSearch, required this.onAccount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Music',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '为你打开今天的旋律',
                style: TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ListenerCircleButton(
          icon: FLucideIcons.search,
          onPress: onSearch,
        ),
        const SizedBox(width: 9),
        ListenerCircleButton(
          icon: FLucideIcons.userRound,
          onPress: onAccount,
        ),
      ],
    );
  }
}

class _ListenerHero extends StatelessWidget {
  final Song? song;
  final String? imageUrl;
  final VoidCallback? onPlay;

  const _ListenerHero({
    required this.song,
    required this.imageUrl,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPlay,
      builder: (context, states, child) {
        return AnimatedScale(
          scale: states.contains(FTappableVariant.pressed) ? 0.99 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 205,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                  blurRadius: 54,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListenerCoverArt(
                    imageUrl: imageUrl,
                    fallbackIcon: FLucideIcons.music,
                    borderRadius: 0,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x14FFFFFF),
                          Color(0x7A0F172A),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 82,
                  top: 22,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          song?.artist ?? '精选推荐',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        song?.title ?? '随机播放',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song == null
                            ? '从你的音乐库发现声音'
                            : '来自 ${song!.album ?? '你的音乐库'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FLucideIcons.play,
                      color: onPlay == null
                          ? ListenerColors.muted
                          : ListenerColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroLoading extends StatelessWidget {
  const _HeroLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(child: FCircularProgress()),
    );
  }
}

class _PlaylistShortcuts extends StatelessWidget {
  final VoidCallback onOpen;

  const _PlaylistShortcuts({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FTappable(
          onPress: onOpen,
          builder: (context, states, child) {
            return AnimatedScale(
              scale: states.contains(FTappableVariant.pressed) ? 0.99 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: ListenerShadows.soft,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Playlist',
                            style: TextStyle(
                              color: ListenerColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '把常听的旋律放进一份清单',
                            style: TextStyle(
                              color: ListenerColors.foreground,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '最近添加、A-Z 排序都能从这里直接进入。',
                            style: TextStyle(
                              color: ListenerColors.softText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ListenerColors.foreground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: ListenerShadows.soft,
                      ),
                      child: const Icon(
                        FLucideIcons.listMusic,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _PlaylistShortcut(
                title: '最近添加',
                subtitle: '先看刚整理好的歌单',
                onPress: onOpen,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: _PlaylistShortcut(
                title: 'A-Z 排序',
                subtitle: '按名字快速找到目标',
                onPress: onOpen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlaylistShortcut extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const _PlaylistShortcut({
    required this.title,
    required this.subtitle,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return AnimatedScale(
          scale: states.contains(FTappableVariant.pressed) ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 81,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(20),
              boxShadow: ListenerShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ListenerColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ListenerColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final WidgetRef ref;

  const _AlbumGrid({required this.albums, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) return const _EmptyInline(label: '暂无新专辑');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: albums.length.clamp(0, 3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 13,
        mainAxisSpacing: 13,
        childAspectRatio: 0.63,
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        return ListenerAlbumCard(
          album: album,
          imageUrl: _albumCoverUrl(ref, album),
          onPress: () => context.push('/album-detail', extra: {
            'albumId': album.id,
            'albumName': album.name,
            'albumArtist': album.artist,
            'coverArtId': album.coverArt,
          }),
        );
      },
    );
  }
}

class _ArtistGrid extends StatelessWidget {
  final List<Artist> artists;
  final WidgetRef ref;

  const _ArtistGrid({required this.artists, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) return const _EmptyInline(label: '暂无艺术家');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artists.length.clamp(0, 3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ListenerArtistCard(
          artist: artist,
          imageUrl: artist.coverArt == null
              ? null
              : ref
                  .read(musicRepositoryProvider)
                  .getCoverArtUrl(artist.coverArt!, size: 180),
          onPress: () => context.push('/artist-detail', extra: {
            'artistId': artist.id,
            'artistName': artist.name,
            'coverArtId': artist.coverArt,
          }),
        );
      },
    );
  }
}

class _GenreGrid extends StatelessWidget {
  final List<Genre> genres;

  const _GenreGrid({required this.genres});

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const _EmptyInline(label: '暂无风格');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: genres.length.clamp(0, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.02,
      ),
      itemBuilder: (context, index) {
        final genre = genres[index];
        return ListenerGenreCard(
          name: genre.name,
          subtitle:
              genre.trackCount == 0 ? '探索你的音乐库' : '${genre.trackCount} 首歌曲',
          onPress: () => context.push('/genre-detail', extra: {
            'genreName': genre.name,
            'albumCount': genre.albumCount,
            'trackCount': genre.trackCount,
          }),
        );
      },
    );
  }
}

class _SongList extends StatelessWidget {
  final List<Song> songs;
  final WidgetRef ref;

  const _SongList({required this.songs, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const _EmptyInline(label: '暂无歌曲');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length.clamp(0, 6),
      itemBuilder: (context, index) {
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
      },
    );
  }
}

class _ThreeColumnLoading extends StatelessWidget {
  final bool round;

  const _ThreeColumnLoading({this.round = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 13),
            child: AspectRatio(
              aspectRatio: round ? 0.94 : 0.63,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.54),
                  borderRadius: BorderRadius.circular(round ? 22 : 19),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreLoading extends StatelessWidget {
  const _GenreLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 156,
      child: Center(child: FCircularProgress()),
    );
  }
}

class _TrackListLoading extends StatelessWidget {
  const _TrackListLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: FCircularProgress()),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String label;
  final VoidCallback onRetry;

  const _InlineError({required this.label, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: FButton(
        variant: FButtonVariant.ghost,
        onPress: onRetry,
        child: Text(label),
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String label;

  const _EmptyInline({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(color: ListenerColors.muted),
      ),
    );
  }
}

String? _songCoverUrl(WidgetRef ref, Song? song) {
  if (song?.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(song!.coverArt!);
}

String? _albumCoverUrl(WidgetRef ref, Album album) {
  if (album.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(album.coverArt!);
}

Future<void> _playSongs(
  WidgetRef ref,
  List<Song> songs, {
  required int initialIndex,
}) async {
  if (songs.isEmpty) return;
  final player = ref.read(audioPlayerServiceProvider);
  final subsonic = ref.read(subsonicServiceProvider);
  await player.setPlaylist(songs, initialIndex: initialIndex);
  await player.playAtIndex(
    initialIndex,
    (songId) => subsonic.getStreamUrl(songId),
  );
}
