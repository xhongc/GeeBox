import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../exceptions/subsonic_exceptions.dart';

class SubsonicService {
  final Dio _dio;
  String _serverUrl = '';
  String _username = '';
  String _password = '';
  bool _isConfigured = false;
  static const String _clientName = 'Chanson';
  static const String _apiVersion = '1.16.1';

  SubsonicService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// 配置服务器连接信息
  void configure({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    _serverUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    _username = username;
    _password = password;
    _isConfigured = true;
  }

  bool get isConfigured => _isConfigured;

  /// 确保已配置，否则抛出异常
  void _ensureConfigured() {
    if (!_isConfigured) {
      throw NotConfiguredException();
    }
  }

  /// 处理 Subsonic API 响应
  T _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (response.statusCode == 200) {
      final data = response.data['subsonic-response'];

      // 检查 API 返回状态
      if (data['status'] == 'failed') {
        final error = data['error'];
        final code = error['code'] as int;
        final message = error['message'] as String;

        // 认证错误
        if (code == 40 || code == 41) {
          throw AuthenticationException(message);
        }

        throw ServerException(code, message);
      }

      if (data['status'] == 'ok') {
        return parser(data);
      }
    }

    throw ServerException(
      response.statusCode ?? 500,
      'Unexpected response: ${response.statusCode}',
    );
  }

  /// 处理 Dio 异常
  Never _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      throw NetworkException('连接超时，请检查网络连接');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw NetworkException('接收数据超时');
    } else if (e.type == DioExceptionType.connectionError) {
      throw NetworkException('网络连接失败，请检查服务器地址');
    } else if (e.type == DioExceptionType.badResponse) {
      throw ServerException(
        e.response?.statusCode ?? 500,
        '服务器返回错误: ${e.response?.statusCode}',
      );
    }

    throw NetworkException('网络请求失败: ${e.message}');
  }

  /// 生成认证参数
  Map<String, dynamic> _getAuthParams() {
    _ensureConfigured();
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final token = md5.convert(utf8.encode(_password + salt)).toString();

    return {
      'u': _username,
      't': token,
      's': salt,
      'v': _apiVersion,
      'c': _clientName,
      'f': 'json',
    };
  }

  /// 测试服务器连接
  Future<bool> ping() async {
    if (!_isConfigured) return false;
    try {
      final response = await _dio.get(
        '$_serverUrl/rest/ping',
        queryParameters: _getAuthParams(),
      );

      if (response.statusCode == 200) {
        final data = response.data['subsonic-response'];
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Ping error: $e');
      return false;
    }
  }

  /// 获取随机歌曲
  Future<List<Song>> getRandomSongs({int size = 10}) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['size'] = size.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/getRandomSongs',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['randomSongs'] != null && data['randomSongs']['song'] != null) {
          final songs = data['randomSongs']['song'] as List;
          return songs.map((json) => Song.fromJson(json)).toList();
        }
        return <Song>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get random songs error: $e');
      throw ParseException('解析数据失败: $e');
    }
  }

  /// 获取专辑列表
  Future<List<Album>> getAlbumList({
    String type = 'newest',
    int size = 20,
    int offset = 0,
  }) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['type'] = type;
      params['size'] = size.toString();
      params['offset'] = offset.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/getAlbumList2',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['albumList2'] != null && data['albumList2']['album'] != null) {
          final albums = data['albumList2']['album'] as List;
          return albums.map((json) => Album.fromJson(json)).toList();
        }
        return <Album>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get album list error: $e');
      throw ParseException('解析专辑列表失败: $e');
    }
  }

  /// 获取专辑详情（包含歌曲列表）
  Future<List<Song>> getAlbum(String albumId) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['id'] = albumId;

      final response = await _dio.get(
        '$_serverUrl/rest/getAlbum',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['album'] != null && data['album']['song'] != null) {
          final songs = data['album']['song'] as List;
          return songs.map((json) => Song.fromJson(json)).toList();
        }
        return <Song>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get album error: $e');
      throw ParseException('解析专辑详情失败: $e');
    }
  }

  /// 获取歌曲流媒体 URL
  String getStreamUrl(String songId) {
    if (!_isConfigured) return '';
    final params = _getAuthParams();
    params['id'] = songId;

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$_serverUrl/rest/stream?$queryString';
  }

  /// 获取封面图片 URL
  String getCoverArtUrl(String coverArtId, {int size = 300}) {
    if (!_isConfigured) return '';
    final params = _getAuthParams();
    params['id'] = coverArtId;
    params['size'] = size.toString();

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$_serverUrl/rest/getCoverArt?$queryString';
  }

  /// 搜索
  Future<Map<String, dynamic>> search(String query) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['query'] = query;

      final response = await _dio.get(
        '$_serverUrl/rest/search3',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['searchResult3'] != null) {
          final result = data['searchResult3'];
          return {
            'songs': (result['song'] as List?)?.map((json) => Song.fromJson(json)).toList() ?? [],
            'albums': (result['album'] as List?)?.map((json) => Album.fromJson(json)).toList() ?? [],
          };
        }
        return {'songs': <Song>[], 'albums': <Album>[]};
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Search error: $e');
      throw ParseException('搜索失败: $e');
    }
  }

  // ==================== 播放列表相关 API ====================

  /// 获取所有播放列表
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();

      final response = await _dio.get(
        '$_serverUrl/rest/getPlaylists',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['playlists'] != null) {
          final playlists = data['playlists']['playlist'];
          if (playlists is List) {
            return playlists.cast<Map<String, dynamic>>();
          } else if (playlists is Map) {
            return [playlists.cast<String, dynamic>()];
          }
        }
        return <Map<String, dynamic>>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get playlists error: $e');
      throw ParseException('获取播放列表失败: $e');
    }
  }

  /// 获取播放列表详情（包含歌曲）
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['id'] = playlistId;

      final response = await _dio.get(
        '$_serverUrl/rest/getPlaylist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['playlist'] != null) {
          return data['playlist'];
        }
        return null;
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get playlist error: $e');
      throw ParseException('获取播放列表详情失败: $e');
    }
  }

  /// 创建播放列表
  Future<String?> createPlaylist({
    required String name,
    String? comment,
  }) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['name'] = name;
      if (comment != null && comment.isNotEmpty) {
        params['comment'] = comment;
      }

      final response = await _dio.get(
        '$_serverUrl/rest/createPlaylist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        // 1.14.0+ 版本会返回创建的播放列表
        if (data['playlist'] != null) {
          return data['playlist']['id'];
        }
        // 早期版本需要重新获取播放列表列表来找到新创建的
        return null;
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Create playlist error: $e');
      throw ParseException('创建播放列表失败: $e');
    }
  }

  /// 更新播放列表（修改名称和描述）
  Future<bool> updatePlaylistInfo({
    required String playlistId,
    String? name,
    String? comment,
  }) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['playlistId'] = playlistId;
      if (name != null) {
        params['name'] = name;
      }
      if (comment != null) {
        params['comment'] = comment;
      }

      final response = await _dio.get(
        '$_serverUrl/rest/updatePlaylist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Update playlist info error: $e');
      throw ParseException('更新播放列表信息失败: $e');
    }
  }

  /// 添加歌曲到播放列表
  Future<bool> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['playlistId'] = playlistId;
      params['songIdToAdd'] = songId;

      final response = await _dio.get(
        '$_serverUrl/rest/updatePlaylist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Add song to playlist error: $e');
      throw ParseException('添加歌曲到播放列表失败: $e');
    }
  }

  /// 从播放列表移除歌曲（通过索引）
  Future<bool> removeSongFromPlaylist({
    required String playlistId,
    required int songIndex,
  }) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['playlistId'] = playlistId;
      params['songIndexToRemove'] = songIndex.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/updatePlaylist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Remove song from playlist error: $e');
      throw ParseException('从播放列表移除歌曲失败: $e');
    }
  }

  /// 删除播放列表
  Future<bool> deletePlaylist(String playlistId) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['id'] = playlistId;

      final response = await _dio.get(
        '$_serverUrl/rest/deletePlaylist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Delete playlist error: $e');
      throw ParseException('删除播放列表失败: $e');
    }
  }

  // ==================== 艺术家相关 API ====================

  /// 获取所有艺术家（按字母索引）
  Future<List<Artist>> getArtists() async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();

      final response = await _dio.get(
        '$_serverUrl/rest/getArtists',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['artists'] != null) {
          final artists = <Artist>[];
          final indexes = data['artists']['index'];

          if (indexes is List) {
            for (final index in indexes) {
              if (index['artist'] != null) {
                final artistList = index['artist'];
                if (artistList is List) {
                  artists.addAll(artistList.map((json) => Artist.fromJson(json)));
                } else if (artistList is Map) {
                  artists.add(Artist.fromJson(artistList.cast<String, dynamic>()));
                }
              }
            }
          }
          return artists;
        }
        return <Artist>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get artists error: $e');
      throw ParseException('获取艺术家列表失败: $e');
    }
  }

  /// 获取艺术家详情（包含专辑列表）
  Future<Map<String, dynamic>?> getArtist(String artistId) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['id'] = artistId;

      final response = await _dio.get(
        '$_serverUrl/rest/getArtist',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['artist'] != null) {
          return data['artist'];
        }
        return null;
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get artist error: $e');
      throw ParseException('获取艺术家详情失败: $e');
    }
  }

  /// 收藏歌曲/专辑/艺术家
  Future<bool> star({String? id, String? albumId, String? artistId}) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      if (id != null) params['id'] = id;
      if (albumId != null) params['albumId'] = albumId;
      if (artistId != null) params['artistId'] = artistId;

      final response = await _dio.get(
        '$_serverUrl/rest/star',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Star error: $e');
      throw ParseException('收藏失败: $e');
    }
  }

  /// 取消收藏歌曲/专辑/艺术家
  Future<bool> unstar({String? id, String? albumId, String? artistId}) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      if (id != null) params['id'] = id;
      if (albumId != null) params['albumId'] = albumId;
      if (artistId != null) params['artistId'] = artistId;

      final response = await _dio.get(
        '$_serverUrl/rest/unstar',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Unstar error: $e');
      throw ParseException('取消收藏失败: $e');
    }
  }

  /// 获取收藏列表
  Future<List<Song>> getStarredSongs() async {
    _ensureConfigured();

    try {
      final response = await _dio.get(
        '$_serverUrl/rest/getStarred',
        queryParameters: _getAuthParams(),
      );

      return _handleResponse(response, (data) {
        if (data['starred'] != null) {
          final songs = data['starred']['song'] as List?;
          if (songs != null) {
            return songs.map((json) => Song.fromJson(json)).toList();
          }
        }
        return <Song>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get starred songs error: $e');
      throw ParseException('获取收藏列表失败: $e');
    }
  }

  /// 提交播放记录（scrobble）
  Future<bool> scrobble(String id, {int? time, bool submission = true}) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['id'] = id;
      if (time != null) params['time'] = time.toString();
      params['submission'] = submission.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/scrobble',
        queryParameters: params,
      );

      return _handleResponse(response, (data) => true);
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Scrobble error: $e');
      throw ParseException('提交播放记录失败: $e');
    }
  }

  /// 按类型获取歌曲（用于获取播放历史）
  Future<List<Song>> getSongsByGenre(
    String genre, {
    int count = 10,
    int offset = 0,
  }) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      params['genre'] = genre;
      params['count'] = count.toString();
      params['offset'] = offset.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/getSongsByGenre',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['songsByGenre'] != null) {
          final songs = data['songsByGenre']['song'] as List?;
          if (songs != null) {
            return songs.map((json) => Song.fromJson(json)).toList();
          }
        }
        return <Song>[];
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get songs by genre error: $e');
      throw ParseException('按类型获取歌曲失败: $e');
    }
  }

  /// 获取歌词
  Future<String?> getLyrics({String? artist, String? title}) async {
    _ensureConfigured();

    try {
      final params = _getAuthParams();
      if (artist != null) params['artist'] = artist;
      if (title != null) params['title'] = title;

      final response = await _dio.get(
        '$_serverUrl/rest/getLyrics',
        queryParameters: params,
      );

      return _handleResponse(response, (data) {
        if (data['lyrics'] != null) {
          // 歌词内容在 lyrics 节点的文本中
          final lyrics = data['lyrics'];
          if (lyrics is Map && lyrics['value'] != null) {
            return lyrics['value'] as String;
          } else if (lyrics is String) {
            return lyrics;
          }
        }
        return null;
      });
    } on DioException catch (e) {
      _handleDioException(e);
    } on SubsonicException {
      rethrow;
    } catch (e) {
      debugPrint('Get lyrics error: $e');
      throw ParseException('获取歌词失败: $e');
    }
  }
}
