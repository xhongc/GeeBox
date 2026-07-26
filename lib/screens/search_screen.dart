import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/search_provider.dart';
import '../providers/subsonic_provider.dart';
import '../services/search_service.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim();
    if (initialQuery == null || initialQuery.isEmpty) return;
    _searchController.text = initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(searchResultProvider) != null) return;
      _performSearch(initialQuery);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleInput(String value) {
    setState(() {});
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      ref.read(searchResultProvider.notifier).state = null;
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 260),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      ref.read(searchResultProvider.notifier).state = null;
      return;
    }

    setState(() => _isSearching = true);
    try {
      final searchService = ref.read(searchServiceProvider);
      final result = await searchService.search(trimmed);
      if (!mounted) return;
      ref.read(searchResultProvider.notifier).state = result;
      ref.invalidate(searchHistoryProvider);
    } catch (error) {
      if (!mounted) return;
      showChansonToast(context, '搜索失败: $error', destructive: true);
      ref.read(searchResultProvider.notifier).state = SearchResult(
        songs: [],
        albums: [],
        artists: [],
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(searchResultProvider.notifier).state = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(searchResultProvider);
    final hasKeyword = _searchController.text.trim().isNotEmpty;

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
                    _SearchHero(
                      controller: _searchController,
                      onBack: () => Navigator.of(context).pop(),
                      onChanged: _handleInput,
                      onSubmit: _performSearch,
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: 24),
                    if (_isSearching)
                      const _SearchState(
                        icon: FLucideIcons.loaderCircle,
                        title: '正在搜索...',
                        subtitle: '正在整理歌曲、专辑和艺术家结果。',
                      )
                    else if (!hasKeyword)
                      _SearchHistory(
                        onSelect: (query) {
                          _searchController.text = query;
                          _performSearch(query);
                        },
                      )
                    else if (result == null)
                      const _SearchState(
                        icon: FLucideIcons.search,
                        title: '开始一次搜索',
                        subtitle: '输入歌曲名、专辑名或艺术家，结果会立即出现。',
                      )
                    else if (result.isEmpty)
                      const _SearchState(
                        icon: FLucideIcons.searchX,
                        title: '没有找到结果',
                        subtitle: '换个关键词试试，比如歌手名或者专辑名。',
                      )
                    else
                      _SearchResults(result: result),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHero extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  const _SearchHero({
    required this.controller,
    required this.onBack,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenerCircleButton(
              icon: FLucideIcons.chevronLeft,
              onPress: onBack,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '搜索你想听的声音',
                    style: TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.18),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: FTextField(
            autofocus: true,
            hint: '搜索艺术家、专辑或歌曲...',
            control: FTextFieldControl.managed(
              controller: controller,
              onChange: (value) => onChanged(value.text),
            ),
            prefixBuilder: (context, style, variants) =>
                FTextField.prefixIconBuilder(
              context,
              style,
              variants,
              const Icon(FLucideIcons.search),
            ),
            suffixBuilder: controller.text.isEmpty
                ? null
                : (context, style, variants) => FButton.icon(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      onPress: onClear,
                      child: const Icon(FLucideIcons.x),
                    ),
            onSubmit: onSubmit,
          ),
        ),
      ],
    );
  }
}

class _SearchHistory extends ConsumerWidget {
  final ValueChanged<String> onSelect;

  const _SearchHistory({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(searchHistoryProvider);
    final searchService = ref.watch(searchServiceProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const _SearchState(
            icon: FLucideIcons.search,
            title: '开始一次搜索',
            subtitle: '输入歌曲名、专辑名或艺术家，结果会立即出现。',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenerSectionHeader(
              title: '搜索历史',
              actionLabel: '清空',
              onAction: () async {
                await searchService.clearSearchHistory();
                ref.invalidate(searchHistoryProvider);
              },
            ),
            for (final item in history)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: ListenerShadows.soft,
                ),
                child: FTile(
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
                  onPress: () => onSelect(item.query),
                ),
              ),
          ],
        );
      },
      loading: () => const _SearchState(
        icon: FLucideIcons.loaderCircle,
        title: '正在加载...',
        subtitle: '正在读取搜索历史。',
      ),
      error: (_, __) => _SearchState(
        icon: FLucideIcons.searchX,
        title: '历史加载失败',
        subtitle: '稍后再试，或直接输入关键词搜索。',
        action: FButton(
          variant: FButtonVariant.ghost,
          onPress: () => ref.invalidate(searchHistoryProvider),
          child: const Text('重试'),
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final SearchResult result;

  const _SearchResults({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.artists.isNotEmpty) ...[
          ListenerSectionHeader(
            title: '艺术家',
            actionLabel: '${result.artists.length}',
          ),
          for (final artist in result.artists) _ArtistResultRow(artist: artist),
          const SizedBox(height: 24),
        ],
        if (result.albums.isNotEmpty) ...[
          ListenerSectionHeader(
            title: '专辑',
            actionLabel: '${result.albums.length}',
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.albums.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final album = result.albums[index];
              return ListenerAlbumCard(
                album: album,
                imageUrl: _albumCoverUrl(ref, album),
                onPress: () => context.push('/album-detail', extra: {
                  'albumId': album.id,
                  'albumName': album.name,
                  'albumArtist': album.artist,
                  'coverArtId': album.coverArt,
                }),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (result.songs.isNotEmpty) ...[
          ListenerSectionHeader(
            title: '歌曲',
            actionLabel: '${result.songs.length}',
          ),
          for (final (index, song) in result.songs.indexed)
            Builder(
              builder: (context) {
                final imageUrl = _songCoverUrl(ref, song);
                return ListenerTrackRow(
                  song: song,
                  imageUrl: imageUrl,
                  onPress: () =>
                      _playSongs(ref, result.songs, initialIndex: index),
                  onFavorite: () => showChansonToast(context, '收藏功能将在喜爱页统一管理'),
                  onMore: () => showListenerTrackActionSheet(
                    context: context,
                    ref: ref,
                    song: song,
                    imageUrl: imageUrl,
                    queue: result.songs,
                    index: index,
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _ArtistResultRow extends ConsumerWidget {
  final Artist artist;

  const _ArtistResultRow({required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        boxShadow: ListenerShadows.soft,
      ),
      child: FTile(
        prefix: SizedBox.square(
          dimension: 58,
          child: ListenerCoverArt(
            imageUrl: artist.coverArt == null
                ? null
                : ref
                    .read(musicRepositoryProvider)
                    .getCoverArtUrl(artist.coverArt!, size: 180),
            fallbackIcon: FLucideIcons.userRound,
            borderRadius: 18,
          ),
        ),
        title: Text(artist.name),
        subtitle: Text('${artist.albumCount ?? 0} 张专辑'),
        suffix: const Icon(FLucideIcons.chevronRight),
        onPress: () => context.push('/artist-detail', extra: {
          'artistId': artist.id,
          'artistName': artist.name,
          'coverArtId': artist.coverArt,
        }),
      ),
    );
  }
}

class _SearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _SearchState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                shape: BoxShape.circle,
                boxShadow: ListenerShadows.soft,
              ),
              child: Icon(icon, color: ListenerColors.muted, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: ListenerColors.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 13,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

String? _songCoverUrl(WidgetRef ref, Song song) {
  if (song.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(song.coverArt!);
}

String? _albumCoverUrl(WidgetRef ref, Album album) {
  if (album.coverArt == null) return null;
  return ref.read(musicRepositoryProvider).getCoverArtUrl(album.coverArt!);
}

Future<void> _playSongs(
  WidgetRef ref,
  List<Song> songs, {
  required int initialIndex,
}) async {
  if (songs.isEmpty) return;
  final audioService = ref.read(audioPlayerServiceProvider);
  final subsonicService = ref.read(subsonicServiceProvider);
  await audioService.setPlaylist(songs, initialIndex: initialIndex);
  await audioService.playAtIndex(
    initialIndex,
    (songId) => subsonicService.getStreamUrl(songId),
  );
}
