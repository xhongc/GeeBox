import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

final artistAlbumsProvider = FutureProvider.family
    .autoDispose<List<Album>, String>((ref, artistId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getArtistAlbums(artistId);
});

class ArtistTracksScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? coverArtId;

  const ArtistTracksScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverArtId,
  });

  @override
  ConsumerState<ArtistTracksScreen> createState() => _ArtistTracksScreenState();
}

class _ArtistTracksScreenState extends ConsumerState<ArtistTracksScreen> {
  String _section = 'albums';

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(artistAlbumsProvider(widget.artistId));
    final songsAsync = ref.watch(artistSongsProvider(widget.artistId));

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ArtistTracksHeader(
                      artistName: widget.artistName,
                      section: _section,
                      onBack: () => Navigator.of(context).pop(),
                      onSection: (section) {
                        setState(() => _section = section);
                      },
                    ),
                    const SizedBox(height: 18),
                    songsAsync.when(
                      data: (songs) => _ArtistTracksSummary(
                        section: _section,
                        artistName: widget.artistName,
                        count: _section == 'tracks'
                            ? songs.length
                            : albumsAsync.valueOrNull?.length ?? 0,
                        onPlay:
                            songs.isEmpty ? null : () => _playSongs(ref, songs),
                        onShuffle: songs.isEmpty
                            ? null
                            : () => _shuffleSongs(ref, songs),
                      ),
                      loading: () => _ArtistTracksSummary(
                        section: _section,
                        artistName: widget.artistName,
                        count: 0,
                        loading: true,
                        onPlay: null,
                        onShuffle: null,
                      ),
                      error: (_, __) => _ArtistTracksSummary(
                        section: _section,
                        artistName: widget.artistName,
                        count: 0,
                        onPlay: null,
                        onShuffle: null,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_section == 'albums')
                      albumsAsync.when(
                        data: (albums) => _AlbumGrid(albums: albums),
                        loading: () => const _LoadingBlock(label: '正在加载专辑...'),
                        error: (_, __) => _ReloadBlock(
                          label: '重新加载专辑',
                          onPress: () => ref.invalidate(
                              artistAlbumsProvider(widget.artistId)),
                        ),
                      )
                    else
                      songsAsync.when(
                        data: (songs) => _TrackList(songs: songs),
                        loading: () => const _LoadingBlock(label: '正在加载歌曲...'),
                        error: (_, __) => _ReloadBlock(
                          label: '重新加载歌曲',
                          onPress: () => ref
                              .invalidate(artistSongsProvider(widget.artistId)),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistTracksHeader extends StatelessWidget {
  final String artistName;
  final String section;
  final VoidCallback onBack;
  final ValueChanged<String> onSection;

  const _ArtistTracksHeader({
    required this.artistName,
    required this.section,
    required this.onBack,
    required this.onSection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ListenerCircleButton(
                icon: FLucideIcons.chevronLeft, onPress: onBack),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '艺术家',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _SectionPill(
              label: '专辑',
              value: 'albums',
              selected: section,
              onSection: onSection,
            ),
            const SizedBox(width: 10),
            _SectionPill(
              label: '歌曲',
              value: 'tracks',
              selected: section,
              onSection: onSection,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionPill extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSection;

  const _SectionPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSection,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;

    return Expanded(
      child: FTappable(
        onPress: () => onSection(value),
        builder: (context, states, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? ListenerColors.foreground
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(999),
              boxShadow: ListenerShadows.soft,
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
      ),
    );
  }
}

class _ArtistTracksSummary extends StatelessWidget {
  final String section;
  final String artistName;
  final int count;
  final bool loading;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const _ArtistTracksSummary({
    required this.section,
    required this.artistName,
    required this.count,
    required this.onPlay,
    required this.onShuffle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = section == 'tracks' ? '歌曲' : '专辑';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
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
            loading ? '正在整理' : '$count 个$label',
            style: const TextStyle(
              color: ListenerColors.foreground,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            section == 'tracks'
                ? '$artistName 的歌曲会集中在这里，适合直接播放全部。'
                : '$artistName 的专辑会集中在这里，方便按作品继续探索。',
            style: const TextStyle(
              color: ListenerColors.softText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (section == 'tracks') ...[
            const SizedBox(height: 16),
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
                        Text('播放全部'),
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
                        Text('打乱'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AlbumGrid extends ConsumerWidget {
  final List<Album> albums;

  const _AlbumGrid({required this.albums});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (albums.isEmpty) return const _EmptyBlock(label: '暂无专辑');

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
        return ListenerAlbumCard(
          album: album,
          imageUrl: album.coverArt == null
              ? null
              : ref
                  .read(musicRepositoryProvider)
                  .getCoverArtUrl(album.coverArt!),
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

class _TrackList extends ConsumerWidget {
  final List<Song> songs;

  const _TrackList({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) return const _EmptyBlock(label: '暂无歌曲');

    return Column(
      children: [
        for (final (index, song) in songs.indexed)
          Builder(
            builder: (context) {
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
          ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final String label;

  const _LoadingBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FCircularProgress(),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: ListenerColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _ReloadBlock extends StatelessWidget {
  final String label;
  final VoidCallback onPress;

  const _ReloadBlock({
    required this.label,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: FButton(
          variant: FButtonVariant.ghost,
          onPress: onPress,
          child: Text(label),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String label;

  const _EmptyBlock({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: ListenerColors.muted),
        ),
      ),
    );
  }
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
