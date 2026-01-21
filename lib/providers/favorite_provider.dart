import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorite_service.dart';
import '../models/song.dart';
import 'subsonic_provider.dart';

/// 收藏服务 Provider
final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return FavoriteService(subsonicService);
});

/// 收藏列表 Provider（自动刷新）
final starredSongsProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  final service = ref.watch(favoriteServiceProvider);
  return await service.getStarredSongs();
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
