import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../providers/search_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../services/search_service.dart';
import '../widgets/add_to_playlist_dialog.dart';
import '../widgets/error_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        ref.read(searchResultProvider.notifier).state = null;
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      final searchService = ref.read(searchServiceProvider);
      final result = await searchService.search(query);
      if (mounted) {
        ref.read(searchResultProvider.notifier).state = result;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      ref.read(searchResultProvider.notifier).state = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResult = ref.watch(searchResultProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索歌曲、专辑、艺术家...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          onSubmitted: _performSearch,
          onChanged: (value) {
            setState(() {});
          },
        ),
        actions: [
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(searchResult, theme),
    );
  }

  Widget _buildBody(SearchResult? searchResult, ThemeData theme) {
    if (searchResult == null) {
      return _buildSearchHistory();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResult.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '没有找到相关结果',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return _buildSearchResults(searchResult, theme);
  }

  Widget _buildSearchHistory() {
    final searchService = ref.watch(searchServiceProvider);
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无搜索历史',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '搜索历史',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await searchService.clearSearchHistory();
                      ref.invalidate(searchHistoryProvider);
                    },
                    child: const Text('清空'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(item.query),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () async {
                        await searchService.deleteSearchHistory(item.query);
                        ref.invalidate(searchHistoryProvider);
                      },
                    ),
                    onTap: () {
                      _searchController.text = item.query;
                      _performSearch(item.query);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => error.toErrorWidget(
        onRetry: () => ref.invalidate(searchHistoryProvider),
      ),
    );
  }

  Widget _buildSearchResults(SearchResult searchResult, ThemeData theme) {
    return ListView(
      children: [
        if (searchResult.songs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '歌曲 (${searchResult.songs.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...searchResult.songs.map((song) => _buildSongItem(song, theme)),
        ],
        if (searchResult.albums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '专辑 (${searchResult.albums.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...searchResult.albums.map((album) => _buildAlbumItem(album, theme)),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSongItem(Song song, ThemeData theme) {
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
            onPressed: () => _showSongOptions(song),
          ),
        ],
      ),
      onTap: () {
        final audioService = ref.read(audioPlayerServiceProvider);
        final subsonicService = ref.read(subsonicServiceProvider);
        final streamUrl = subsonicService.getStreamUrl(song.id);
        audioService.playSong(song, streamUrl);
        Navigator.pop(context);
      },
    );
  }

  void _showSongOptions(Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到播放列表'),
              onTap: () {
                Navigator.pop(context);
                showAddToPlaylistDialog(context, ref, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumItem(Album album, ThemeData theme) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.album, color: Colors.grey),
      ),
      title: Text(
        album.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album.artist ?? '未知艺术家',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${album.songCount ?? 0} 首',
        style: TextStyle(color: Colors.grey[600]),
      ),
      onTap: () {
        context.push('/album-detail', extra: {
          'albumId': album.id,
          'albumName': album.name,
          'albumArtist': album.artist,
          'coverArtId': album.coverArt,
        });
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
