import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../models/song.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '添加到播放列表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('创建新播放列表'),
            onTap: () {
              Navigator.pop(context);
              _showCreatePlaylistDialog(context, ref, song);
            },
          ),
          const Divider(height: 1),
          playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '还没有播放列表',
                    style: TextStyle(color: Colors.grey),
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

                    return ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.songIds.length} 首歌曲'),
                      trailing: isInPlaylist
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: isInPlaylist
                          ? null
                          : () async {
                              final service = ref.read(playlistServiceProvider);
                              await service.addSongToPlaylist(playlist.id, song.id);
                              refreshPlaylists(ref);
                              refreshPlaylist(ref, playlist.id);

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已添加到: ${playlist.name}'),
                                  ),
                                );
                              }
                            },
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Text('加载失败: $error'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref, Song song) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建播放列表'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '输入播放列表名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '输入播放列表描述',
              ),
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
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入播放列表名称')),
                );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('创建播放列表失败')),
                  );
                }
                return;
              }

              // 添加歌曲到新创建的播放列表
              await service.addSongToPlaylist(playlist.id, song.id);

              refreshPlaylists(ref);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已创建播放列表并添加歌曲: $name')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
