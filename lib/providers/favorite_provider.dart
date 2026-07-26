import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorite_service.dart';
import '../models/song.dart';
import '../models/starred_items.dart';
import 'subsonic_provider.dart';

/// 收藏服务 Provider
final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return FavoriteService(subsonicService);
});

/// 收藏列表 Provider（歌曲、专辑、艺术家）
final starredItemsProvider =
    FutureProvider.autoDispose<StarredItems>((ref) async {
  final service = ref.watch(favoriteServiceProvider);
  return await service.getStarred2();
});

/// 收藏歌曲 Provider（自动刷新）
final starredSongsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  final items = await ref.watch(starredItemsProvider.future);
  return items.songs;
});

/// 单个歌曲的收藏状态 Provider（用于显示爱心图标）
final isSongStarredProvider = FutureProvider.family.autoDispose<bool, String>(
  (ref, songId) async {
    try {
      final songs = await ref.watch(starredSongsProvider.future);
      return songs.any((song) => song.id == songId);
    } catch (e) {
      return false;
    }
  },
);

/// 单个专辑的收藏状态 Provider
final isAlbumStarredProvider = FutureProvider.family.autoDispose<bool, String>(
  (ref, albumId) async {
    try {
      final items = await ref.watch(starredItemsProvider.future);
      return items.albums.any((album) => album.id == albumId);
    } catch (e) {
      return false;
    }
  },
);

/// 单个艺术家的收藏状态 Provider
final isArtistStarredProvider = FutureProvider.family.autoDispose<bool, String>(
  (ref, artistId) async {
    try {
      final items = await ref.watch(starredItemsProvider.future);
      return items.artists.any((artist) => artist.id == artistId);
    } catch (e) {
      return false;
    }
  },
);
