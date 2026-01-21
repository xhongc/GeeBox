import 'subsonic_service.dart';
import '../models/song.dart';

/// 播放历史服务
class PlayHistoryService {
  final SubsonicService _subsonicService;

  PlayHistoryService(this._subsonicService);

  /// 提交播放记录（scrobble）
  Future<bool> scrobble(String songId) async {
    return await _subsonicService.scrobble(
      songId,
      time: DateTime.now().millisecondsSinceEpoch,
      submission: true,
    );
  }

  /// 获取播放历史（最近播放的歌曲）
  Future<List<Song>> getRecentlyPlayed({int count = 50}) async {
    return await _subsonicService.getSongsByGenre(
      'recently-played',
      count: count,
      offset: 0,
    );
  }
}
