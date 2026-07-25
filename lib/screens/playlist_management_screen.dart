import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/playlist_provider.dart';
import '../models/playlist.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

class PlaylistManagementScreen extends ConsumerWidget {
  const PlaylistManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return ChansonScaffold(
      title: '播放列表',
      suffixes: [
        FHeaderAction(
          icon: const Icon(FLucideIcons.plus),
          onPress: () => _showCreatePlaylistDialog(context, ref),
        ),
      ],
      child: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildPlaylistGrid(context, ref, playlists);
        },
        loading: () => const Center(child: FCircularProgress()),
        error: (error, stack) => error.toErrorWidget(
          onRetry: () => ref.invalidate(playlistsProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        const SizedBox(height: 120),
        const ChansonEmptyState(
          icon: FLucideIcons.listMusic,
          message: '还没有播放列表',
        ),
        const SizedBox(height: 20),
        Center(
          child: FButton(
            onPress: () => _showCreatePlaylistDialog(context, ref),
            prefix: const Icon(FLucideIcons.plus),
            child: const Text('创建播放列表'),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistGrid(
    BuildContext context,
    WidgetRef ref,
    List<Playlist> playlists,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _buildPlaylistCard(context, ref, playlist);
      },
    );
  }

  Widget _buildPlaylistCard(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final theme = context.theme;

    return FTappable(
      onPress: () {
        context.push('/playlist-detail', extra: {
          'playlistId': playlist.id,
        });
      },
      onLongPress: () => _showPlaylistOptions(context, ref, playlist),
      builder: (context, variants, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colors.border),
                ),
                child: Center(
                  child: Icon(
                    FLucideIcons.listMusic,
                    size: 54,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    playlist.name,
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FButton.icon(
                  variant: FButtonVariant.ghost,
                  size: FButtonSizeVariant.sm,
                  onPress: () => _showPlaylistOptions(context, ref, playlist),
                  child: const Icon(FLucideIcons.ellipsisVertical),
                ),
              ],
            ),
            Text(
              '${playlist.songIds.length} 首歌曲',
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, style) => _PlaylistFormDialog(
          title: '创建播放列表',
          nameController: nameController,
          descriptionController: descriptionController,
          submitLabel: '创建',
          onSubmit: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入播放列表名称')),
              );
              return;
            }

            final service = ref.read(playlistServiceProvider);
            await service.createPlaylist(
              name: name,
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
            );

            refreshPlaylists(ref);

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已创建播放列表: $name')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showPlaylistOptions(
      BuildContext context, WidgetRef ref, Playlist playlist) {
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
                    _showEditPlaylistDialog(context, ref, playlist);
                  },
                ),
                FTile(
                  variant: FItemVariant.destructive,
                  prefix: const Icon(FLucideIcons.trash2),
                  title: const Text('删除'),
                  onPress: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(context, ref, playlist);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPlaylistDialog(
      BuildContext context, WidgetRef ref, Playlist playlist) {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController =
        TextEditingController(text: playlist.description ?? '');

    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, style) => _PlaylistFormDialog(
          title: '编辑播放列表',
          nameController: nameController,
          descriptionController: descriptionController,
          submitLabel: '保存',
          onSubmit: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入播放列表名称')),
              );
              return;
            }

            final service = ref.read(playlistServiceProvider);
            final updatedPlaylist = playlist.copyWith(
              name: name,
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
            );
            await service.updatePlaylist(updatedPlaylist);

            refreshPlaylists(ref);

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已更新播放列表')),
              );
            }
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
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
                      final service = ref.read(playlistServiceProvider);
                      await service.deletePlaylist(playlist.id);

                      refreshPlaylists(ref);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已删除播放列表: ${playlist.name}')),
                        );
                      }
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

class _PlaylistFormDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String submitLabel;
  final Future<void> Function() onSubmit;

  const _PlaylistFormDialog({
    required this.title,
    required this.nameController,
    required this.descriptionController,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.theme.dialogStyle;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: style.titleTextStyle),
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
                onPress: onSubmit,
                child: Text(submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
