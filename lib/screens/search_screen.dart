import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../providers/music_repository_provider.dart';
import '../providers/search_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../services/search_service.dart';
import '../widgets/add_to_playlist_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

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

    return ChansonScaffold(
      title: '搜索',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: _searchController,
                onChange: (_) => setState(() {}),
              ),
              autofocus: true,
              hint: '搜索歌曲、专辑、艺术家...',
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(
                context,
                style,
                variants,
                const Icon(FLucideIcons.search),
              ),
              suffixBuilder: _searchController.text.isEmpty
                  ? null
                  : (context, style, variants) => FButton.icon(
                        variant: FButtonVariant.ghost,
                        size: FButtonSizeVariant.sm,
                        onPress: _clearSearch,
                        child: const Icon(FLucideIcons.x),
                      ),
              onSubmit: _performSearch,
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          Expanded(child: _buildBody(searchResult)),
        ],
      ),
    );
  }

  Widget _buildBody(SearchResult? searchResult) {
    if (searchResult == null) {
      return _buildSearchHistory();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchResult.isEmpty) {
      return const ChansonEmptyState(
        icon: FLucideIcons.searchX,
        message: '没有找到相关结果',
      );
    }

    return _buildSearchResults(searchResult);
  }

  Widget _buildSearchHistory() {
    final searchService = ref.watch(searchServiceProvider);
    final historyAsync = ref.watch(searchHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const ChansonEmptyState(
            icon: FLucideIcons.history,
            message: '暂无搜索历史',
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
                  Text(
                    '搜索历史',
                    style: context.theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    onPress: () async {
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
                  return FTile(
                    prefix: const Icon(FLucideIcons.history),
                    title: Text(item.query),
                    suffix: FButton.icon(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      onPress: () async {
                        await searchService.deleteSearchHistory(item.query);
                        ref.invalidate(searchHistoryProvider);
                      },
                      child: const Icon(FLucideIcons.x),
                    ),
                    onPress: () {
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

  Widget _buildSearchResults(SearchResult searchResult) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (searchResult.songs.isNotEmpty) ...[
          ChansonSection(
            title: '歌曲 (${searchResult.songs.length})',
            children: [
              ...searchResult.songs.map(_buildSongItem),
            ],
          ),
        ],
        if (searchResult.albums.isNotEmpty) ...[
          ChansonSection(
            title: '专辑 (${searchResult.albums.length})',
            children: [
              ...searchResult.albums.map(_buildAlbumItem),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSongItem(Song song) {
    final repository = ref.read(musicRepositoryProvider);

    return ChansonSongTile(
      coverUrl: song.coverArt == null
          ? null
          : repository.getCoverArtUrl(song.coverArt!),
      title: song.title,
      subtitle: song.artist ?? '未知艺术家',
      duration: _formatDuration(song.duration ?? 0),
      onMore: () => _showSongOptions(song),
      onPress: () {
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: FCard(
            child: FTile(
              prefix: const Icon(FLucideIcons.listPlus),
              title: const Text('添加到播放列表'),
              onPress: () {
                Navigator.pop(context);
                showAddToPlaylistDialog(context, ref, song);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumItem(Album album) {
    final repository = ref.read(musicRepositoryProvider);

    return FTile(
      prefix: SizedBox.square(
        dimension: 46,
        child: ChansonCoverArt(
          imageUrl: album.coverArt == null
              ? null
              : repository.getCoverArtUrl(album.coverArt!),
          fallbackIcon: FLucideIcons.disc3,
        ),
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
      details: Text('${album.songCount ?? 0} 首'),
      suffix: const Icon(FLucideIcons.chevronRight),
      onPress: () {
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
