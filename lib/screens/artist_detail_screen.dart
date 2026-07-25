import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../models/album.dart';
import '../providers/music_repository_provider.dart';
import '../widgets/error_view.dart';
import '../widgets/forui_components.dart';

final artistDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, artistId) async {
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
    final coverUrl = coverArtId == null
        ? null
        : repository.getCoverArtUrl(coverArtId!, size: 500);

    return ChansonScaffold(
      title: artistName,
      child: artistAsync.when(
        data: (artistData) {
          if (artistData == null) {
            return const ChansonEmptyState(
              icon: FLucideIcons.userRoundX,
              message: '加载失败',
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _ArtistHero(name: artistName, coverUrl: coverUrl),
              const SizedBox(height: 18),
              if (albums.isEmpty)
                const SizedBox(
                  height: 220,
                  child: ChansonEmptyState(
                    icon: FLucideIcons.disc3,
                    message: '暂无专辑',
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    return _buildAlbumCard(context, ref, albums[index]);
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => error.toErrorWidget(
          onRetry: () => ref.invalidate(artistDetailProvider(artistId)),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, WidgetRef ref, Album album) {
    final repository = ref.read(musicRepositoryProvider);

    return ChansonGridCard(
      imageUrl: album.coverArt == null
          ? null
          : repository.getCoverArtUrl(album.coverArt!),
      title: album.name,
      subtitle: album.year?.toString() ?? album.artist ?? '未知艺术家',
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

class _ArtistHero extends StatelessWidget {
  final String name;
  final String? coverUrl;

  const _ArtistHero({
    required this.name,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: 132,
          child: ChansonCoverArt(
            imageUrl: coverUrl,
            fallbackIcon: FLucideIcons.userRound,
            borderRadius: 66,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            name,
            style: theme.typography.body.xl3.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
