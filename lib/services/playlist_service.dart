import 'package:hive/hive.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'subsonic_service.dart';

class PlaylistService {
  final SubsonicService _subsonicService;
  Box<Playlist>? _playlistBox;
  Box<Song>? _songBox;

  PlaylistService(this._subsonicService) {
    _initBoxes();
  }

  /// 初始化存储
  Future<void> _initBoxes() async {
    _playlistBox = await Hive.openBox<Playlist>('playlists');
    _songBox = await Hive.openBox<Song>('songs');
  }

  /// 确保 boxes 已初始化
  Future<void> _ensureBoxes() async {
    if (_playlistBox == null || !_playlistBox!.isOpen) {
      _playlistBox = await Hive.openBox<Playlist>('playlists');
    }
    if (_songBox == null || !_songBox!.isOpen) {
      _songBox = await Hive.openBox<Song>('songs');
    }
  }

  /// 从服务器同步播放列表到本地
  Future<void> syncFromServer() async {
    try {
      await _ensureBoxes();

      // 获取服务器上的所有播放列表
      final serverPlaylists = await _subsonicService.getPlaylists();

      // 清空本地播放列表（可选：也可以做增量同步）
      await _playlistBox!.clear();

      // 将服务器播放列表保存到本地
      for (final playlistData in serverPlaylists) {
        final playlist = Playlist(
          id: playlistData['id'] as String,
          name: playlistData['name'] as String,
          description: playlistData['comment'] as String?,
          songIds: [], // 稍后获取详情时填充
          createdAt: DateTime.parse(playlistData['created'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.now(),
        );

        // 获取播放列表详情（包含歌曲列表）
        final details = await _subsonicService.getPlaylist(playlist.id);
        if (details != null && details['entry'] != null) {
          final entries = details['entry'];
          final songIds = <String>[];

          if (entries is List) {
            for (final entry in entries) {
              final songId = entry['id'] as String;
              songIds.add(songId);

              // 将歌曲保存到本地缓存
              final song = Song.fromJson(entry);
              await _songBox!.put(songId, song);
            }
          }

          final playlistWithSongs = playlist.copyWith(songIds: songIds);
          await _playlistBox!.put(playlist.id, playlistWithSongs);
        } else {
          await _playlistBox!.put(playlist.id, playlist);
        }
      }
    } catch (e) {
      print('Sync from server error: $e');
    }
  }

  /// 从服务器同步单个播放列表
  Future<void> syncPlaylistFromServer(String playlistId) async {
    try {
      await _ensureBoxes();

      // 从服务器获取播放列表详情
      final details = await _subsonicService.getPlaylist(playlistId);
      if (details != null) {
        final playlist = Playlist(
          id: details['id'] as String,
          name: details['name'] as String,
          description: details['comment'] as String?,
          songIds: [],
          createdAt: DateTime.parse(details['created'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.now(),
        );

        // 处理歌曲列表
        if (details['entry'] != null) {
          final entries = details['entry'];
          final songIds = <String>[];

          if (entries is List) {
            for (final entry in entries) {
              final songId = entry['id'] as String;
              songIds.add(songId);

              // 将歌曲保存到本地缓存
              final song = Song.fromJson(entry);
              await _songBox!.put(songId, song);
            }
          }

          final playlistWithSongs = playlist.copyWith(songIds: songIds);
          await _playlistBox!.put(playlistId, playlistWithSongs);
        } else {
          await _playlistBox!.put(playlistId, playlist);
        }
      }
    } catch (e) {
      print('Sync playlist from server error: $e');
    }
  }

  /// 创建播放列表（同时创建到服务器和本地）
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      await _ensureBoxes();

      // 在服务器上创建播放列表
      final playlistId = await _subsonicService.createPlaylist(
        name: name,
        comment: description,
      );

      if (playlistId != null) {
        // 创建成功，保存到本地
        final playlist = Playlist(
          id: playlistId,
          name: name,
          description: description,
          songIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _playlistBox!.put(playlist.id, playlist);
        return playlist;
      } else {
        // 如果服务器返回 null（早期版本），重新同步获取新创建的播放列表
        await syncFromServer();
        final playlists = await getAllPlaylists();
        return playlists.firstWhere(
          (p) => p.name == name,
          orElse: () => playlists.first,
        );
      }
    } catch (e) {
      print('Create playlist error: $e');
      return null;
    }
  }

  /// 获取所有播放列表
  Future<List<Playlist>> getAllPlaylists() async {
    await _ensureBoxes();
    final playlists = _playlistBox!.values.toList();
    // 按更新时间倒序排列
    playlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return playlists;
  }

  /// 获取单个播放列表
  Future<Playlist?> getPlaylist(String id) async {
    await _ensureBoxes();
    return _playlistBox!.get(id);
  }

  /// 更新播放列表信息
  Future<bool> updatePlaylist(Playlist playlist) async {
    try {
      await _ensureBoxes();

      // 更新服务器
      final success = await _subsonicService.updatePlaylistInfo(
        playlistId: playlist.id,
        name: playlist.name,
        comment: playlist.description,
      );

      if (success) {
        // 更新本地
        final updatedPlaylist = playlist.copyWith(updatedAt: DateTime.now());
        await _playlistBox!.put(playlist.id, updatedPlaylist);
        return true;
      }
      return false;
    } catch (e) {
      print('Update playlist error: $e');
      return false;
    }
  }

  /// 删除播放列表
  Future<bool> deletePlaylist(String id) async {
    try {
      await _ensureBoxes();

      // 从服务器删除
      final success = await _subsonicService.deletePlaylist(id);

      if (success) {
        // 从本地删除
        await _playlistBox!.delete(id);
        return true;
      }
      return false;
    } catch (e) {
      print('Delete playlist error: $e');
      return false;
    }
  }

  /// 添加歌曲到播放列表
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _ensureBoxes();
      final playlist = await getPlaylist(playlistId);
      if (playlist == null) return false;

      // 检查歌曲是否已存在
      if (playlist.songIds.contains(songId)) return true;

      // 添加到服务器
      final success = await _subsonicService.addSongToPlaylist(
        playlistId: playlistId,
        songId: songId,
      );

      if (success) {
        // 更新本地
        final updatedSongIds = [...playlist.songIds, songId];
        final updatedPlaylist = playlist.copyWith(
          songIds: updatedSongIds,
          updatedAt: DateTime.now(),
        );

        await _playlistBox!.put(playlistId, updatedPlaylist);
        return true;
      }
      return false;
    } catch (e) {
      print('Add song to playlist error: $e');
      return false;
    }
  }

  /// 从播放列表移除歌曲
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _ensureBoxes();
      final playlist = await getPlaylist(playlistId);
      if (playlist == null) return false;

      // 找到歌曲的索引
      final songIndex = playlist.songIds.indexOf(songId);
      if (songIndex == -1) return true; // 歌曲不存在，视为成功

      // 从服务器移除
      final success = await _subsonicService.removeSongFromPlaylist(
        playlistId: playlistId,
        songIndex: songIndex,
      );

      if (success) {
        // 更新本地
        final updatedSongIds = playlist.songIds.where((id) => id != songId).toList();
        final updatedPlaylist = playlist.copyWith(
          songIds: updatedSongIds,
          updatedAt: DateTime.now(),
        );

        await _playlistBox!.put(playlistId, updatedPlaylist);
        return true;
      }
      return false;
    } catch (e) {
      print('Remove song from playlist error: $e');
      return false;
    }
  }

  /// 获取播放列表中的歌曲
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    await _ensureBoxes();
    final playlist = await getPlaylist(playlistId);
    if (playlist == null) return [];

    final songs = <Song>[];
    for (final songId in playlist.songIds) {
      final song = _songBox!.get(songId);
      if (song != null) {
        songs.add(song);
      }
    }

    return songs;
  }

  /// 重新排序播放列表中的歌曲（仅本地操作，Subsonic API 不支持）
  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    await _ensureBoxes();
    final playlist = await getPlaylist(playlistId);
    if (playlist == null) return;

    final songIds = List<String>.from(playlist.songIds);
    final item = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, item);

    final updatedPlaylist = playlist.copyWith(
      songIds: songIds,
      updatedAt: DateTime.now(),
    );

    await _playlistBox!.put(playlistId, updatedPlaylist);
  }

  /// 检查歌曲是否在播放列表中
  Future<bool> isSongInPlaylist(String playlistId, String songId) async {
    await _ensureBoxes();
    final playlist = await getPlaylist(playlistId);
    if (playlist == null) return false;
    return playlist.songIds.contains(songId);
  }

  /// 获取包含指定歌曲的所有播放列表
  Future<List<Playlist>> getPlaylistsContainingSong(String songId) async {
    await _ensureBoxes();
    final allPlaylists = await getAllPlaylists();
    return allPlaylists.where((playlist) => playlist.songIds.contains(songId)).toList();
  }
}
