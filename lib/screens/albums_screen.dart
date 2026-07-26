import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/album.dart';
import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

/// Listener 风格专辑列表页面
class AlbumsScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const AlbumsScreen({
    super.key,
    this.embedded = false,
  });

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  String _sortType = 'newest';
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumListProvider(_sortType));
    final horizontalPadding = widget.embedded ? 4.0 : 16.0;

    return ListenerPageBackground(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, 10, horizontalPadding, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _AlbumsHeading(
                  selected: _sortType,
                  onRefresh: () => ref.invalidate(albumListProvider(_sortType)),
                  onChanged: (value) {
                    setState(() {
                      _sortType = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _AlbumFilterField(
                  controller: _filterController,
                  onChanged: (value) => setState(() => _filter = value),
                  onClear: () {
                    _filterController.clear();
                    setState(() => _filter = '');
                  },
                ),
                const SizedBox(height: 18),
                albumsAsync.when(
                  data: (albums) {
                    final filtered = _filterAlbums(albums, _filter);
                    return _AlbumsSummary(
                      sort: _sortType,
                      count: filtered.length,
                      onPlayFirst: filtered.isEmpty
                          ? null
                          : () => _playAlbum(ref, filtered.first),
                      onPlayRandom: filtered.isEmpty
                          ? null
                          : () {
                              final shuffled = List<Album>.from(filtered)
                                ..shuffle();
                              _playAlbum(ref, shuffled.first);
                            },
                    );
                  },
                  loading: () => _AlbumsSummary(
                    sort: _sortType,
                    count: 0,
                    loading: true,
                    onPlayFirst: null,
                    onPlayRandom: null,
                  ),
                  error: (_, __) => _AlbumsSummary(
                    sort: _sortType,
                    count: 0,
                    onPlayFirst: null,
                    onPlayRandom: null,
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          albumsAsync.when(
            data: (albums) {
              final filtered = _filterAlbums(albums, _filter);
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _AlbumsEmpty(),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 0, horizontalPadding, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final album = filtered[index];
                      return ListenerAlbumCard(
                        album: album,
                        imageUrl: album.coverArt == null
                            ? null
                            : ref
                                .read(musicRepositoryProvider)
                                .getCoverArtUrl(album.coverArt!),
                        onPress: () => context.push('/album-detail', extra: {
                          'albumId': album.id,
                          'albumName': album.name,
                          'albumArtist': album.artist,
                          'coverArtId': album.coverArt,
                        }),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: FCircularProgress()),
            ),
            error: (_, __) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FButton(
                  variant: FButtonVariant.ghost,
                  onPress: () => ref.invalidate(albumListProvider(_sortType)),
                  child: const Text('重新加载专辑'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumFilterField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _AlbumFilterField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        boxShadow: ListenerShadows.soft,
      ),
      child: FTextField(
        hint: '过滤专辑或艺术家',
        style: FTextFieldStyleDelta.delta(
          color: FVariantsValueDelta.delta([
            FVariantValueDeltaOperation.all(Colors.transparent),
          ]),
          border: FVariantsValueDelta.delta([
            FVariantValueDeltaOperation.all(InputBorder.none),
          ]),
        ),
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
      ),
    );
  }
}

class _AlbumsHeading extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  const _AlbumsHeading({
    required this.selected,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '专辑收藏',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '专辑',
                    style: TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ListenerCircleButton(
              icon: FLucideIcons.refreshCcw,
              onPress: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _SortPill(
                label: '最近添加',
                value: 'newest',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '最近播放',
                value: 'recent',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '最多播放',
                value: 'frequent',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: 'A-Z排序',
                value: 'alphabeticalByName',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '歌手排序',
                value: 'alphabeticalByArtist',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '随机',
                value: 'random',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '缺失封面',
                value: 'less_cover',
                selected: selected,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SortPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;

    return FTappable(
      onPress: () => onChanged(value),
      builder: (context, states, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? ListenerColors.foreground
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? ListenerShadows.soft : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : ListenerColors.softText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _AlbumsSummary extends StatelessWidget {
  final String sort;
  final int count;
  final bool loading;
  final VoidCallback? onPlayFirst;
  final VoidCallback? onPlayRandom;

  const _AlbumsSummary({
    required this.sort,
    required this.count,
    this.loading = false,
    required this.onPlayFirst,
    required this.onPlayRandom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: ListenerGradients.darkPlayer,
        borderRadius: BorderRadius.circular(26),
        boxShadow: ListenerShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前视图',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loading ? '正在加载...' : _pageTitle(sort),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loading ? '正在整理你的专辑收藏。' : _summaryText(sort, count),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: onPlayFirst,
                  prefix: const Icon(FLucideIcons.play, size: 17),
                  child: const Text('播放第一张'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: onPlayRandom,
                  prefix: const Icon(FLucideIcons.shuffle, size: 17),
                  child: const Text('随机一张'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _pageTitle(String sort) {
    return switch (sort) {
      'recent' => '最近播放',
      'frequent' => '最多播放',
      'alphabeticalByName' => 'A-Z排序',
      'alphabeticalByArtist' => '歌手排序',
      'less_cover' => '缺失封面',
      'random' => '随机',
      _ => '最近添加',
    };
  }

  static String _summaryText(String sort, int count) {
    final prefix = switch (sort) {
      'recent' => '最近听过的专辑聚在这里，方便无缝续播。',
      'frequent' => '这些是你最常回放的专辑，基本都是稳定命中。',
      'alphabeticalByName' => '按名称浏览整库，找专辑会更直接。',
      'alphabeticalByArtist' => '按艺术家线索整理，适合顺着人声和风格往下翻。',
      'less_cover' => '这里是还缺封面的专辑，后续可以继续补全。',
      'random' => '随机抽取一批专辑，适合不知道听什么的时候。',
      _ => '新收进来的专辑会先出现在这里，适合直接开始今天的播放。',
    };
    return '$prefix 当前加载 $count 张。';
  }
}

class _AlbumsEmpty extends StatelessWidget {
  const _AlbumsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FLucideIcons.disc3, color: ListenerColors.muted, size: 48),
          SizedBox(height: 14),
          Text(
            '暂无专辑',
            style: TextStyle(color: ListenerColors.muted),
          ),
        ],
      ),
    );
  }
}

// 专辑列表 Provider（按类型）
final albumListProvider =
    FutureProvider.family.autoDispose<List<Album>, String>(
  (ref, type) async {
    final normalized = switch (type) {
      'recent' => 'recent',
      'frequent' => 'frequent',
      'alphabeticalByName' => 'alphabeticalByName',
      'alphabeticalByArtist' => 'alphabeticalByArtist',
      'less_cover' => 'newest',
      'random' => 'random',
      _ => 'newest',
    };
    final repository = ref.watch(musicRepositoryProvider);
    var albums = await repository.getAlbumList(type: normalized, size: 100);
    if (type == 'less_cover') {
      albums = albums.where((album) => album.coverArt == null).toList();
    }
    return albums;
  },
);

List<Album> _filterAlbums(List<Album> albums, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return albums;
  return albums.where((album) {
    return album.name.toLowerCase().contains(normalized) ||
        (album.artist ?? '').toLowerCase().contains(normalized);
  }).toList();
}

Future<void> _playAlbum(WidgetRef ref, Album album) async {
  final context = ref.context;
  try {
    final repository = ref.read(musicRepositoryProvider);
    final songs = await repository.getAlbum(album.id);
    if (!context.mounted) return;
    if (songs.isEmpty) {
      showChansonToast(context, '这张专辑暂无歌曲');
      return;
    }
    await _playSongs(ref, songs);
  } catch (error) {
    if (!context.mounted) return;
    showChansonToast(context, '播放专辑失败: $error', destructive: true);
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
