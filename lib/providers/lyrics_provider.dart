import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subsonic_provider.dart';

class LyricsQuery {
  final String? artist;
  final String? title;

  const LyricsQuery({required this.artist, required this.title});

  @override
  bool operator ==(Object other) {
    return other is LyricsQuery && other.artist == artist && other.title == title;
  }

  @override
  int get hashCode => Object.hash(artist, title);
}

/// 歌词 Provider（根据艺术家和歌曲名获取）
final lyricsProvider = FutureProvider.family.autoDispose<String?, LyricsQuery>(
  (ref, query) async {
    final subsonicService = ref.watch(subsonicServiceProvider);
    return await subsonicService.getLyrics(
      artist: query.artist,
      title: query.title,
    );
  },
);
