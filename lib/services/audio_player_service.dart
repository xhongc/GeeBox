import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
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
  Song? _currentSong; // 独立维护当前歌曲

  // Scrobble 相关
  bool _hasScrobbled = false;
  StreamSubscription? _positionSubscription;
  Function(String)? _onScrobble;

  // Getters
  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  Song? get currentSong => _currentSong;

  // 播放状态流
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  // 当前歌曲流 - 用于通知 UI 更新
  final _currentSongController = StreamController<Song?>.broadcast();
  Stream<Song?> get currentSongStream {
    // 创建一个新的 stream，在订阅时立即发送当前值
    return Stream.multi((controller) {
      // 立即发送当前值
      controller.add(_currentSong);
      // 然后监听后续的变化
      final subscription = _currentSongController.stream.listen(
        (song) => controller.add(song),
        onError: (error) => controller.addError(error),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

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
      // 更新当前歌曲
      _currentSong = song;

      // 重置 scrobble 标记
      _hasScrobbled = false;

      // 取消之前的监听
      _positionSubscription?.cancel();

      await _player.setUrl(streamUrl);
      await _player.play();

      // 通知当前歌曲变化
      _currentSongController.add(song);

      // 监听播放进度，30秒后提交 scrobble
      _positionSubscription = _player.positionStream.listen((position) {
        if (position.inSeconds >= 30 && !_hasScrobbled && _onScrobble != null) {
          _onScrobble!(song.id);
          _hasScrobbled = true;
        }
      });
    } catch (e) {
      debugPrint('Play song error: $e');
    }
  }

  /// 播放当前播放列表中的歌曲
  Future<void> playAtIndex(int index, String Function(String) getStreamUrl) async {
    if (index < 0 || index >= _playlist.length) return;

    _currentIndex = index;
    final song = _playlist[index];
    final streamUrl = getStreamUrl(song.id);
    await playSong(song, streamUrl);

    // 通知当前歌曲变化（playSong 中已经发送，这里是为了确保）
    _currentSongController.add(song);
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
    _currentSong = null;
    _currentSongController.add(null);
  }

  /// 释放资源
  Future<void> dispose() async {
    _positionSubscription?.cancel();
    await _currentSongController.close();
    await _player.dispose();
  }

  /// 添加歌曲到队列末尾
  void addToQueue(Song song) {
    _playlist.add(song);
  }

  /// 添加多首歌曲到队列
  void addAllToQueue(List<Song> songs) {
    _playlist.addAll(songs);
  }

  /// 从队列中移除指定索引的歌曲
  void removeFromQueue(int index) {
    if (index < 0 || index >= _playlist.length) return;

    // 如果删除的是当前播放的歌曲之前的歌曲，需要调整当前索引
    if (index < _currentIndex) {
      _currentIndex--;
    }
    // 如果删除的是当前播放的歌曲，停止播放
    else if (index == _currentIndex) {
      stop();
      _currentIndex = -1;
    }

    _playlist.removeAt(index);
  }

  /// 清空播放队列
  void clearQueue() {
    stop();
    _playlist.clear();
    _currentIndex = -1;
    _currentSong = null;
    _currentSongController.add(null);
  }

  /// 移动队列中的歌曲位置
  void moveInQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0 || newIndex >= _playlist.length) return;

    final song = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, song);

    // 调整当前播放索引
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
  }
}
