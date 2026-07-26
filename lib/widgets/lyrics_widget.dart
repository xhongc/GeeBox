import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/lyrics_provider.dart';
import 'listener_components.dart';

/// 歌词显示组件
class LyricsWidget extends ConsumerStatefulWidget {
  final String? artist;
  final String? title;
  final Duration position;

  const LyricsWidget({
    super.key,
    required this.artist,
    required this.title,
    this.position = Duration.zero,
  });

  @override
  ConsumerState<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends ConsumerState<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.artist != widget.artist) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.artist == null || widget.title == null) {
      return const Center(
        child: Text(
          '暂无歌词信息',
          style: TextStyle(color: ListenerColors.muted),
        ),
      );
    }

    final lyrics = ref.watch(
      lyricsProvider(
        LyricsQuery(artist: widget.artist, title: widget.title),
      ),
    );

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

        final parsed = _parseLrc(lyricsText);
        if (parsed.isEmpty) {
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
        }

        final activeIndex = _activeLyricIndex(parsed, widget.position);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActive(activeIndex);
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
          itemCount: parsed.length,
          itemBuilder: (context, index) {
            final active = index == activeIndex;
            final distance = (index - activeIndex).abs();
            final opacity = active ? 1.0 : (distance == 1 ? 0.58 : 0.34);

            return AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: TextStyle(
                color: ListenerColors.foreground.withValues(alpha: opacity),
                fontSize: active ? 18 : 15,
                height: 1.55,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  parsed[index].text,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
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

  void _scrollToActive(int activeIndex) {
    if (!_scrollController.hasClients || activeIndex < 0) return;
    final viewport = _scrollController.position.viewportDimension;
    final target = (activeIndex * 43.0) - (viewport / 2) + 22;
    final clamped = target.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    if ((_scrollController.offset - clamped).abs() < 8) return;
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class _LyricLine {
  final Duration time;
  final String text;

  const _LyricLine({required this.time, required this.text});
}

List<_LyricLine> _parseLrc(String lyricsText) {
  final lines = <_LyricLine>[];
  final timePattern = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');

  for (final rawLine in lyricsText.split(RegExp(r'\r?\n'))) {
    final matches = timePattern.allMatches(rawLine).toList();
    if (matches.isEmpty) continue;

    final text = rawLine.replaceAll(timePattern, '').trim();
    if (text.isEmpty) continue;

    for (final match in matches) {
      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
      final fraction = match.group(3) ?? '0';
      final milliseconds = switch (fraction.length) {
        1 => (int.tryParse(fraction) ?? 0) * 100,
        2 => (int.tryParse(fraction) ?? 0) * 10,
        _ => int.tryParse(fraction.padRight(3, '0').substring(0, 3)) ?? 0,
      };

      lines.add(
        _LyricLine(
          time: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
          text: text,
        ),
      );
    }
  }

  lines.sort((a, b) => a.time.compareTo(b.time));
  return lines;
}

int _activeLyricIndex(List<_LyricLine> lines, Duration position) {
  var active = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].time <= position) {
      active = i;
    } else {
      break;
    }
  }
  return active;
}
