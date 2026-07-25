import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_repository_provider.dart';
import '../models/album.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

/// 专辑列表页面
class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  String _sortType =
      'newest'; // newest, alphabeticalByName, alphabeticalByArtist, random

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumListProvider(_sortType));

    return ChansonScaffold(
      title: '所有专辑',
      suffixes: [
        FHeaderAction(
          icon: const Icon(FLucideIcons.shuffle),
          onPress: () {
            setState(() {
              _sortType = _sortType == 'random' ? 'newest' : 'random';
            });
          },
        ),
      ],
      child: albumsAsync.when(
        data: (albums) {
          if (albums.isEmpty) {
            return const ChansonEmptyState(
              icon: FLucideIcons.disc3,
              message: '暂无专辑',
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

// 专辑列表 Provider（按类型）
final albumListProvider =
    FutureProvider.family.autoDispose<List<Album>, String>(
  (ref, type) async {
    final repository = ref.watch(musicRepositoryProvider);
    return await repository.getAlbumList(type: type, size: 100);
  },
);
