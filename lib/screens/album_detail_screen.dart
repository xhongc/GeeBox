import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

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

    return ChansonScaffold(
      title: albumName,
      child: songsAsync.when(
        data: (songs) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _AlbumHero(
              title: albumName,
              artist: albumArtist,
              coverUrl: coverArtId == null
                  ? null
                  : repository.getCoverArtUrl(coverArtId!, size: 500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: songs.isEmpty
                        ? null
                        : () async {
                            final playerService =
                                ref.read(audioPlayerServiceProvider);
                            await playerService.setPlaylist(songs);
                            await playerService.playAtIndex(
                              0,
                              (songId) => repository.getStreamUrl(songId),
                            );
                          },
                    prefix: const Icon(FLucideIcons.play),
                    child: const Text('播放全部'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: songs.isEmpty
                        ? null
                        : () async {
                            final shuffledSongs = List<Song>.from(songs)
                              ..shuffle();
                            final playerService =
                                ref.read(audioPlayerServiceProvider);
                            await playerService.setPlaylist(shuffledSongs);
                            await playerService.playAtIndex(
                              0,
                              (songId) => repository.getStreamUrl(songId),
                            );
                          },
                    prefix: const Icon(FLucideIcons.shuffle),
                    child: const Text('随机播放'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (songs.isEmpty)
              const SizedBox(
                height: 220,
                child: ChansonEmptyState(
                  icon: FLucideIcons.music,
                  message: '暂无歌曲',
                ),
              )
            else
              ChansonSection(
                title: '歌曲',
                children: [
                  for (final (index, song) in songs.indexed)
                    _buildSongItem(context, ref, song, index, songs),
                ],
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => error.toErrorWidget(
          onRetry: () => ref.invalidate(albumDetailProvider(albumId)),
        ),
      ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    WidgetRef ref,
    Song song,
    int index,
    List<Song> allSongs,
  ) {
    final currentSong = ref.watch(currentSongProvider).value;
    final isPlaying = currentSong?.id == song.id;
    final theme = context.theme;

    return FTile(
      selected: isPlaying,
      prefix: SizedBox.square(
        dimension: 38,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isPlaying ? theme.colors.primary : theme.colors.muted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: isPlaying
                ? Icon(
                    FLucideIcons.volume2,
                    color: theme.colors.primaryForeground,
                    size: 18,
                  )
                : Text(
                    '${index + 1}',
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.mutedForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
      title: Text(song.title),
      subtitle: Text(song.artist ?? '未知艺术家'),
      details:
          song.duration == null ? null : Text(_formatDuration(song.duration!)),
      suffix: FButton.icon(
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        onPress: () => _showSongOptions(context, ref, song),
        child: const Icon(FLucideIcons.ellipsisVertical),
      ),
      onPress: () async {
        final playerService = ref.read(audioPlayerServiceProvider);
        await playerService.setPlaylist(allSongs, initialIndex: index);
        await playerService.playAtIndex(
          index,
          (songId) => ref.read(musicRepositoryProvider).getStreamUrl(songId),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FTile(
              prefix: const Icon(FLucideIcons.play),
              title: const Text('播放'),
              onPress: () async {
                Navigator.pop(context);
                final playerService = ref.read(audioPlayerServiceProvider);
                final repository = ref.read(musicRepositoryProvider);
                await playerService.playSong(
                  song,
                  repository.getStreamUrl(song.id),
                );
              },
            ),
            FTile(
              prefix: const Icon(FLucideIcons.listPlus),
              title: const Text('添加到播放列表'),
              onPress: () => Navigator.pop(context),
            ),
            FTile(
              prefix: const Icon(FLucideIcons.share2),
              title: const Text('分享'),
              onPress: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumHero extends StatelessWidget {
  final String title;
  final String? artist;
  final String? coverUrl;

  const _AlbumHero({
    required this.title,
    required this.artist,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: 132,
          child: ChansonCoverArt(
            imageUrl: coverUrl,
            fallbackIcon: FLucideIcons.disc3,
            borderRadius: 8,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.body.xl2.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (artist != null) ...[
                const SizedBox(height: 6),
                Text(
                  artist!,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
