import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_repository_provider.dart';
import '../models/album.dart';
import '../widgets/error_view.dart';

/// 专辑列表页面
class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  String _sortType = 'newest'; // newest, alphabeticalByName, alphabeticalByArtist, random

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumListProvider(_sortType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('所有专辑'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('最新'),
              ),
              const PopupMenuItem(
                value: 'alphabeticalByName',
                child: Text('按名称排序'),
              ),
              const PopupMenuItem(
                value: 'alphabeticalByArtist',
                child: Text('按艺术家排序'),
              ),
              const PopupMenuItem(
                value: 'random',
                child: Text('随机'),
              ),
            ],
          ),
        ],
      ),
      body: albumsAsync.when(
        data: (albums) {
          if (albums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.album, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无专辑',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              return _buildAlbumCard(context, albums[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => error.toErrorWidget(
          onRetry: () => ref.invalidate(albumListProvider(_sortType)),
        ),
      ),
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

// 专辑列表 Provider（按类型）
final albumListProvider = FutureProvider.family.autoDispose<List<Album>, String>(
  (ref, type) async {
    final repository = ref.watch(musicRepositoryProvider);
    return await repository.getAlbumList(type: type, size: 100);
  },
);
