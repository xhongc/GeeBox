import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

class PlaylistManagementScreen extends ConsumerStatefulWidget {
  const PlaylistManagementScreen({super.key});

  @override
  ConsumerState<PlaylistManagementScreen> createState() =>
      _PlaylistManagementScreenState();
}

class _PlaylistManagementScreenState
    extends ConsumerState<PlaylistManagementScreen> {
  String _sortValue = 'recently-added';

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsProvider);

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
                    playlistsAsync.when(
                      data: (playlists) => _PlaylistsHero(
                        count: playlists.length,
                        sortValue: _sortValue,
                        firstPlaylist: _sortedPlaylists(playlists).firstOrNull,
                        onSort: (value) => setState(() => _sortValue = value),
                        onBack: () => Navigator.of(context).pop(),
                        onCreate: () => _showPlaylistDialog(context, ref),
                        onOpenFirst: (playlist) => context.push(
                          '/playlist-detail',
                          extra: {'playlistId': playlist.id},
                        ),
                        onPlayFirst: (playlist) =>
                            _playPlaylist(context, ref, playlist),
                      ),
                      loading: () => _PlaylistsHero(
                        count: 0,
                        sortValue: _sortValue,
                        firstPlaylist: null,
                        onSort: (value) => setState(() => _sortValue = value),
                        onBack: () => Navigator.of(context).pop(),
                        onCreate: () => _showPlaylistDialog(context, ref),
                        onOpenFirst: (_) {},
                        onPlayFirst: (_) {},
                      ),
                      error: (_, __) => _PlaylistsHero(
                        count: 0,
                        sortValue: _sortValue,
                        firstPlaylist: null,
                        onSort: (value) => setState(() => _sortValue = value),
                        onBack: () => Navigator.of(context).pop(),
                        onCreate: () => _showPlaylistDialog(context, ref),
                        onOpenFirst: (_) {},
                        onPlayFirst: (_) {},
                      ),
                    ),
                    const SizedBox(height: 18),
                    playlistsAsync.when(
                      data: (playlists) {
                        final sorted = _sortedPlaylists(playlists);
                        if (sorted.isEmpty) {
                          return _PlaylistsEmpty(
                            onCreate: () => _showPlaylistDialog(context, ref),
                          );
                        }
                        return Column(
                          children: [
                            for (final playlist in sorted)
                              _PlaylistRow(
                                playlist: playlist,
                                onOpen: () => context.push(
                                  '/playlist-detail',
                                  extra: {'playlistId': playlist.id},
                                ),
                                onPlay: () =>
                                    _playPlaylist(context, ref, playlist),
                                onMore: () => _showPlaylistOptions(
                                    context, ref, playlist),
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
                            onPress: () => ref.invalidate(playlistsProvider),
                            child: const Text('重新加载播放列表'),
                          ),
                        ),
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

  List<Playlist> _sortedPlaylists(List<Playlist> playlists) {
    final sorted = List<Playlist>.from(playlists);
    switch (_sortValue) {
      case 'a-z':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  void _showPlaylistOptions(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FTile(
                  prefix: const Icon(FLucideIcons.penLine),
                  title: const Text('编辑'),
                  onPress: () {
                    Navigator.pop(context);
                    _showPlaylistDialog(context, ref, playlist: playlist);
                  },
                ),
                FTile(
                  variant: FItemVariant.destructive,
                  prefix: const Icon(FLucideIcons.trash2),
                  title: const Text('删除'),
                  onPress: () async {
                    Navigator.pop(context);
                    await ref
                        .read(playlistServiceProvider)
                        .deletePlaylist(playlist.id);
                    refreshPlaylists(ref);
                    if (!context.mounted) return;
                    showChansonToast(context, '已删除播放列表: ${playlist.name}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaylistDialog(
    BuildContext context,
    WidgetRef ref, {
    Playlist? playlist,
  }) {
    final nameController = TextEditingController(text: playlist?.name ?? '');
    final descriptionController =
        TextEditingController(text: playlist?.description ?? '');
    final isEdit = playlist != null;

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
              Text(isEdit ? '编辑播放列表' : '创建播放列表', style: style.titleTextStyle),
              const SizedBox(height: 18),
              FTextField(
                control: FTextFieldControl.managed(controller: nameController),
                label: const Text('名称'),
                hint: '输入播放列表名称',
                autofocus: true,
              ),
              const SizedBox(height: 14),
              FTextField(
                control: FTextFieldControl.managed(
                  controller: descriptionController,
                ),
                label: const Text('描述（可选）'),
                hint: '输入播放列表描述',
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
                      if (name.isEmpty) {
                        showChansonToast(
                          context,
                          '请输入播放列表名称',
                          destructive: true,
                        );
                        return;
                      }
                      final service = ref.read(playlistServiceProvider);
                      if (isEdit) {
                        await service.updatePlaylist(
                          playlist.copyWith(
                            name: name,
                            description:
                                descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                          ),
                        );
                      } else {
                        await service.createPlaylist(
                          name: name,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                      }
                      refreshPlaylists(ref);
                      if (!context.mounted) return;
                      showChansonToast(context, isEdit ? '已更新播放列表' : '已创建播放列表');
                      Navigator.pop(context);
                    },
                    child: Text(isEdit ? '保存' : '创建'),
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

class _PlaylistsHero extends StatelessWidget {
  final int count;
  final String sortValue;
  final Playlist? firstPlaylist;
  final ValueChanged<String> onSort;
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final ValueChanged<Playlist> onOpenFirst;
  final ValueChanged<Playlist> onPlayFirst;

  const _PlaylistsHero({
    required this.count,
    required this.sortValue,
    required this.firstPlaylist,
    required this.onSort,
    required this.onBack,
    required this.onCreate,
    required this.onOpenFirst,
    required this.onPlayFirst,
  });

  @override
  Widget build(BuildContext context) {
    final title = sortValue == 'a-z' ? 'A-Z排序' : '最近添加';
    final summaryTitle = sortValue == 'a-z' ? '按名称浏览你整理好的歌单' : '最近整理过的歌单都在这里';
    final summaryText = sortValue == 'a-z'
        ? '适合按名字快速找回某一份收藏，不用一路往下翻。'
        : '从刚导入、刚创建到最近更新的清单，都可以在这里继续播放。';

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
                    '播放列表',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 14,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _PlaylistTab(
              label: '最近添加',
              value: 'recently-added',
              selected: sortValue,
              onSort: onSort,
            ),
            const SizedBox(width: 10),
            _PlaylistTab(
              label: 'A-Z排序',
              value: 'a-z',
              selected: sortValue,
              onSort: onSort,
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
                '歌单入口',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                summaryTitle,
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                summaryText,
                style: const TextStyle(
                  color: ListenerColors.softText,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              if (firstPlaylist == null)
                FButton(
                  onPress: onCreate,
                  prefix: const Icon(FLucideIcons.plus),
                  child: const Text('创建播放列表'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        onPress: () => onOpenFirst(firstPlaylist!),
                        prefix: const Icon(FLucideIcons.panelTopOpen),
                        child: const Text('打开第一份'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: () => onPlayFirst(firstPlaylist!),
                        prefix: const Icon(FLucideIcons.play),
                        child: const Text('直接播放'),
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

class _PlaylistTab extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSort;

  const _PlaylistTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
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
            style: TextStyle(
              color: active ? Colors.white : ListenerColors.softText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onOpen;
  final VoidCallback onPlay;
  final VoidCallback onMore;

  const _PlaylistRow({
    required this.playlist,
    required this.onOpen,
    required this.onPlay,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(23),
        boxShadow: ListenerShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: FTappable(
              onPress: onOpen,
              builder: (context, states, child) => Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 58,
                      child: ListenerCoverArt(
                        imageUrl: playlist.coverUrl,
                        fallbackIcon: FLucideIcons.listMusic,
                        borderRadius: 18,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
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
                            '${playlist.songIds.length} 首歌曲',
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
              ),
            ),
          ),
          FButton.icon(
            variant: FButtonVariant.ghost,
            onPress: onPlay,
            child: const Icon(FLucideIcons.play),
          ),
          FButton.icon(
            variant: FButtonVariant.ghost,
            onPress: onMore,
            child: const Icon(FLucideIcons.ellipsisVertical),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

Future<void> _playPlaylist(
  BuildContext context,
  WidgetRef ref,
  Playlist playlist,
) async {
  try {
    final songs = await ref.read(playlistSongsProvider(playlist.id).future);
    if (!context.mounted) return;
    if (songs.isEmpty) {
      showChansonToast(context, '这个播放列表暂无歌曲');
      return;
    }
    await _playSongs(ref, songs);
  } catch (error) {
    if (!context.mounted) return;
    showChansonToast(context, '播放列表失败: $error', destructive: true);
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

class _PlaylistsEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _PlaylistsEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              FLucideIcons.listMusic,
              color: ListenerColors.muted,
              size: 54,
            ),
            const SizedBox(height: 14),
            const Text(
              '还没有播放列表',
              style: TextStyle(color: ListenerColors.muted),
            ),
            const SizedBox(height: 18),
            FButton(
              onPress: onCreate,
              prefix: const Icon(FLucideIcons.plus),
              child: const Text('创建播放列表'),
            ),
          ],
        ),
      ),
    );
  }
}
