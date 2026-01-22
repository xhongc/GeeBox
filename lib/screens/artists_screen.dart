import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_repository_provider.dart';
import '../models/artist.dart';
import '../widgets/error_view.dart';

// 艺术家列表 Provider
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
  void initState() {
    super.initState();
    // 页面加载时获取数据
    Future.microtask(() {
      ref.read(artistsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('艺术家'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(artistsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索艺术家...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 艺术家列表
          Expanded(
            child: artistsAsync.when(
              data: (artists) {
                if (artists.isEmpty) {
                  return const Center(
                    child: Text(
                      '暂无艺术家',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // 过滤艺术家
                final filteredArtists = _searchQuery.isEmpty
                    ? artists
                    : artists.where((artist) {
                        return artist.name.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filteredArtists.isEmpty) {
                  return const Center(
                    child: Text(
                      '未找到匹配的艺术家',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // 按首字母分组
                final groupedArtists = _groupArtistsByInitial(filteredArtists);

                return ListView.builder(
                  itemCount: groupedArtists.length,
                  itemBuilder: (context, index) {
                    final entry = groupedArtists.entries.elementAt(index);
                    return _buildArtistGroup(context, entry.key, entry.value);
                  },
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
      final initial = artist.name.isNotEmpty
          ? artist.name[0].toUpperCase()
          : '#';

      // 如果不是字母，归类到 #
      final key = RegExp(r'^[A-Z]$').hasMatch(initial) ? initial : '#';

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(artist);
    }

    // 排序
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });

    final sortedGrouped = <String, List<Artist>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  Widget _buildArtistGroup(BuildContext context, String initial, List<Artist> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        // 艺术家列表
        ...artists.map((artist) => _buildArtistItem(context, artist)),
      ],
    );
  }

  Widget _buildArtistItem(BuildContext context, Artist artist) {
    final repository = ref.read(musicRepositoryProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: artist.coverArt != null
            ? NetworkImage(repository.getCoverArtUrl(artist.coverArt!, size: 100))
            : null,
        child: artist.coverArt == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        artist.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: artist.albumCount != null
          ? Text('${artist.albumCount} 张专辑')
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/artist-detail', extra: {
          'artistId': artist.id,
          'artistName': artist.name,
          'coverArtId': artist.coverArt,
        });
      },
    );
  }
}
