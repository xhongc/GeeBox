import 'subsonic_service.dart';
import '../models/song.dart';

/// 收藏服务
class FavoriteService {
  final SubsonicService _subsonicService;

  FavoriteService(this._subsonicService);

  /// 收藏歌曲
  Future<bool> starSong(String songId) async {
    return await _subsonicService.star(id: songId);
  }

  /// 取消收藏歌曲
  Future<bool> unstarSong(String songId) async {
    return await _subsonicService.unstar(id: songId);
  }

  /// 获取收藏的歌曲列表
  Future<List<Song>> getStarredSongs() async {
    return await _subsonicService.getStarredSongs();
  }

  /// 收藏专辑
  Future<bool> starAlbum(String albumId) async {
    return await _subsonicService.star(albumId: albumId);
  }

  /// 取消收藏专辑
  Future<bool> unstarAlbum(String albumId) async {
    return await _subsonicService.unstar(albumId: albumId);
  }

  /// 收藏艺术家
  Future<bool> starArtist(String artistId) async {
    return await _subsonicService.star(artistId: artistId);
  }

  /// 取消收藏艺术家
  Future<bool> unstarArtist(String artistId) async {
    return await _subsonicService.unstar(artistId: artistId);
  }
}
