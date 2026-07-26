import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

final artistDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, artistId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getArtist(artistId);
});

class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;
  final String artistName;
  final String? coverArtId;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverArtId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailProvider(artistId));
    final songsAsync = ref.watch(artistSongsProvider(artistId));
    final repository = ref.read(musicRepositoryProvider);
    final coverUrl = coverArtId == null
        ? null
        : repository.getCoverArtUrl(coverArtId!, size: 600);

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: Stack(
          children: [
            Positioned(
              top: -56,
              left: -32,
              right: -32,
              height: 260,
              child: Opacity(
                opacity: 0.18,
                child: ListenerCoverArt(
                  imageUrl: coverUrl,
                  fallbackIcon: FLucideIcons.userRound,
                  borderRadius: 0,
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: artistAsync.when(
                  data: (artistData) {
                    if (artistData == null) {
                      return const Center(
                        child: Text(
                          '加载失败',
                          style: TextStyle(color: ListenerColors.muted),
                        ),
                      );
                    }

                    final albums = _parseAlbums(artistData);

                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _ArtistTopBar(
                                albumCount: albums.length,
                                onBack: () => Navigator.of(context).pop(),
                                onFavorite: () async {
                                  final ok = await ref
                                      .read(favoriteServiceProvider)
                                      .starArtist(artistId);
                                  if (!context.mounted) return;
                                  if (!ok) {
                                    showChansonToast(context, '收藏艺术家失败',
                                        destructive: true);
                                    return;
                                  }
                                  showChansonToast(context, '已收藏艺术家');
                                },
                              ),
                              const SizedBox(height: 22),
                              _ArtistDetailHero(
                                name: artistName,
                                coverUrl: coverUrl,
                                albumCount: albums.length,
                              ),
                              const SizedBox(height: 20),
                              _ArtistActions(
                                hasAlbums: albums.isNotEmpty,
                                hasSongs:
                                    songsAsync.valueOrNull?.isNotEmpty ?? false,
                                onPlay: () {
                                  final songs = songsAsync.valueOrNull ?? [];
                                  _playSongs(ref, songs);
                                },
                                onShuffle: () {
                                  final songs = songsAsync.valueOrNull ?? [];
                                  _shuffleSongs(ref, songs);
                                },
                                onTracks: () =>
                                    _openArtistTracks(context, albums.length),
                              ),
                              const SizedBox(height: 26),
                              ListenerSectionHeader(
                                title: '专辑',
                                actionLabel: '${albums.length}',
                              ),
                              if (albums.isEmpty)
                                const SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: Text(
                                      '暂无专辑',
                                      style: TextStyle(
                                          color: ListenerColors.muted),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: albums.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemBuilder: (context, index) {
                                    final album = albums[index];
                                    return ListenerAlbumCard(
                                      album: album,
                                      imageUrl: album.coverArt == null
                                          ? null
                                          : repository.getCoverArtUrl(
                                              album.coverArt!,
                                            ),
                                      onPress: () => _openAlbum(context, album),
                                    );
                                  },
                                ),
                              const SizedBox(height: 28),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: FCircularProgress()),
                  error: (_, __) => Center(
                    child: FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () =>
                          ref.invalidate(artistDetailProvider(artistId)),
                      child: const Text('重新加载艺术家'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Album> _parseAlbums(Map<String, dynamic> artistData) {
    final albums = <Album>[];
    final albumList = artistData['album'];
    if (albumList is List) {
      albums.addAll(
        albumList.map((json) => Album.fromJson((json as Map).cast())),
      );
    } else if (albumList is Map) {
      albums.add(Album.fromJson(albumList.cast<String, dynamic>()));
    }
    return albums;
  }

  void _openAlbum(BuildContext context, Album album) {
    context.push('/album-detail', extra: {
      'albumId': album.id,
      'albumName': album.name,
      'albumArtist': album.artist ?? artistName,
      'coverArtId': album.coverArt,
    });
  }

  void _openArtistTracks(BuildContext context, int albumCount) {
    context.push('/artist-tracks', extra: {
      'artistId': artistId,
      'artistName': artistName,
      'coverArtId': coverArtId,
      'albumCount': albumCount,
    });
  }
}

class _ArtistTopBar extends StatelessWidget {
  final int albumCount;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  const _ArtistTopBar({
    required this.albumCount,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '艺术家详情',
                style: TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$albumCount 张专辑',
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
        ListenerCircleButton(icon: FLucideIcons.heart, onPress: onFavorite),
      ],
    );
  }
}

class _ArtistDetailHero extends StatelessWidget {
  final String name;
  final String? coverUrl;
  final int albumCount;

  const _ArtistDetailHero({
    required this.name,
    required this.coverUrl,
    required this.albumCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: ListenerShadows.elevated,
          ),
          child: ClipOval(
            child: ListenerCoverArt(
              imageUrl: coverUrl,
              fallbackIcon: FLucideIcons.userRound,
              borderRadius: 999,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '艺术家',
          style: TextStyle(
            color: ListenerColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ListenerColors.foreground,
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$albumCount 张专辑 · 继续探索这个声音',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ListenerColors.softText,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ArtistActions extends StatelessWidget {
  final bool hasAlbums;
  final bool hasSongs;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onTracks;

  const _ArtistActions({
    required this.hasAlbums,
    required this.hasSongs,
    required this.onPlay,
    required this.onShuffle,
    required this.onTracks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FButton(
            onPress: hasSongs ? onPlay : null,
            prefix: const Icon(FLucideIcons.play),
            child: const Text('播放热门'),
          ),
        ),
        const SizedBox(width: 10),
        FButton(
          variant: FButtonVariant.secondary,
          onPress: hasSongs ? onShuffle : null,
          prefix: const Icon(FLucideIcons.shuffle),
          child: const Text('随机'),
        ),
        const SizedBox(width: 10),
        FButton(
          variant: FButtonVariant.outline,
          onPress: hasAlbums ? onTracks : null,
          prefix: const Icon(FLucideIcons.listMusic),
          child: const Text('全部歌曲'),
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

Future<void> _shuffleSongs(WidgetRef ref, List<Song> songs) async {
  final shuffled = List<Song>.from(songs)..shuffle();
  await _playSongs(ref, shuffled);
}
