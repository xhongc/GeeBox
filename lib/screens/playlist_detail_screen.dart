import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../models/song.dart';

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

    return Scaffold(
      body: playlistAsync.when(
        data: (playlist) {
          if (playlist == null) {
            return const Center(child: Text('播放列表不存在'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, ref, playlist),
              songsAsync.when(
                data: (songs) => _buildSongList(context, ref, songs),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(child: Text('加载失败: $error')),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, playlist) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlist.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.queue_music,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showPlaylistOptions(context, ref, playlist),
        ),
      ],
    );
  }

  Widget _buildSongList(BuildContext context, WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '播放列表为空',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return _buildPlayAllButton(context, ref, songs);
            }
            final song = songs[index - 1];
            return _buildSongItem(context, ref, song, index - 1);
          },
          childCount: songs.length + 1,
        ),
      ),
    );
  }

  Widget _buildPlayAllButton(BuildContext context, WidgetRef ref, List<Song> songs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _playAll(context, ref, songs),
              icon: const Icon(Icons.play_arrow),
              label: Text('播放全部 (${songs.length})'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _shufflePlay(context, ref, songs),
            icon: const Icon(Icons.shuffle),
            label: const Text('随机播放'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(BuildContext context, WidgetRef ref, Song song, int index) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note, color: Colors.grey),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? '未知艺术家',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(song.duration ?? 0),
            style: TextStyle(color: Colors.grey[600]),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showSongOptions(context, ref, song),
          ),
        ],
      ),
      onTap: () => _playSong(context, ref, song),
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
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑信息'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除播放列表', style: TextStyle(color: Colors.red)),
              onTap: () {
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
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('播放'),
              onTap: () {
                Navigator.pop(context);
                _playSong(context, ref, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('从播放列表移除', style: TextStyle(color: Colors.red)),
              onTap: () async {
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
    final descriptionController = TextEditingController(text: playlist.description ?? '');

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
