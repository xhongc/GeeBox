import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../models/song.dart';
import 'subsonic_provider.dart';

// 音频播放器服务单例 Provider
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  final subsonic = ref.watch(subsonicServiceProvider);
  service
    ..bindStreamUrlBuilder(subsonic.getStreamUrl)
    ..bindCoverArtUrlBuilder(subsonic.getCoverArtUrl);
  return service;
});

// 当前播放歌曲 Provider - 从 AudioPlayerService 的 stream 获取
final currentSongProvider = StreamProvider<Song?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentSongStream;
});

// 播放状态 Provider
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playerStateStream;
});

// 播放位置 Provider
final positionProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.positionStream;
});

// 播放时长 Provider
final durationProvider = StreamProvider<Duration?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.durationStream;
});

// 当前播放队列 Provider
final currentPlaylistProvider = StreamProvider<List<Song>>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playlistStream;
});

// 当前播放索引 Provider
final currentIndexProvider = StreamProvider<int>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.currentIndexStream;
});

// 播放模式 Provider
final playModeProvider = StreamProvider<PlayMode>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playModeStream;
});

// 播放错误 Provider
final playbackErrorProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.playbackErrorStream;
});
