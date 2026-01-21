import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/play_history_service.dart';
import '../models/song.dart';
import 'subsonic_provider.dart';

/// 播放历史服务 Provider
final playHistoryServiceProvider = Provider<PlayHistoryService>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return PlayHistoryService(subsonicService);
});

/// 播放历史列表 Provider（自动刷新）
final recentlyPlayedProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  final service = ref.watch(playHistoryServiceProvider);
  return await service.getRecentlyPlayed(count: 50);
});
