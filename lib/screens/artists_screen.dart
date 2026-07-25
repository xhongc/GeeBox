import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../models/artist.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

final artistsProvider = FutureProvider.autoDispose<List<Artist>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getArtists();
});

class ArtistsScreen extends ConsumerStatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ConsumerState<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends ConsumerState<ArtistsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(artistsProvider);

    return ChansonScaffold(
      title: '艺术家',
      suffixes: [
        FHeaderAction(
          icon: const Icon(FLucideIcons.refreshCw),
          onPress: () => ref.invalidate(artistsProvider),
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FTextField(
              hint: '搜索艺术家...',
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(
                context,
                style,
                variants,
                const Icon(FLucideIcons.search),
              ),
              onSubmit: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              onEditingComplete: () {},
              control: FTextFieldControl.managed(
                onChange: (value) {
                  setState(() {
                    _searchQuery = value.text.toLowerCase();
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: artistsAsync.when(
              data: (artists) {
                if (artists.isEmpty) {
                  return const ChansonEmptyState(
                    icon: FLucideIcons.userRound,
                    message: '暂无艺术家',
                  );
                }

                final filteredArtists = _searchQuery.isEmpty
                    ? artists
                    : artists
                        .where(
                          (artist) =>
                              artist.name.toLowerCase().contains(_searchQuery),
                        )
                        .toList();

                if (filteredArtists.isEmpty) {
                  return const ChansonEmptyState(
                    icon: FLucideIcons.searchX,
                    message: '未找到匹配的艺术家',
                  );
                }

                final groupedArtists = _groupArtistsByInitial(filteredArtists);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final entry in groupedArtists.entries)
                      _buildArtistGroup(context, entry.key, entry.value),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => error.toErrorWidget(
                onRetry: () => ref.invalidate(artistsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Artist>> _groupArtistsByInitial(List<Artist> artists) {
    final grouped = <String, List<Artist>>{};

    for (final artist in artists) {
      final initial =
          artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '#';
      final key = RegExp(r'^[A-Z]$').hasMatch(initial) ? initial : '#';
      grouped.putIfAbsent(key, () => []).add(artist);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    return {
      for (final key in sortedKeys) key: grouped[key]!,
    };
  }

  Widget _buildArtistGroup(
    BuildContext context,
    String initial,
    List<Artist> artists,
  ) {
    return ChansonSection(
      title: initial,
      children: [
        for (final artist in artists) _buildArtistItem(context, artist),
      ],
    );
  }

  Widget _buildArtistItem(BuildContext context, Artist artist) {
    final repository = ref.read(musicRepositoryProvider);

    return FTile(
      prefix: SizedBox.square(
        dimension: 42,
        child: ChansonCoverArt(
          imageUrl: artist.coverArt == null
              ? null
              : repository.getCoverArtUrl(artist.coverArt!, size: 100),
          fallbackIcon: FLucideIcons.userRound,
          borderRadius: 21,
        ),
      ),
      title: Text(artist.name),
      subtitle:
          artist.albumCount == null ? null : Text('${artist.albumCount} 张专辑'),
      suffix: const Icon(FLucideIcons.chevronRight),
      onPress: () {
        context.push('/artist-detail', extra: {
          'artistId': artist.id,
          'artistName': artist.name,
          'coverArtId': artist.coverArt,
        });
      },
    );
  }
}
