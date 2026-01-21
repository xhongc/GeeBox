import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/playlist_service.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'subsonic_provider.dart';

/// 播放列表服务 Provider
final playlistServiceProvider = Provider<PlaylistService>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return PlaylistService(subsonicService);
});

/// 所有播放列表 Provider（直接从 API 获取，不使用缓存）
final playlistsProvider = FutureProvider.autoDispose<List<Playlist>>((ref) async {
  final subsonicService = ref.watch(subsonicServiceProvider);

  // 直接从 API 获取播放列表
  final serverPlaylists = await subsonicService.getPlaylists();

  // 转换为 Playlist 对象
  final playlists = <Playlist>[];
  for (final playlistData in serverPlaylists) {
    final playlist = Playlist(
      id: playlistData['id'] as String,
      name: playlistData['name'] as String,
      description: playlistData['comment'] as String?,
      songIds: [], // 列表页不需要歌曲详情
      createdAt: DateTime.parse(playlistData['created'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.now(),
    );
    playlists.add(playlist);
  }

  return playlists;
});

/// 单个播放列表 Provider（直接从 API 获取）
final playlistProvider = FutureProvider.autoDispose.family<Playlist?, String>((ref, id) async {
  final subsonicService = ref.watch(subsonicServiceProvider);

  // 直接从 API 获取播放列表详情
  final details = await subsonicService.getPlaylist(id);
  if (details != null) {
    final songIds = <String>[];
    if (details['entry'] != null) {
      final entries = details['entry'];
      if (entries is List) {
        for (final entry in entries) {
          songIds.add(entry['id'] as String);
        }
      }
    }

    return Playlist(
      id: details['id'] as String,
      name: details['name'] as String,
      description: details['comment'] as String?,
      songIds: songIds,
      createdAt: DateTime.parse(details['created'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.now(),
    );
  }

  return null;
});

/// 播放列表中的歌曲 Provider（直接从 API 获取）
final playlistSongsProvider = FutureProvider.autoDispose.family<List<Song>, String>((ref, playlistId) async {
  final subsonicService = ref.watch(subsonicServiceProvider);

  // 直接从 API 获取播放列表详情（包含歌曲）
  final details = await subsonicService.getPlaylist(playlistId);
  if (details != null && details['entry'] != null) {
    final entries = details['entry'];
    final songs = <Song>[];

    if (entries is List) {
      for (final entry in entries) {
        final song = Song.fromJson(entry);
        songs.add(song);
      }
    }

    return songs;
  }

  return [];
});

/// 刷新播放列表的辅助方法
void refreshPlaylists(WidgetRef ref) {
  ref.invalidate(playlistsProvider);
}

void refreshPlaylist(WidgetRef ref, String playlistId) {
  ref.invalidate(playlistProvider(playlistId));
  ref.invalidate(playlistSongsProvider(playlistId));
}
