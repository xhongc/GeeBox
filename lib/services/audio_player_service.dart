import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';

/// 播放模式枚举
enum PlayMode {
  sequence, // 顺序播放
  shuffle, // 随机播放
  repeatOne, // 单曲循环
}

abstract class AudioPlaybackBackend {
  bool get playing;
  Stream<PlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  Future<void> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> setShuffleModeEnabled(bool enabled);
  Future<void> dispose();
}

class JustAudioPlaybackBackend implements AudioPlaybackBackend {
  final AudioPlayer _player;

  JustAudioPlaybackBackend([AudioPlayer? player])
      : _player = player ?? AudioPlayer();

  AudioPlayer get player => _player;

  @override
  bool get playing => _player.playing;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> setUrl(String url) => _player.setUrl(url);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  @override
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  @override
  Future<void> dispose() => _player.dispose();
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() : _backend = JustAudioPlaybackBackend();
  @visibleForTesting
  AudioPlayerService.testing(AudioPlaybackBackend backend) : _backend = backend;

  final AudioPlaybackBackend _backend;
  List<Song> _playlist = [];
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequence;
  Song? _currentSong; // 独立维护当前歌曲
  String Function(String)? _streamUrlBuilder;
  Duration _lastPosition = Duration.zero;
  String? _playbackError;
  final List<int> _shuffleHistory = [];
  int _shuffleHistoryIndex = -1;

  // Scrobble 相关
  bool _hasScrobbled = false;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  Function(String)? _onScrobble;

  // Getters
  AudioPlaybackBackend get player => _backend;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;
  Song? get currentSong => _currentSong;

  // 播放状态流
  Stream<PlayerState> get playerStateStream => _backend.playerStateStream;
  Stream<Duration> get positionStream => _backend.positionStream;
  Stream<Duration?> get durationStream => _backend.durationStream;

  // 当前歌曲流 - 用于通知 UI 更新
  final _currentSongController = StreamController<Song?>.broadcast();
  final _playlistController = StreamController<List<Song>>.broadcast();
  final _currentIndexController = StreamController<int>.broadcast();
  final _playModeController = StreamController<PlayMode>.broadcast();
  final _playbackErrorController = StreamController<String?>.broadcast();
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

  Stream<List<Song>> get playlistStream {
    return Stream.multi((controller) {
      controller.add(List.unmodifiable(_playlist));
      final subscription = _playlistController.stream.listen(
        (playlist) => controller.add(List.unmodifiable(playlist)),
        onError: (error) => controller.addError(error),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  Stream<int> get currentIndexStream {
    return Stream.multi((controller) {
      controller.add(_currentIndex);
      final subscription = _currentIndexController.stream.listen(
        (index) => controller.add(index),
        onError: (error) => controller.addError(error),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  Stream<PlayMode> get playModeStream {
    return Stream.multi((controller) {
      controller.add(_playMode);
      final subscription = _playModeController.stream.listen(
        (mode) => controller.add(mode),
        onError: (error) => controller.addError(error),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  Stream<String?> get playbackErrorStream {
    return Stream.multi((controller) {
      controller.add(_playbackError);
      final subscription = _playbackErrorController.stream.listen(
        (error) => controller.add(error),
        onError: (error) => controller.addError(error),
      );
      controller.onCancel = () => subscription.cancel();
    });
  }

  void bindStreamUrlBuilder(String Function(String) getStreamUrl) {
    _streamUrlBuilder = getStreamUrl;
    _playerStateSubscription ??= _backend.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });
  }

  Future<void> _handlePlaybackCompleted() async {
    final getStreamUrl = _streamUrlBuilder;
    if (getStreamUrl == null || _playlist.isEmpty) return;

    switch (_playMode) {
      case PlayMode.repeatOne:
        await playAtIndex(_currentIndex, getStreamUrl);
        break;
      case PlayMode.shuffle:
        await _playRandomNext(getStreamUrl);
        break;
      case PlayMode.sequence:
        if (_currentIndex < _playlist.length - 1) {
          await playAtIndex(_currentIndex + 1, getStreamUrl);
        } else {
          await _backend.stop();
        }
        break;
    }
  }

  /// 设置 scrobble 回调函数
  void setScrobbleCallback(Function(String) callback) {
    _onScrobble = callback;
  }

  /// 设置播放模式
  void setPlayMode(PlayMode mode) {
    _playMode = mode;
    if (mode == PlayMode.shuffle &&
        _currentIndex >= 0 &&
        _shuffleHistory.isEmpty) {
      _shuffleHistory
        ..clear()
        ..add(_currentIndex);
      _shuffleHistoryIndex = 0;
    }
    _playModeController.add(_playMode);

    // 根据播放模式设置 just_audio 的循环模式
    switch (mode) {
      case PlayMode.sequence:
        _backend.setLoopMode(LoopMode.off);
        _backend.setShuffleModeEnabled(false);
        break;
      case PlayMode.shuffle:
        _backend.setLoopMode(LoopMode.off);
        _backend.setShuffleModeEnabled(true);
        break;
      case PlayMode.repeatOne:
        _backend.setLoopMode(LoopMode.one);
        _backend.setShuffleModeEnabled(false);
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
    _playlist = List<Song>.from(songs);
    _currentIndex = initialIndex;
    _shuffleHistory.clear();
    _shuffleHistoryIndex = -1;
    _playlistController.add(List.unmodifiable(_playlist));
    _currentIndexController.add(_currentIndex);
  }

  /// 播放指定歌曲
  Future<void> playSong(Song song, String streamUrl) async {
    try {
      await _startSong(song, streamUrl);
    } catch (e) {
      debugPrint('Play song error: $e');
      _setPlaybackError('播放失败，请检查服务器连接或稍后重试');
    }
  }

  Future<void> _startSong(Song song, String streamUrl) async {
    _setPlaybackError(null);
    // 更新当前歌曲
    _currentSong = song;

    // 立即通知当前歌曲变化，确保 UI 能立即响应
    _currentSongController.add(song);

    // 重置 scrobble 标记
    _hasScrobbled = false;

    // 取消之前的监听
    await _positionSubscription?.cancel();

    await _backend.setUrl(streamUrl);
    await _backend.play();

    // 监听播放进度，30秒后提交 scrobble
    _positionSubscription = _backend.positionStream.listen((position) {
      _lastPosition = position;
      if (position.inSeconds >= 30 && !_hasScrobbled && _onScrobble != null) {
        _onScrobble!(song.id);
        _hasScrobbled = true;
      }
    });
  }

  void _setPlaybackError(String? message) {
    _playbackError = message;
    _playbackErrorController.add(message);
  }

  /// 播放当前播放列表中的歌曲
  Future<void> playAtIndex(
    int index,
    String Function(String) getStreamUrl, {
    bool recordShuffleHistory = true,
    int failureSkipCount = 0,
  }) async {
    if (index < 0 || index >= _playlist.length) return;

    bindStreamUrlBuilder(getStreamUrl);
    _currentIndex = index;
    _currentIndexController.add(_currentIndex);
    if (_playMode == PlayMode.shuffle && recordShuffleHistory) {
      _recordShuffleIndex(index);
    }
    final song = _playlist[index];
    final streamUrl = getStreamUrl(song.id);
    try {
      await _startSong(song, streamUrl);
    } catch (e) {
      debugPrint('Play song error: $e');
      _setPlaybackError('播放失败，已跳过这首歌');
      await _skipFailedSong(getStreamUrl, failureSkipCount: failureSkipCount);
    }
  }

  /// 播放/暂停
  Future<void> playPause() async {
    if (_backend.playing) {
      await _backend.pause();
    } else {
      await _backend.play();
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    await _backend.pause();
  }

  /// 下一首
  Future<void> next(String Function(String) getStreamUrl) async {
    bindStreamUrlBuilder(getStreamUrl);
    if (_playlist.isEmpty) return;
    if (_playMode == PlayMode.shuffle) {
      await _playRandomNext(getStreamUrl);
      return;
    }
    if (_playMode == PlayMode.repeatOne && _currentIndex >= 0) {
      await playAtIndex(_currentIndex, getStreamUrl);
      return;
    }
    if (_currentIndex < _playlist.length - 1) {
      await playAtIndex(_currentIndex + 1, getStreamUrl);
    }
  }

  /// 上一首
  Future<void> previous(String Function(String) getStreamUrl) async {
    bindStreamUrlBuilder(getStreamUrl);
    if (_lastPosition.inSeconds >= 3 && _currentIndex >= 0) {
      await seek(Duration.zero);
      _lastPosition = Duration.zero;
      return;
    }
    if (_playMode == PlayMode.shuffle && _shuffleHistoryIndex > 0) {
      _shuffleHistoryIndex--;
      await playAtIndex(
        _shuffleHistory[_shuffleHistoryIndex],
        getStreamUrl,
        recordShuffleHistory: false,
      );
      return;
    }
    if (_currentIndex > 0) {
      await playAtIndex(_currentIndex - 1, getStreamUrl);
    }
  }

  Future<void> _playRandomNext(String Function(String) getStreamUrl) async {
    if (_playlist.isEmpty) return;
    if (_playlist.length == 1) {
      await playAtIndex(0, getStreamUrl, recordShuffleHistory: true);
      return;
    }

    if (_shuffleHistoryIndex >= 0 &&
        _shuffleHistoryIndex < _shuffleHistory.length - 1) {
      _shuffleHistoryIndex++;
      await playAtIndex(
        _shuffleHistory[_shuffleHistoryIndex],
        getStreamUrl,
        recordShuffleHistory: false,
      );
      return;
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    var nextIndex = now % _playlist.length;
    if (nextIndex == _currentIndex) {
      nextIndex = (nextIndex + 1) % _playlist.length;
    }
    await playAtIndex(nextIndex, getStreamUrl);
  }

  Future<void> _skipFailedSong(
    String Function(String) getStreamUrl, {
    required int failureSkipCount,
  }) async {
    await _backend.stop();
    if (_playlist.isEmpty || failureSkipCount >= _playlist.length - 1) {
      return;
    }

    await Future<void>.delayed(Duration.zero);

    if (_playMode == PlayMode.shuffle) {
      await _playRandomNextAfterFailure(
        getStreamUrl,
        failureSkipCount: failureSkipCount + 1,
      );
      return;
    }

    final nextIndex = _currentIndex + 1;
    if (nextIndex >= _playlist.length) {
      return;
    }
    await playAtIndex(
      nextIndex,
      getStreamUrl,
      failureSkipCount: failureSkipCount + 1,
    );
  }

  Future<void> _playRandomNextAfterFailure(
    String Function(String) getStreamUrl, {
    required int failureSkipCount,
  }) async {
    if (_playlist.length == 1) {
      await _backend.stop();
      return;
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    var nextIndex = now % _playlist.length;
    if (nextIndex == _currentIndex) {
      nextIndex = (nextIndex + 1) % _playlist.length;
    }
    await playAtIndex(
      nextIndex,
      getStreamUrl,
      failureSkipCount: failureSkipCount,
    );
  }

  void _recordShuffleIndex(int index) {
    if (_shuffleHistoryIndex >= 0 &&
        _shuffleHistory[_shuffleHistoryIndex] == index) {
      return;
    }
    if (_shuffleHistoryIndex < _shuffleHistory.length - 1) {
      _shuffleHistory.removeRange(
        _shuffleHistoryIndex + 1,
        _shuffleHistory.length,
      );
    }
    _shuffleHistory.add(index);
    _shuffleHistoryIndex = _shuffleHistory.length - 1;
  }

  /// 跳转到指定位置
  Future<void> seek(Duration position) async {
    await _backend.seek(position);
  }

  /// 停止播放
  Future<void> stop() async {
    await _backend.stop();
    _currentSong = null;
    _currentSongController.add(null);
  }

  /// 释放资源
  Future<void> dispose() async {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    await _currentSongController.close();
    await _playlistController.close();
    await _currentIndexController.close();
    await _playModeController.close();
    await _playbackErrorController.close();
    await _backend.dispose();
  }

  /// 添加歌曲到队列末尾
  void addToQueue(Song song) {
    _playlist.add(song);
    _playlistController.add(List.unmodifiable(_playlist));
  }

  /// 添加歌曲到当前歌曲之后
  void addNext(Song song) {
    final insertIndex = _currentIndex >= 0 && _currentIndex < _playlist.length
        ? _currentIndex + 1
        : _playlist.length;
    _playlist.insert(insertIndex, song);
    _playlistController.add(List.unmodifiable(_playlist));
  }

  /// 添加多首歌曲到队列
  void addAllToQueue(List<Song> songs) {
    _playlist.addAll(songs);
    _playlistController.add(List.unmodifiable(_playlist));
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
    _playlistController.add(List.unmodifiable(_playlist));
    _currentIndexController.add(_currentIndex);
  }

  /// 清空播放队列
  void clearQueue() {
    stop();
    _playlist.clear();
    _currentIndex = -1;
    _currentSong = null;
    _currentSongController.add(null);
    _playlistController.add(List.unmodifiable(_playlist));
    _currentIndexController.add(_currentIndex);
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

    _playlistController.add(List.unmodifiable(_playlist));
    _currentIndexController.add(_currentIndex);
  }
}
