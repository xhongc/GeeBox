import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/playlist_provider.dart';
import '../models/song.dart';
import 'forui_components.dart';

/// 显示添加到播放列表的对话框
void showAddToPlaylistDialog(BuildContext context, WidgetRef ref, Song song) {
  showModalBottomSheet(
    context: context,
    builder: (context) => AddToPlaylistSheet(song: song),
  );
}

class AddToPlaylistSheet extends ConsumerWidget {
  final Song song;

  const AddToPlaylistSheet({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: FCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Text(
                      '添加到播放列表',
                      style: context.theme.typography.body.lg.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    FButton.icon(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      onPress: () => Navigator.pop(context),
                      child: const Icon(FLucideIcons.x),
                    ),
                  ],
                ),
              ),
              FTile(
                prefix: const Icon(FLucideIcons.plus),
                title: const Text('创建新播放列表'),
                onPress: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context, ref, song);
                },
              ),
              playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return const SizedBox(
                      height: 180,
                      child: ChansonEmptyState(
                        icon: FLucideIcons.listMusic,
                        message: '还没有播放列表',
                      ),
                    );
                  }

                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final isInPlaylist = playlist.songIds.contains(song.id);

                        return FTile(
                          prefix: const Icon(FLucideIcons.listMusic),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.songIds.length} 首歌曲'),
                          suffix: isInPlaylist
                              ? Icon(
                                  FLucideIcons.check,
                                  color: context.theme.colors.primary,
                                )
                              : null,
                          onPress: isInPlaylist
                              ? null
                              : () async {
                                  final service =
                                      ref.read(playlistServiceProvider);
                                  await service.addSongToPlaylist(
                                      playlist.id, song.id);
                                  refreshPlaylists(ref);
                                  refreshPlaylist(ref, playlist.id);

                                  if (context.mounted) {
                                    showChansonToast(
                                        context, '已添加到: ${playlist.name}');
                                    Navigator.pop(context);
                                  }
                                },
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: FCircularProgress()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: ChansonAlert(
                    title: '加载失败',
                    message: '$error',
                    variant: FAlertVariant.destructive,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, WidgetRef ref, Song song) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

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
              Text('创建播放列表', style: style.titleTextStyle),
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
                        showChansonToast(context, '请输入播放列表名称',
                            destructive: true);
                        return;
                      }

                      final service = ref.read(playlistServiceProvider);
                      final playlist = await service.createPlaylist(
                        name: name,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );

                      if (playlist == null) {
                        if (context.mounted) {
                          showChansonToast(context, '创建播放列表失败',
                              destructive: true);
                        }
                        return;
                      }

                      await service.addSongToPlaylist(playlist.id, song.id);

                      refreshPlaylists(ref);

                      if (context.mounted) {
                        showChansonToast(context, '已创建播放列表并添加歌曲: $name');
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('创建'),
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
