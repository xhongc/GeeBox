import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_repository_provider.dart';
import '../models/album.dart';
import '../widgets/error_view.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _selectedCategory = 'newest';

  @override
  void initState() {
    super.initState();
    // 页面加载时获取数据
    Future.microtask(() {
      ref.read(recentAlbumsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 根据选择的分类获取不同的专辑列表
    final albumsAsync = _selectedCategory == 'newest'
        ? ref.watch(recentAlbumsProvider)
        : _selectedCategory == 'random'
            ? ref.watch(randomAlbumsProvider)
            : ref.watch(frequentAlbumsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            floating: true,
            title: const Text(
              '发现',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  context.push('/search');
                },
              ),
            ],
          ),

          // 分类标签
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('最新专辑', 'newest'),
                  _buildCategoryChip('随机推荐', 'random'),
                  _buildCategoryChip('热门专辑', 'frequent'),
                ],
              ),
            ),
          ),

          // 推荐专辑
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCategoryTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 刷新当前分类的数据
                      if (_selectedCategory == 'newest') {
                        ref.invalidate(recentAlbumsProvider);
                      } else if (_selectedCategory == 'random') {
                        ref.invalidate(randomAlbumsProvider);
                      } else {
                        ref.invalidate(frequentAlbumsProvider);
                      }
                    },
                    child: const Text('刷新'),
                  ),
                ],
              ),
            ),
          ),

          albumsAsync.when(
            data: (albums) {
              if (albums.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildAlbumCard(context, albums[index]);
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
                onRetry: () {
                  if (_selectedCategory == 'newest') {
                    ref.invalidate(recentAlbumsProvider);
                  } else if (_selectedCategory == 'random') {
                    ref.invalidate(randomAlbumsProvider);
                  } else {
                    ref.invalidate(frequentAlbumsProvider);
                  }
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  String _getCategoryTitle() {
    switch (_selectedCategory) {
      case 'newest':
        return '最新专辑';
      case 'random':
        return '随机推荐';
      case 'frequent':
        return '热门专辑';
      default:
        return '推荐专辑';
    }
  }

  Widget _buildCategoryChip(String label, String category) {
    final selected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }

  Widget _buildAlbumCard(BuildContext context, Album album) {
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
          // 艺术家
          Text(
            album.artist ?? '未知艺术家',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
