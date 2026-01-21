import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../models/song.dart';
import '../models/album.dart';

class SubsonicService {
  final Dio _dio;
  late String _serverUrl;
  late String _username;
  late String _password;
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
  }

  /// 生成认证参数
  Map<String, dynamic> _getAuthParams() {
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
      print('Ping error: $e');
      return false;
    }
  }

  /// 获取随机歌曲
  Future<List<Song>> getRandomSongs({int size = 10}) async {
    try {
      final params = _getAuthParams();
      params['size'] = size.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/getRandomSongs',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['subsonic-response'];
        if (data['status'] == 'ok' && data['randomSongs'] != null) {
          final songs = data['randomSongs']['song'] as List;
          return songs.map((json) => Song.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get random songs error: $e');
      return [];
    }
  }

  /// 获取专辑列表
  Future<List<Album>> getAlbumList({
    String type = 'newest',
    int size = 20,
    int offset = 0,
  }) async {
    try {
      final params = _getAuthParams();
      params['type'] = type;
      params['size'] = size.toString();
      params['offset'] = offset.toString();

      final response = await _dio.get(
        '$_serverUrl/rest/getAlbumList2',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['subsonic-response'];
        if (data['status'] == 'ok' && data['albumList2'] != null) {
          final albums = data['albumList2']['album'] as List;
          return albums.map((json) => Album.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get album list error: $e');
      return [];
    }
  }

  /// 获取专辑详情（包含歌曲列表）
  Future<List<Song>> getAlbum(String albumId) async {
    try {
      final params = _getAuthParams();
      params['id'] = albumId;

      final response = await _dio.get(
        '$_serverUrl/rest/getAlbum',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['subsonic-response'];
        if (data['status'] == 'ok' && data['album'] != null) {
          final songs = data['album']['song'] as List;
          return songs.map((json) => Song.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get album error: $e');
      return [];
    }
  }

  /// 获取歌曲流媒体 URL
  String getStreamUrl(String songId) {
    final params = _getAuthParams();
    params['id'] = songId;

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$_serverUrl/rest/stream?$queryString';
  }

  /// 获取封面图片 URL
  String getCoverArtUrl(String coverArtId, {int size = 300}) {
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
    try {
      final params = _getAuthParams();
      params['query'] = query;

      final response = await _dio.get(
        '$_serverUrl/rest/search3',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data['subsonic-response'];
        if (data['status'] == 'ok' && data['searchResult3'] != null) {
          final result = data['searchResult3'];
          return {
            'songs': (result['song'] as List?)?.map((json) => Song.fromJson(json)).toList() ?? [],
            'albums': (result['album'] as List?)?.map((json) => Album.fromJson(json)).toList() ?? [],
          };
        }
      }
      return {'songs': [], 'albums': []};
    } catch (e) {
      print('Search error: $e');
      return {'songs': [], 'albums': []};
    }
  }
}
