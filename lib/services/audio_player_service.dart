import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

/// 播放模式枚举
enum PlayMode {
  sequence,  // 顺序播放
  shuffle,   // 随机播放
  repeatOne, // 单曲循环
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequence;

  // Scrobble 相关
  bool _hasScrobbled = false;
  StreamSubscription? _positionSubscription;
  Function(String)? _onScrobble;

  // Getters
  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  // 播放状态流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 设置 scrobble 回调函数
  void setScrobbleCallback(Function(String) callback) {
    _onScrobble = callback;
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    _playMode = mode;

    // 根据播放模式设置 just_audio 的循环模式
    switch (mode) {
      case PlayMode.sequence:
        _player.setLoopMode(LoopMode.off);
        _player.setShuffleModeEnabled(false);
        break;
      case PlayMode.shuffle:
        _player.setLoopMode(LoopMode.off);
        _player.setShuffleModeEnabled(true);
        break;
      case PlayMode.repeatOne:
        _player.setLoopMode(LoopMode.one);
        _player.setShuffleModeEnabled(false);
        break;
    }
  }

  /// 切换播放模式
  PlayMode togglePlayMode() {
    switch (_playMode) {
      case PlayMode.sequence:
        setPlayMode(PlayMode.shuffle);
        return PlayMode.shuffle;
      case PlayMode.shuffle:
        setPlayMode(PlayMode.repeatOne);
        return PlayMode.repeatOne;
      case PlayMode.repeatOne:
        setPlayMode(PlayMode.sequence);
        return PlayMode.sequence;
    }
  }

  /// 设置播放列表
  Future<void> setPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    _playlist = songs;
    _currentIndex = initialIndex;
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song, String streamUrl) async {
    try {
      // 重置 scrobble 标记
      _hasScrobbled = false;

      // 取消之前的监听
      _positionSubscription?.cancel();

      await _player.setUrl(streamUrl);
      await _player.play();

      // 监听播放进度，30秒后提交 scrobble
      _positionSubscription = _player.positionStream.listen((position) {
        if (position.inSeconds >= 30 && !_hasScrobbled && _onScrobble != null) {
          _onScrobble!(song.id);
          _hasScrobbled = true;
        }
      });
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
    _positionSubscription?.cancel();
    await _player.dispose();
  }
}
