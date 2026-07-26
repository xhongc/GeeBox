import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/search_provider.dart';
import 'forui_components.dart';
import 'listener_components.dart';

Future<void> showListenerTrackActionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Song song,
  String? imageUrl,
  List<Song>? queue,
  int? index,
}) {
  return showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: 0.82,
    builder: (context) => _ListenerTrackActionSheet(
      song: song,
      imageUrl: imageUrl,
      ref: ref,
      queue: queue,
      index: index,
    ),
  );
}

class _ListenerTrackActionSheet extends ConsumerStatefulWidget {
  final Song song;
  final String? imageUrl;
  final WidgetRef ref;
  final List<Song>? queue;
  final int? index;

  const _ListenerTrackActionSheet({
    required this.song,
    required this.ref,
    this.imageUrl,
    this.queue,
    this.index,
  });

  @override
  ConsumerState<_ListenerTrackActionSheet> createState() =>
      _ListenerTrackActionSheetState();
}

class _ListenerTrackActionSheetState
    extends ConsumerState<_ListenerTrackActionSheet> {
  bool _showPlaylists = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ListenerGradients.shell),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child:
              _showPlaylists ? _playlistPanel(context) : _actionsPanel(context),
        ),
      ),
    );
  }

  Widget _actionsPanel(BuildContext context) {
    final song = widget.song;
    final starredItems = ref.watch(starredItemsProvider).valueOrNull;
    final isStarred =
        starredItems?.songs.any((item) => item.id == song.id) ?? false;

    return Column(
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
        Row(
          children: [
            SizedBox.square(
              dimension: 62,
              child: ListenerCoverArt(
                imageUrl: widget.imageUrl,
                fallbackIcon: FLucideIcons.music,
                borderRadius: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '歌曲操作',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist ?? song.album ?? '未知艺术家',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ListenerColors.softText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SheetAction(
          icon: FLucideIcons.listEnd,
          title: '添加下一首',
          subtitle: '紧接当前歌曲播放',
          onPress: () {
            widget.ref.read(audioPlayerServiceProvider).addNext(song);
            Navigator.of(context).pop();
            showChansonToast(context, '已添加到下一首');
          },
        ),
        _SheetAction(
          icon: FLucideIcons.listPlus,
          title: '添加到队列',
          subtitle: '继续留在待播列表里',
          onPress: () {
            widget.ref.read(audioPlayerServiceProvider).addToQueue(song);
            Navigator.of(context).pop();
            showChansonToast(context, '已加入队列');
          },
        ),
        _SheetAction(
          icon: FLucideIcons.listMusic,
          title: '添加到播放列表',
          subtitle: '收藏进你自己的歌单',
          onPress: () {
            setState(() => _showPlaylists = true);
          },
        ),
        _SheetAction(
          icon: FLucideIcons.heart,
          title: isStarred ? '移出喜爱' : '添加到喜爱',
          subtitle: isStarred ? '从喜爱列表移除' : '点亮这首常听歌曲',
          onPress: () async {
            final service = widget.ref.read(favoriteServiceProvider);
            final ok = isStarred
                ? await service.unstarSong(song.id)
                : await service.starSong(song.id);
            if (!context.mounted) return;
            if (!ok) {
              showChansonToast(
                context,
                isStarred ? '移出喜爱失败' : '添加到喜爱失败',
                destructive: true,
              );
              return;
            }
            widget.ref.invalidate(starredItemsProvider);
            Navigator.of(context).pop();
            showChansonToast(context, isStarred ? '已移出喜爱' : '已添加到喜爱');
          },
        ),
        if (song.album != null)
          _SheetAction(
            icon: FLucideIcons.disc3,
            title: '查看专辑',
            subtitle: song.album!,
            onPress: () => _openAlbum(context, song),
          ),
        if (song.artist != null)
          _SheetAction(
            icon: FLucideIcons.userRound,
            title: '查看艺术家',
            subtitle: song.artist!,
            onPress: () => _openArtist(context, song),
          ),
      ],
    );
  }

  Widget _playlistPanel(BuildContext context) {
    final playlistsAsync = widget.ref.watch(playlistsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ListenerCircleButton(
              icon: FLucideIcons.chevronLeft,
              onPress: () => setState(() => _showPlaylists = false),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '添加到播放列表',
                    style: TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '选择一个列表收下这首歌',
                    style: TextStyle(color: ListenerColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return const SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    '还没有播放列表',
                    style: TextStyle(color: ListenerColors.muted),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final playlist in playlists)
                  _PlaylistAction(
                    playlist: playlist,
                    onPress: () => _addToPlaylist(context, playlist),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 150,
            child: Center(child: FCircularProgress()),
          ),
          error: (_, __) => SizedBox(
            height: 150,
            child: Center(
              child: FButton(
                variant: FButtonVariant.ghost,
                onPress: () => widget.ref.invalidate(playlistsProvider),
                child: const Text('重新加载播放列表'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addToPlaylist(
    BuildContext context,
    Playlist playlist,
  ) async {
    final ok = await widget.ref
        .read(playlistServiceProvider)
        .addSongToPlaylist(playlist.id, widget.song.id);
    refreshPlaylists(widget.ref);
    refreshPlaylist(widget.ref, playlist.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showChansonToast(context, ok ? '已添加到 ${playlist.name}' : '添加失败');
  }

  Future<void> _openAlbum(BuildContext context, Song song) async {
    final albumName = song.album;
    if (albumName == null || albumName.trim().isEmpty) return;

    final result =
        await widget.ref.read(searchServiceProvider).search(albumName);
    if (!context.mounted) return;
    Navigator.of(context).pop();

    final normalizedAlbum = _normalize(albumName);
    final normalizedArtist = _normalize(song.artist);
    final matches = result.albums.where((album) {
      final albumMatches = _normalize(album.name) == normalizedAlbum;
      if (!albumMatches) return false;
      if (normalizedArtist.isEmpty) return true;
      return _normalize(album.artist) == normalizedArtist;
    }).toList();
    final album = matches.isNotEmpty
        ? matches.first
        : result.albums
            .where((album) => _normalize(album.name) == normalizedAlbum)
            .firstOrNull;

    if (album == null) {
      context.push('/search?q=${Uri.encodeQueryComponent(albumName)}');
      showChansonToast(context, '未直接匹配专辑，已打开搜索结果');
      return;
    }

    context.push('/album-detail', extra: {
      'albumId': album.id,
      'albumName': album.name,
      'albumArtist': album.artist,
      'coverArtId': album.coverArt,
    });
  }

  Future<void> _openArtist(BuildContext context, Song song) async {
    final artistName = song.artist;
    if (artistName == null || artistName.trim().isEmpty) return;

    final result =
        await widget.ref.read(searchServiceProvider).search(artistName);
    if (!context.mounted) return;
    Navigator.of(context).pop();

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
}

String _normalize(String? value) => (value ?? '').trim().toLowerCase();

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPress;

  const _SheetAction({
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
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(22),
            boxShadow: ListenerShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ListenerColors.foreground, size: 19),
              ),
              const SizedBox(width: 13),
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
                        color: ListenerColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistAction extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onPress;

  const _PlaylistAction({
    required this.playlist,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return _SheetAction(
      icon: FLucideIcons.listMusic,
      title: playlist.name,
      subtitle: playlist.description ?? '播放列表',
      onPress: onPress,
    );
  }
}
