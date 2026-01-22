import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subsonic_provider.dart';

/// 歌词 Provider（根据艺术家和歌曲名获取）
final lyricsProvider = FutureProvider.family.autoDispose<String?, Map<String, String?>>(
  (ref, params) async {
    final subsonicService = ref.watch(subsonicServiceProvider);
    return await subsonicService.getLyrics(
      artist: params['artist'],
      title: params['title'],
    );
  },
);
