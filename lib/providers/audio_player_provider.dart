import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../models/song.dart';

// 音频播放器服务单例 Provider
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

// 当前播放歌曲 Provider
final currentSongProvider = StateProvider<Song?>((ref) => null);

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
final currentPlaylistProvider = StateProvider<List<Song>>((ref) => []);

// 当前播放索引 Provider
final currentIndexProvider = StateProvider<int>((ref) => -1);

// 播放模式 Provider
final playModeProvider = StateProvider<PlayMode>((ref) => PlayMode.sequence);
