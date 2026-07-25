import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_repository_provider.dart';
import '../providers/media_type_settings_provider.dart';
import '../models/album.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

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
    final mediaSettings = ref.watch(mediaTypeSettingsProvider);

    // 根据选择的分类获取不同的专辑列表
    final albumsAsync = _selectedCategory == 'newest'
        ? ref.watch(recentAlbumsProvider)
        : _selectedCategory == 'random'
            ? ref.watch(randomAlbumsProvider)
            : ref.watch(frequentAlbumsProvider);
    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        title: const Text('发现'),
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.search),
            onPress: () => context.push('/search'),
          ),
        ],
      ),
      child: CustomScrollView(
        slivers: [
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

          // 浏览内容 - 根据媒体类型设置显示
          if (mediaSettings.hasAtLeastOneEnabled)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '浏览内容',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (mediaSettings.musicEnabled)
                      _buildBrowseCard(
                        context,
                        '音乐分类',
                        '流派、年代、排行榜',
                        Icons.music_note,
                        Colors.blue,
                        () {
                          // TODO: 导航到音乐分类页面
                        },
                      ),
                    if (mediaSettings.podcastEnabled)
                      _buildBrowseCard(
                        context,
                        '播客分类',
                        '商业、教育、娱乐等',
                        Icons.mic,
                        Colors.purple,
                        () {
                          // TODO: 导航到播客分类页面
                        },
                      ),
                    if (mediaSettings.audiobookEnabled)
                      _buildBrowseCard(
                        context,
                        '有声书分类',
                        '小说、传记、自我提升',
                        Icons.menu_book,
                        Colors.orange,
                        () {
                          // TODO: 导航到有声书分类页面
                        },
                      ),
                    if (mediaSettings.radioEnabled)
                      _buildBrowseCard(
                        context,
                        '电台分类',
                        '心情、场景、流派',
                        Icons.radio,
                        Colors.green,
                        () {
                          // TODO: 导航到电台分类页面
                        },
                      ),
                    if (mediaSettings.musicEnabled)
                      _buildBrowseCard(
                        context,
                        '艺术家',
                        '按字母、热门排序',
                        Icons.person,
                        Colors.teal,
                        () {
                          context.push('/artists');
                        },
                      ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 推荐专辑 - 仅在启用音乐时显示
          if (mediaSettings.musicEnabled) ...[
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
          ],

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

  Widget _buildBrowseCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FTile(
        prefix: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        suffix: const Icon(FLucideIcons.chevronRight),
        onPress: onTap,
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, Album album) {
    final repository = ref.read(musicRepositoryProvider);

    return ChansonGridCard(
      imageUrl: album.coverArt == null
          ? null
          : repository.getCoverArtUrl(album.coverArt!),
      title: album.name,
      subtitle: album.artist ?? '未知艺术家',
      fallbackIcon: FLucideIcons.disc3,
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
}
