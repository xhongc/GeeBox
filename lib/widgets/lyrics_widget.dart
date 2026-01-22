import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lyrics_provider.dart';

/// 歌词显示组件
class LyricsWidget extends ConsumerWidget {
  final String? artist;
  final String? title;

  const LyricsWidget({
    super.key,
    required this.artist,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (artist == null || title == null) {
      return const Center(
        child: Text(
          '暂无歌词信息',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final lyrics = ref.watch(lyricsProvider({'artist': artist, 'title': title}));

    return lyrics.when(
      data: (lyricsText) {
        if (lyricsText == null || lyricsText.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lyrics_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  '暂无歌词',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              lyricsText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '加载歌词失败',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(lyricsProvider);
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
