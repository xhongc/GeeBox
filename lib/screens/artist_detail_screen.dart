import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_repository_provider.dart';
import '../models/album.dart';
import '../widgets/error_view.dart';

// 艺术家详情 Provider
final artistDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, artistId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getArtist(artistId);
});

class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;
  final String artistName;
  final String? coverArtId;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverArtId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistDetailProvider(artistId));
    final repository = ref.read(musicRepositoryProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                artistName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(128, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              background: coverArtId != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          repository.getCoverArtUrl(coverArtId!, size: 500),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        // 渐变遮罩
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          // 专辑列表
          artistAsync.when(
            data: (artistData) {
              if (artistData == null) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        '加载失败',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              final albums = <Album>[];
              if (artistData['album'] != null) {
                final albumList = artistData['album'];
                if (albumList is List) {
                  albums.addAll(albumList.map((json) => Album.fromJson(json)));
                } else if (albumList is Map) {
                  albums.add(Album.fromJson(albumList.cast<String, dynamic>()));
                }
              }

              if (albums.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        '暂无专辑',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildAlbumCard(context, ref, albums[index]);
                    },
                    childCount: albums.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: error.toErrorWidget(
                onRetry: () => ref.invalidate(artistDetailProvider(artistId)),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, WidgetRef ref, Album album) {
    final repository = ref.read(musicRepositoryProvider);

    return InkWell(
      onTap: () {
        context.push('/album-detail', extra: {
          'albumId': album.id,
          'albumName': album.name,
          'albumArtist': album.artist,
          'coverArtId': album.coverArt,
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverArt != null
                  ? Image.network(
                      repository.getCoverArtUrl(album.coverArt!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.album,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.album,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // 标题
          Text(
            album.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // 年份
          if (album.year != null)
            Text(
              album.year.toString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}
