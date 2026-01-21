import 'package:hive/hive.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../services/subsonic_service.dart';

class MusicRepository {
  final SubsonicService _subsonicService;
  final Box<Song> _songsBox;
  final Box<Album> _albumsBox;
  final Box<Artist> _artistsBox;

  // 缓存过期时间（24小时）
  static const Duration _cacheExpiration = Duration(hours: 24);

  MusicRepository({
    required SubsonicService subsonicService,
  })  : _subsonicService = subsonicService,
        _songsBox = Hive.box<Song>('songs'),
        _albumsBox = Hive.box<Album>('albums'),
        _artistsBox = Hive.box<Artist>('artists');

  /// 获取随机歌曲（缓存优先）
  Future<List<Song>> getRandomSongs({int size = 10, bool forceRefresh = false}) async {
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh && _songsBox.isNotEmpty) {
      final cachedSongs = _songsBox.values.toList();
      if (cachedSongs.isNotEmpty && _isCacheValid(cachedSongs.first.cacheTime)) {
        return cachedSongs;
      }
    }

    // 从网络获取
    final songs = await _subsonicService.getRandomSongs(size: size);

    // 更新缓存
    if (songs.isNotEmpty) {
      await _songsBox.clear();
      for (var song in songs) {
        await _songsBox.put(song.id, song);
      }
    }

    return songs;
  }

  /// 获取专辑列表（缓存优先）
  Future<List<Album>> getAlbumList({
    String type = 'newest',
    int size = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh && _albumsBox.isNotEmpty) {
      final cachedAlbums = _albumsBox.values.toList();
      if (cachedAlbums.isNotEmpty && _isCacheValid(cachedAlbums.first.cacheTime)) {
        return cachedAlbums;
      }
    }

    // 从网络获取
    final albums = await _subsonicService.getAlbumList(
      type: type,
      size: size,
      offset: offset,
    );

    // 更新缓存
    if (albums.isNotEmpty) {
      await _albumsBox.clear();
      for (var album in albums) {
        await _albumsBox.put(album.id, album);
      }
    }

    return albums;
  }

  /// 获取专辑详情（包含歌曲列表）
  Future<List<Song>> getAlbum(String albumId) async {
    return await _subsonicService.getAlbum(albumId);
  }

  /// 搜索
  Future<Map<String, dynamic>> search(String query) async {
    return await _subsonicService.search(query);
  }

  /// 获取流媒体 URL
  String getStreamUrl(String songId) {
    return _subsonicService.getStreamUrl(songId);
  }

  /// 获取封面图片 URL
  String getCoverArtUrl(String coverArtId, {int size = 300}) {
    return _subsonicService.getCoverArtUrl(coverArtId, size: size);
  }

  /// 检查缓存是否有效
  bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < _cacheExpiration;
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    await _songsBox.clear();
    await _albumsBox.clear();
    await _artistsBox.clear();
  }

  /// 获取所有艺术家（缓存优先）
  Future<List<Artist>> getArtists({bool forceRefresh = false}) async {
    // 如果不强制刷新，先尝试从缓存获取
    if (!forceRefresh && _artistsBox.isNotEmpty) {
      final cachedArtists = _artistsBox.values.toList();
      if (cachedArtists.isNotEmpty && _isCacheValid(cachedArtists.first.cacheTime)) {
        return cachedArtists;
      }
    }

    // 从网络获取
    final artists = await _subsonicService.getArtists();

    // 更新缓存
    if (artists.isNotEmpty) {
      await _artistsBox.clear();
      for (var artist in artists) {
        await _artistsBox.put(artist.id, artist);
      }
    }

    return artists;
  }

  /// 获取艺术家详情（包含专辑列表）
  Future<Map<String, dynamic>?> getArtist(String artistId) async {
    return await _subsonicService.getArtist(artistId);
  }

  /// 获取音乐库统计信息
  Future<Map<String, int>> getLibraryStats() async {
    return {
      'songs': _songsBox.length,
      'albums': _albumsBox.length,
      'artists': _artistsBox.length,
    };
  }
}
