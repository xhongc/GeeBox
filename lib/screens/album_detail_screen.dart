import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

final albumDetailProvider =
    FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbum(albumId);
});

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  final String albumName;
  final String? albumArtist;
  final String? coverArtId;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    required this.albumName,
    this.albumArtist,
    this.coverArtId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(albumDetailProvider(albumId));
    final repository = ref.read(musicRepositoryProvider);
    final isStarred =
        ref.watch(isAlbumStarredProvider(albumId)).valueOrNull ?? false;
    final coverUrl = coverArtId == null
        ? null
        : repository.getCoverArtUrl(coverArtId!, size: 600);

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: Stack(
          children: [
            ListenerCoverBackdrop(
              imageUrl: coverUrl,
              fallbackIcon: FLucideIcons.disc3,
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: songsAsync.when(
                  data: (songs) => CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _AlbumTopBar(
                              artist: albumArtist,
                              isStarred: isStarred,
                              onBack: () => Navigator.of(context).pop(),
                              onArtist: albumArtist == null
                                  ? null
                                  : () => _openArtist(
                                        context,
                                        ref,
                                        albumArtist!,
                                      ),
                              onFavorite: () => _toggleAlbumFavorite(
                                context,
                                ref,
                                albumId,
                                isStarred,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _AlbumDetailHero(
                              title: albumName,
                              artist: albumArtist,
                              coverUrl: coverUrl,
                              trackCount: songs.length,
                              onArtist: albumArtist == null
                                  ? null
                                  : () => _openArtist(
                                        context,
                                        ref,
                                        albumArtist!,
                                      ),
                              duration: songs.fold<int>(
                                0,
                                (total, song) => total + (song.duration ?? 0),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _AlbumActions(
                              songs: songs,
                              onPlay: () => _playAlbum(ref, songs),
                              onShuffle: () => _shuffleAlbum(ref, songs),
                              onNext: () {
                                _addSongsNext(ref, songs);
                                showChansonToast(context, '已添加到下一首');
                              },
                              onQueue: () {
                                ref
                                    .read(audioPlayerServiceProvider)
                                    .addAllToQueue(songs);
                                showChansonToast(context, '已加入队列');
                              },
                            ),
                            const SizedBox(height: 26),
                            ListenerSectionHeader(
                              title: '${songs.length} 首歌曲',
                            ),
                            if (songs.isEmpty)
                              const SizedBox(
                                height: 180,
                                child: Center(
                                  child: Text(
                                    '暂无歌曲',
                                    style:
                                        TextStyle(color: ListenerColors.muted),
                                  ),
                                ),
                              )
                            else
                              for (final (index, song) in songs.indexed)
                                Builder(
                                  builder: (context) {
                                    final imageUrl = song.coverArt == null
                                        ? coverUrl
                                        : repository.getCoverArtUrl(
                                            song.coverArt!,
                                            size: 180,
                                          );
                                    return ListenerTrackRow(
                                      song: song,
                                      imageUrl: imageUrl,
                                      onPress: () => _playAlbum(
                                        ref,
                                        songs,
                                        initialIndex: index,
                                      ),
                                      onMore: () =>
                                          showListenerTrackActionSheet(
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
                            const SizedBox(height: 28),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: FCircularProgress()),
                  error: (_, __) => Center(
                    child: FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () =>
                          ref.invalidate(albumDetailProvider(albumId)),
                      child: const Text('重新加载专辑'),
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
}

class _AlbumTopBar extends StatelessWidget {
  final String? artist;
  final bool isStarred;
  final VoidCallback onBack;
  final VoidCallback? onArtist;
  final VoidCallback onFavorite;

  const _AlbumTopBar({
    required this.artist,
    required this.isStarred,
    required this.onBack,
    required this.onArtist,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ListenerCircleButton(
          icon: FLucideIcons.chevronLeft,
          onPress: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '专辑详情',
                style: TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              FTappable(
                onPress: onArtist,
                child: Text(
                  artist ?? '未知艺术家',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ListenerColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListenerCircleButton(
          icon: FLucideIcons.heart,
          iconColor:
              isStarred ? const Color(0xFFEF4444) : ListenerColors.foreground,
          onPress: onFavorite,
        ),
      ],
    );
  }
}

class _AlbumDetailHero extends StatelessWidget {
  final String title;
  final String? artist;
  final String? coverUrl;
  final int trackCount;
  final VoidCallback? onArtist;
  final int duration;

  const _AlbumDetailHero({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.trackCount,
    required this.onArtist,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final maxCoverSize = (height * 0.34).clamp(190.0, 304.0);
    final resolvedCoverSize = (width * 0.78).clamp(190.0, maxCoverSize);
    final discSize = resolvedCoverSize * 0.72;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(resolvedCoverSize * 0.30, 0),
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
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: resolvedCoverSize,
                  height: resolvedCoverSize,
                  child: ListenerPlayingArtCard(
                    imageUrl: coverUrl,
                    fallbackIcon: FLucideIcons.disc3,
                    borderRadius: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '专辑',
          style: TextStyle(
            color: ListenerColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ListenerColors.foreground,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        FTappable(
          onPress: onArtist,
          child: Text(
            artist ?? '未知艺术家',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ListenerColors.softText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '$trackCount 首歌曲 · ${formatSongDuration(duration)}',
          style: const TextStyle(
            color: ListenerColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _AlbumActions extends StatelessWidget {
  final List<Song> songs;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onNext;
  final VoidCallback onQueue;

  const _AlbumActions({
    required this.songs,
    required this.onPlay,
    required this.onShuffle,
    required this.onNext,
    required this.onQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FButton(
            onPress: songs.isEmpty ? null : onPlay,
            prefix: const Icon(FLucideIcons.play),
            child: const Text('播放'),
          ),
        ),
        const SizedBox(width: 10),
        _AlbumActionButton(
          icon: FLucideIcons.shuffle,
          label: '随机',
          onPress: songs.isEmpty ? null : onShuffle,
        ),
        const SizedBox(width: 10),
        _AlbumActionButton(
          icon: FLucideIcons.listEnd,
          label: '下一首',
          onPress: songs.isEmpty ? null : onNext,
        ),
        const SizedBox(width: 10),
        _AlbumActionButton(
          icon: FLucideIcons.listPlus,
          label: '队列',
          onPress: songs.isEmpty ? null : onQueue,
        ),
      ],
    );
  }
}

class _AlbumActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPress;

  const _AlbumActionButton({
    required this.icon,
    required this.label,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: FButtonVariant.secondary,
      onPress: onPress,
      prefix: Icon(icon),
      child: Text(label),
    );
  }
}

Future<void> _toggleAlbumFavorite(
  BuildContext context,
  WidgetRef ref,
  String albumId,
  bool isStarred,
) async {
  final service = ref.read(favoriteServiceProvider);
  final ok = isStarred
      ? await service.unstarAlbum(albumId)
      : await service.starAlbum(albumId);
  if (!context.mounted) return;
  if (!ok) {
    showChansonToast(
      context,
      isStarred ? '取消收藏专辑失败' : '收藏专辑失败',
      destructive: true,
    );
    return;
  }
  ref.invalidate(starredItemsProvider);
  ref.invalidate(isAlbumStarredProvider(albumId));
  showChansonToast(context, isStarred ? '已取消收藏专辑' : '已收藏专辑');
}

Future<void> _openArtist(
  BuildContext context,
  WidgetRef ref,
  String artistName,
) async {
  final result = await ref.read(searchServiceProvider).search(artistName);
  if (!context.mounted) return;

  final normalizedArtist = _normalize(artistName);
  final artist = result.artists
      .where((artist) => _normalize(artist.name) == normalizedArtist)
      .firstOrNull;

  if (artist == null) {
    context.push('/search?q=${Uri.encodeQueryComponent(artistName)}');
    showChansonToast(context, '未直接匹配艺术家，已打开搜索结果');
    return;
  }

  context.push('/artist-detail', extra: {
    'artistId': artist.id,
    'artistName': artist.name,
    'coverArtId': artist.coverArt,
  });
}

String _normalize(String? value) => (value ?? '').trim().toLowerCase();

Future<void> _playAlbum(
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

Future<void> _shuffleAlbum(WidgetRef ref, List<Song> songs) async {
  if (songs.isEmpty) return;
  final shuffled = List<Song>.from(songs)..shuffle();
  await _playAlbum(ref, shuffled);
}

void _addSongsNext(WidgetRef ref, List<Song> songs) {
  final player = ref.read(audioPlayerServiceProvider);
  for (final song in songs.reversed) {
    player.addNext(song);
  }
}
