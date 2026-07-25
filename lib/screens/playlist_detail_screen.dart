import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../models/song.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistProvider(playlistId));
    final songsAsync = ref.watch(playlistSongsProvider(playlistId));

    return playlistAsync.when(
      data: (playlist) {
        if (playlist == null) {
          return const ChansonScaffold(
            title: '播放列表',
            child: ChansonEmptyState(
              icon: FLucideIcons.listX,
              message: '播放列表不存在',
            ),
          );
        }

        return ChansonScaffold(
          title: playlist.name,
          suffixes: [
            FHeaderAction(
              icon: const Icon(FLucideIcons.ellipsisVertical),
              onPress: () => _showPlaylistOptions(context, ref, playlist),
            ),
          ],
          child: songsAsync.when(
            data: (songs) => _buildSongList(context, ref, playlist, songs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => error.toErrorWidget(
              onRetry: () => ref.invalidate(playlistSongsProvider(playlistId)),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => error.toErrorWidget(
        onRetry: () => ref.invalidate(playlistProvider(playlistId)),
      ),
    );
  }

  Widget _buildSongList(
    BuildContext context,
    WidgetRef ref,
    playlist,
    List<Song> songs,
  ) {
    final theme = context.theme;

    if (songs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _PlaylistHero(playlist: playlist),
          const SizedBox(height: 48),
          const SizedBox(
            height: 220,
            child: ChansonEmptyState(
              icon: FLucideIcons.music,
              message: '播放列表为空',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      children: [
        _PlaylistHero(playlist: playlist),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FButton(
                onPress: () => _playAll(context, ref, songs),
                prefix: const Icon(FLucideIcons.play),
                child: Text('播放全部 (${songs.length})'),
              ),
            ),
            const SizedBox(width: 8),
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => _shufflePlay(context, ref, songs),
              prefix: const Icon(FLucideIcons.shuffle),
              child: const Text('随机播放'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ChansonSection(
          title: '歌曲',
          children: [
            for (final (index, song) in songs.indexed)
              _buildSongItem(context, ref, song, index),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '共 ${songs.length} 首歌曲',
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildSongItem(
      BuildContext context, WidgetRef ref, Song song, int index) {
    final repository = ref.read(musicRepositoryProvider);

    return ChansonSongTile(
      coverUrl: song.coverArt == null
          ? null
          : repository.getCoverArtUrl(song.coverArt!),
      title: song.title,
      subtitle: song.artist ?? '未知艺术家',
      duration: _formatDuration(song.duration ?? 0),
      onMore: () => _showSongOptions(context, ref, song),
      onPress: () => _playSong(context, ref, song),
    );
  }

  void _playAll(BuildContext context, WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return;

    final audioService = ref.read(audioPlayerServiceProvider);
    final subsonicService = ref.read(subsonicServiceProvider);

    audioService.setPlaylist(songs, initialIndex: 0);
    final streamUrl = subsonicService.getStreamUrl(songs[0].id);
    audioService.playSong(songs[0], streamUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('开始播放 ${songs.length} 首歌曲')),
    );
  }

  void _shufflePlay(BuildContext context, WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return;

    final shuffledSongs = List<Song>.from(songs)..shuffle();
    final audioService = ref.read(audioPlayerServiceProvider);
    final subsonicService = ref.read(subsonicServiceProvider);

    audioService.setPlaylist(shuffledSongs, initialIndex: 0);
    final streamUrl = subsonicService.getStreamUrl(shuffledSongs[0].id);
    audioService.playSong(shuffledSongs[0], streamUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('随机播放模式')),
    );
  }

  void _playSong(BuildContext context, WidgetRef ref, Song song) {
    final audioService = ref.read(audioPlayerServiceProvider);
    final subsonicService = ref.read(subsonicServiceProvider);
    final streamUrl = subsonicService.getStreamUrl(song.id);

    audioService.playSong(song, streamUrl);
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref, playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FTile(
              prefix: const Icon(FLucideIcons.penLine),
              title: const Text('编辑信息'),
              onPress: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, playlist);
              },
            ),
            FTile(
              variant: FItemVariant.destructive,
              prefix: const Icon(FLucideIcons.trash2),
              title: const Text('删除播放列表'),
              onPress: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref, playlist);
              },
            ),
          ],
        ),
      ),
    );
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
              onPress: () {
                Navigator.pop(context);
                _playSong(context, ref, song);
              },
            ),
            FTile(
              variant: FItemVariant.destructive,
              prefix: const Icon(FLucideIcons.circleMinus),
              title: const Text('从播放列表移除'),
              onPress: () async {
                Navigator.pop(context);
                final service = ref.read(playlistServiceProvider);
                await service.removeSongFromPlaylist(playlistId, song.id);
                refreshPlaylist(ref, playlistId);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已移除: ${song.title}')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, playlist) {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑播放列表'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '描述（可选）'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final service = ref.read(playlistServiceProvider);
              final updatedPlaylist = playlist.copyWith(
                name: name,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );
              await service.updatePlaylist(updatedPlaylist);

              refreshPlaylist(ref, playlistId);
              refreshPlaylists(ref);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已更新播放列表')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除播放列表'),
        content: Text('确定要删除播放列表"${playlist.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final service = ref.read(playlistServiceProvider);
              await service.deletePlaylist(playlistId);

              refreshPlaylists(ref);

              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除: ${playlist.name}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _PlaylistHero extends StatelessWidget {
  final dynamic playlist;

  const _PlaylistHero({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 92,
              child: ChansonCoverArt(
                fallbackIcon: FLucideIcons.listMusic,
                borderRadius: 8,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: theme.typography.body.xl.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (playlist.description != null &&
                      playlist.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      playlist.description!,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${playlist.songIds.length} 首歌曲',
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
