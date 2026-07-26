import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/listener_components.dart';
import '../widgets/listener_track_action_sheet.dart';

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  String _sort = 'recently-added';
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsLibraryProvider(_sort));

    return ListenerPageBackground(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SongsHeading(
                  selected: _sort,
                  onChanged: (value) {
                    setState(() => _sort = value);
                  },
                  onRefresh: () => ref.invalidate(songsLibraryProvider(_sort)),
                ),
                const SizedBox(height: 18),
                _LibraryFilterField(
                  controller: _filterController,
                  hint: '过滤歌曲、艺术家或专辑',
                  onChanged: (value) => setState(() => _filter = value),
                  onClear: () {
                    _filterController.clear();
                    setState(() => _filter = '');
                  },
                ),
                const SizedBox(height: 18),
                songsAsync.when(
                  data: (songs) {
                    final filtered = _filterSongs(songs, _filter);
                    return _SongsSummary(
                      sort: _sort,
                      count: filtered.length,
                      onPlay: filtered.isEmpty
                          ? null
                          : () => _playSongs(ref, filtered),
                      onShuffle: filtered.isEmpty
                          ? null
                          : () => _shuffleSongs(ref, filtered),
                    );
                  },
                  loading: () => _SongsSummary(
                    sort: _sort,
                    count: 0,
                    loading: true,
                    onPlay: null,
                    onShuffle: null,
                  ),
                  error: (_, __) => _SongsSummary(
                    sort: _sort,
                    count: 0,
                    onPlay: null,
                    onShuffle: null,
                  ),
                ),
                const SizedBox(height: 22),
              ]),
            ),
          ),
          songsAsync.when(
            data: (songs) {
              final filtered = _filterSongs(songs, _filter);
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _SongsEmpty(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = filtered[index];
                      final imageUrl = _songCoverUrl(ref, song);
                      return ListenerTrackRow(
                        song: song,
                        imageUrl: imageUrl,
                        onPress: () => _playSongs(
                          ref,
                          filtered,
                          initialIndex: index,
                        ),
                        onMore: () => showListenerTrackActionSheet(
                          context: context,
                          ref: ref,
                          song: song,
                          imageUrl: imageUrl,
                          queue: filtered,
                          index: index,
                        ),
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
                  onPress: () => ref.invalidate(songsLibraryProvider(_sort)),
                  child: const Text('重新加载歌曲'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryFilterField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _LibraryFilterField({
    required this.controller,
    required this.hint,
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
        hint: hint,
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

class _SongsHeading extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  const _SongsHeading({
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '歌曲馆',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _heroTitle(selected),
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
            ListenerCircleButton(
              icon: FLucideIcons.refreshCcw,
              onPress: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SortPill(
                label: '最近添加',
                value: 'recently-added',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '最近播放',
                value: 'recently-played',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: '最多播放',
                value: 'most-played',
                selected: selected,
                onChanged: onChanged,
              ),
              const SizedBox(width: 10),
              _SortPill(
                label: 'A-Z排序',
                value: 'a-z',
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
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? ListenerShadows.soft : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : ListenerColors.softText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}

class _SongsSummary extends StatelessWidget {
  final String sort;
  final int count;
  final bool loading;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const _SongsSummary({
    required this.sort,
    required this.count,
    required this.onPlay,
    required this.onShuffle,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
        boxShadow: ListenerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '随手开播',
            style: TextStyle(
              color: ListenerColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            loading ? '正在整理歌曲' : '已经整理 $count 首歌',
            style: const TextStyle(
              color: ListenerColors.foreground,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _summarySubtitle(sort),
            style: const TextStyle(
              color: ListenerColors.softText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: onPlay,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FLucideIcons.play, size: 17),
                      SizedBox(width: 8),
                      Text('播放全部'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: onShuffle,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FLucideIcons.shuffle, size: 17),
                      SizedBox(width: 8),
                      Text('打乱'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SongsEmpty extends StatelessWidget {
  const _SongsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(FLucideIcons.music, color: ListenerColors.muted, size: 48),
        SizedBox(height: 14),
        Text(
          '这里还没有声音',
          style: TextStyle(
            color: ListenerColors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '这里暂时没有歌曲，稍后再回来看看。',
          style: TextStyle(color: ListenerColors.muted),
        ),
      ],
    );
  }
}

String _heroTitle(String sort) {
  return switch (sort) {
    'recently-played' => '最近反复想听',
    'most-played' => '循环最多的旋律',
    'a-z' => '按字母慢慢翻',
    _ => '刚收进来的新歌',
  };
}

List<Song> _filterSongs(List<Song> songs, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return songs;
  return songs.where((song) {
    return song.title.toLowerCase().contains(normalized) ||
        (song.artist ?? '').toLowerCase().contains(normalized) ||
        (song.album ?? '').toLowerCase().contains(normalized) ||
        (song.genre ?? '').toLowerCase().contains(normalized);
  }).toList();
}

String _summarySubtitle(String sort) {
  return switch (sort) {
    'recently-played' => '把最近点开过的歌聚在一起，接着上次的情绪继续听。',
    'most-played' => '这些歌被你放得最多，适合一键回到熟悉的节奏。',
    'a-z' => '按字母排序慢慢找，翻歌时会更清楚。',
    _ => '刚入库的新声音排在前面，适合直接看看最近收了什么。',
  };
}

String? _songCoverUrl(WidgetRef ref, Song song) {
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
