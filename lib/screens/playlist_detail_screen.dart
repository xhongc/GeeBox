import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

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

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: SafeArea(
          bottom: false,
          child: playlistAsync.when(
            data: (playlist) {
              if (playlist == null) {
                return const Center(
                  child: Text(
                    '播放列表不存在',
                    style: TextStyle(color: ListenerColors.muted),
                  ),
                );
              }

              return songsAsync.when(
                data: (songs) => _PlaylistDetailBody(
                  playlist: playlist,
                  songs: songs,
                  onBack: () => Navigator.of(context).pop(),
                  onEdit: () => _showEditDialog(context, ref, playlist),
                  onDelete: () => _showDeleteDialog(context, ref, playlist),
                ),
                loading: () => const Center(child: FCircularProgress()),
                error: (_, __) => Center(
                  child: FButton(
                    variant: FButtonVariant.ghost,
                    onPress: () =>
                        ref.invalidate(playlistSongsProvider(playlistId)),
                    child: const Text('重新加载歌曲'),
                  ),
                ),
              );
            },
            loading: () => const Center(child: FCircularProgress()),
            error: (_, __) => Center(
              child: FButton(
                variant: FButtonVariant.ghost,
                onPress: () => ref.invalidate(playlistProvider(playlistId)),
                child: const Text('重新加载播放列表'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Playlist playlist) {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description ?? '');

    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('编辑播放列表', style: style.titleTextStyle),
              const SizedBox(height: 18),
              FTextField(
                control: FTextFieldControl.managed(controller: nameController),
                label: const Text('名称'),
              ),
              const SizedBox(height: 14),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: descriptionController,
                ),
                label: const Text('描述（可选）'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final service = ref.read(playlistServiceProvider);
                      await service.updatePlaylist(
                        playlist.copyWith(
                          name: name,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        ),
                      );
                      refreshPlaylist(ref, playlistId);
                      refreshPlaylists(ref);
                      if (!context.mounted) return;
                      showChansonToast(context, '已更新播放列表');
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Playlist playlist) {
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('删除播放列表', style: style.titleTextStyle),
              const SizedBox(height: 8),
              Text('确定要删除播放列表"${playlist.name}"吗？', style: style.bodyTextStyle),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () async {
                      await ref
                          .read(playlistServiceProvider)
                          .deletePlaylist(playlistId);
                      refreshPlaylists(ref);
                      if (!context.mounted) return;
                      showChansonToast(context, '已删除: ${playlist.name}');
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('删除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistDetailBody extends ConsumerWidget {
  final Playlist playlist;
  final List<Song> songs;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaylistDetailBody({
    required this.playlist,
    required this.songs,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = songs.fold<int>(0, (sum, song) => sum + (song.duration ?? 0));

    return Stack(
      children: [
        Positioned(
          top: -56,
          left: -32,
          right: -32,
          height: 260,
          child: Opacity(
            opacity: 0.14,
            child: ListenerCoverArt(
              imageUrl: playlist.coverUrl,
              fallbackIcon: FLucideIcons.listMusic,
              borderRadius: 0,
            ),
          ),
        ),
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _PlaylistTopBar(
                      playlist: playlist,
                      onBack: onBack,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                    const SizedBox(height: 22),
                    _PlaylistHero(
                      playlist: playlist,
                      trackCount: songs.length,
                      totalDuration: total,
                    ),
                    const SizedBox(height: 20),
                    _PlaylistActions(
                      hasSongs: songs.isNotEmpty,
                      onPlay: () => _playSongs(ref, songs),
                      onShuffle: () => _shuffleSongs(ref, songs),
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
                            '播放列表为空',
                            style: TextStyle(color: ListenerColors.muted),
                          ),
                        ),
                      )
                    else
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
                              onFavorite: () => _removeSong(context, ref, song),
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
                    const SizedBox(height: 28),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _removeSong(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) async {
    await ref
        .read(playlistServiceProvider)
        .removeSongFromPlaylist(playlist.id, song.id);
    refreshPlaylist(ref, playlist.id);
    if (!context.mounted) return;
    showChansonToast(context, '已移除: ${song.title}');
  }
}

class _PlaylistTopBar extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaylistTopBar({
    required this.playlist,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ListenerCircleButton(icon: FLucideIcons.chevronLeft, onPress: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              const Text(
                '播放列表详情',
                style: TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                playlist.description?.isNotEmpty == true
                    ? playlist.description!
                    : '我的歌单',
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
        ListenerCircleButton(icon: FLucideIcons.penLine, onPress: onEdit),
        const SizedBox(width: 8),
        ListenerCircleButton(icon: FLucideIcons.trash2, onPress: onDelete),
      ],
    );
  }
}

class _PlaylistHero extends StatelessWidget {
  final Playlist playlist;
  final int trackCount;
  final int totalDuration;

  const _PlaylistHero({
    required this.playlist,
    required this.trackCount,
    required this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: 34,
                child: Container(
                  width: 178,
                  height: 178,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ListenerColors.foreground,
                    boxShadow: ListenerShadows.elevated,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF7F6F3),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                child: Container(
                  width: 188,
                  height: 188,
                  decoration:
                      BoxDecoration(boxShadow: ListenerShadows.elevated),
                  child: ListenerCoverArt(
                    imageUrl: playlist.coverUrl,
                    fallbackIcon: FLucideIcons.listMusic,
                    borderRadius: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Playlist',
          style: TextStyle(
            color: ListenerColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          playlist.name,
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
        if (playlist.description?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(
            playlist.description!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ListenerColors.softText,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          '$trackCount 首歌曲 · ${formatSongDuration(totalDuration)}',
          style: const TextStyle(
            color: ListenerColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PlaylistActions extends StatelessWidget {
  final bool hasSongs;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onNext;
  final VoidCallback onQueue;

  const _PlaylistActions({
    required this.hasSongs,
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
            onPress: hasSongs ? onPlay : null,
            prefix: const Icon(FLucideIcons.play),
            child: const Text('播放'),
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
          variant: FButtonVariant.secondary,
          onPress: hasSongs ? onNext : null,
          prefix: const Icon(FLucideIcons.listEnd),
          child: const Text('下一首'),
        ),
        const SizedBox(width: 10),
        FButton(
          variant: FButtonVariant.secondary,
          onPress: hasSongs ? onQueue : null,
          prefix: const Icon(FLucideIcons.listPlus),
          child: const Text('队列'),
        ),
      ],
    );
  }
}

String? _coverUrl(WidgetRef ref, Song song) {
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

void _addSongsNext(WidgetRef ref, List<Song> songs) {
  final player = ref.read(audioPlayerServiceProvider);
  for (final song in songs.reversed) {
    player.addNext(song);
  }
}
