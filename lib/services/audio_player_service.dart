import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = -1;

  // Getters
  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  // 播放状态流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = songs;
    _currentIndex = initialIndex;
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song, String streamUrl) async {
    try {
      await _player.setUrl(streamUrl);
      await _player.play();
    } catch (e) {
      print('Play song error: $e');
    }
  }

  /// 播放当前播放列表中的歌曲
  Future<void> playAtIndex(int index, String Function(String) getStreamUrl) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final song = _playlist[index];
    final streamUrl = getStreamUrl(song.id);
    await playSong(song, streamUrl);
  }

  /// 播放/暂停
  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// 下一首
  Future<void> next(String Function(String) getStreamUrl) async {
    if (_currentIndex < _playlist.length - 1) {
      await playAtIndex(_currentIndex + 1, getStreamUrl);
    }
  }

  /// 上一首
  Future<void> previous(String Function(String) getStreamUrl) async {
    if (_currentIndex > 0) {
      await playAtIndex(_currentIndex - 1, getStreamUrl);
    }
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// 停止播放
  Future<void> stop() async {
    await _player.stop();
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
  }
}
