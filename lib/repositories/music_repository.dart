import 'package:hive/hive.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/genre.dart';
import '../services/subsonic_service.dart';

class MusicRepository {
  final SubsonicService _subsonicService;
  final Box<Song> _songsBox;
  final Box<Album> _albumsBox;
  final Box<Artist> _artistsBox;
  final Box _settingsBox;

  // 缓存过期时间（24小时）
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const String _songListPrefix = 'song_list_cache';
  static const String _albumListPrefix = 'album_list_cache';
  static const String _artistListPrefix = 'artist_list_cache';

  MusicRepository({
    required SubsonicService subsonicService,
  })  : _subsonicService = subsonicService,
        _songsBox = Hive.box<Song>('songs'),
        _albumsBox = Hive.box<Album>('albums'),
        _artistsBox = Hive.box<Artist>('artists'),
        _settingsBox = Hive.box('settings');

  /// 获取随机歌曲（缓存优先）
  Future<List<Song>> getRandomSongs(
      {int size = 10, bool forceRefresh = false}) async {
    final cacheKey = _buildSongListCacheKey('random', size, 0);
    if (!forceRefresh) {
      final cachedSongs = _cachedSongs(cacheKey);
      if (cachedSongs.isNotEmpty && _isListCacheValid(cacheKey)) {
        return cachedSongs;
      }
    }

    final songs = await _subsonicService.getRandomSongs(size: size);
    if (songs.isNotEmpty) {
      for (var song in songs) {
        await _songsBox.put(song.id, song);
      }
      await _storeListCache(cacheKey, songs.map((song) => song.id).toList());
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
    final cacheKey = _buildAlbumListCacheKey(type, size, offset);
    if (!forceRefresh) {
      final cachedAlbums = _cachedAlbums(cacheKey);
      if (cachedAlbums.isNotEmpty && _isListCacheValid(cacheKey)) {
        return cachedAlbums;
      }
    }

    final albums = await _subsonicService.getAlbumList(
      type: type,
      size: size,
      offset: offset,
    );

    if (albums.isNotEmpty) {
      for (var album in albums) {
        await _albumsBox.put(album.id, album);
      }
      await _storeListCache(cacheKey, albums.map((album) => album.id).toList());
    }

    return albums;
  }

  /// 获取专辑详情（包含歌曲列表）
  Future<List<Song>> getAlbum(String albumId) async {
    return await _subsonicService.getAlbum(albumId);
  }

  /// 获取单曲详情
  Future<Song?> getSong(String songId) async {
    return await _subsonicService.getSong(songId);
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

  bool _isListCacheValid(String cacheKey) {
    final raw = _settingsBox.get('$cacheKey:time');
    if (raw is! String) return false;
    final time = DateTime.tryParse(raw);
    return _isCacheValid(time);
  }

  Future<void> _storeListCache(String cacheKey, List<String> ids) async {
    await _settingsBox.put('$cacheKey:ids', ids);
    await _settingsBox.put('$cacheKey:time', DateTime.now().toIso8601String());
  }

  List<String> _cachedIds(String cacheKey) {
    final raw = _settingsBox.get('$cacheKey:ids');
    if (raw is List) {
      return raw.map((id) => id.toString()).toList();
    }
    return const <String>[];
  }

  List<Song> _cachedSongs(String cacheKey) {
    return _cachedIds(cacheKey).map(_songsBox.get).whereType<Song>().toList();
  }

  List<Album> _cachedAlbums(String cacheKey) {
    return _cachedIds(cacheKey).map(_albumsBox.get).whereType<Album>().toList();
  }

  List<Artist> _cachedArtists(String cacheKey) {
    return _cachedIds(cacheKey)
        .map(_artistsBox.get)
        .whereType<Artist>()
        .toList();
  }

  String _buildSongListCacheKey(String type, int size, int offset) {
    return '$_songListPrefix:$type:$size:$offset';
  }

  String _buildAlbumListCacheKey(String type, int size, int offset) {
    return '$_albumListPrefix:$type:$size:$offset';
  }

  String _buildArtistListCacheKey(String type) {
    return '$_artistListPrefix:$type';
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    await _songsBox.clear();
    await _albumsBox.clear();
    await _artistsBox.clear();
    final cacheKeys = _settingsBox.keys
        .whereType<String>()
        .where((key) =>
            key.startsWith(_songListPrefix) ||
            key.startsWith(_albumListPrefix) ||
            key.startsWith(_artistListPrefix))
        .toList();
    for (final key in cacheKeys) {
      await _settingsBox.delete(key);
    }
  }

  /// 获取所有艺术家（缓存优先）
  Future<List<Artist>> getArtists({bool forceRefresh = false}) async {
    final cacheKey = _buildArtistListCacheKey('all');
    if (!forceRefresh) {
      final cachedArtists = _cachedArtists(cacheKey);
      if (cachedArtists.isNotEmpty && _isListCacheValid(cacheKey)) {
        return cachedArtists;
      }
    }

    final artists = await _subsonicService.getArtists();
    if (artists.isNotEmpty) {
      for (var artist in artists) {
        await _artistsBox.put(artist.id, artist);
      }
      await _storeListCache(
        cacheKey,
        artists.map((artist) => artist.id).toList(),
      );
    }

    return artists;
  }

  /// 获取艺术家详情（包含专辑列表）
  Future<Map<String, dynamic>?> getArtist(String artistId) async {
    return await _subsonicService.getArtist(artistId);
  }

  /// 获取艺术家专辑
  Future<List<Album>> getArtistAlbums(String artistId) async {
    final artistData = await getArtist(artistId);
    if (artistData == null) return <Album>[];

    final albums = <Album>[];
    final albumList = artistData['album'];
    if (albumList is List) {
      albums.addAll(
        albumList.map((json) => Album.fromJson((json as Map).cast())),
      );
    } else if (albumList is Map) {
      albums.add(Album.fromJson(albumList.cast<String, dynamic>()));
    }
    return albums;
  }

  /// 获取艺术家歌曲。
  ///
  /// 标准 Subsonic 没有统一的 getTracksByArtist2 接口，这里通过
  /// getArtist -> albums -> getAlbum 展开为可播放歌曲列表。
  Future<List<Song>> getArtistSongs(String artistId) async {
    final albums = await getArtistAlbums(artistId);
    final songs = <Song>[];
    final seen = <String>{};

    for (final album in albums) {
      final albumSongs = await _subsonicService.getAlbum(album.id);
      for (final song in albumSongs) {
        if (seen.add(song.id)) {
          songs.add(song);
        }
      }
    }

    return songs;
  }

  /// 获取音乐风格列表
  Future<List<Genre>> getGenres() async {
    return await _subsonicService.getGenres();
  }

  /// 按风格获取歌曲
  Future<List<Song>> getSongsByGenre(
    String genre, {
    int count = 100,
    int offset = 0,
  }) async {
    return await _subsonicService.getSongsByGenre(
      genre,
      count: count,
      offset: offset,
    );
  }

  /// 获取 Listener 歌曲库列表。
  ///
  /// 标准 Subsonic 没有直接的全量歌曲排序接口，这里通过专辑列表接口取一批
  /// 专辑后展开歌曲，保证 ListenerTrackLibrary 先具备真实可播放数据。
  Future<List<Song>> getSongLibrary({
    String sort = 'recently-added',
    int size = 100,
    int offset = 0,
  }) async {
    final albumType = switch (sort) {
      'recently-played' => 'recent',
      'most-played' => 'frequent',
      'a-z' => 'alphabeticalByName',
      _ => 'newest',
    };
    final targetSize = size + offset;
    final cacheKey = _buildSongListCacheKey('library:$sort', size, offset);
    final cachedSongs = _cachedSongs(cacheKey);
    if (cachedSongs.isNotEmpty && _isListCacheValid(cacheKey)) {
      return cachedSongs;
    }

    final albumCount = (targetSize / 8).ceil().clamp(12, 40);
    final albums = await getAlbumList(
      type: albumType,
      size: albumCount,
    );
    final songs = <Song>[];
    final seen = <String>{};

    for (final album in albums) {
      if (songs.length >= targetSize) break;
      final albumSongs = await _subsonicService.getAlbum(album.id);
      for (final song in albumSongs) {
        if (seen.add(song.id)) {
          songs.add(song);
        }
        if (songs.length >= targetSize) break;
      }
    }

    if (sort == 'a-z') {
      songs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    final page = songs.skip(offset).take(size).toList();
    if (page.isNotEmpty) {
      for (final song in page) {
        await _songsBox.put(song.id, song);
      }
      await _storeListCache(cacheKey, page.map((song) => song.id).toList());
    }

    return page;
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
