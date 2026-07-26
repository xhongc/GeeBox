import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/lyrics_provider.dart';
import 'listener_components.dart';

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
          style: TextStyle(color: ListenerColors.muted),
        ),
      );
    }

    final lyrics =
        ref.watch(lyricsProvider(LyricsQuery(artist: artist, title: title)));

    return lyrics.when(
      data: (lyricsText) {
        if (lyricsText == null || lyricsText.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FLucideIcons.fileMusic,
                  size: 64,
                  color: ListenerColors.muted,
                ),
                SizedBox(height: 16),
                Text(
                  '暂无歌词',
                  style: TextStyle(color: ListenerColors.muted),
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
                color: ListenerColors.foreground,
                fontSize: 16,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      loading: () => const Center(child: FCircularProgress()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FLucideIcons.triangleAlert,
              size: 64,
              color: ListenerColors.muted,
            ),
            const SizedBox(height: 16),
            const Text(
              '加载歌词失败',
              style: TextStyle(color: ListenerColors.muted),
            ),
            const SizedBox(height: 8),
            FButton(
              variant: FButtonVariant.ghost,
              onPress: () {
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
