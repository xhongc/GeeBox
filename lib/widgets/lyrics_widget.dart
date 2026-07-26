import 'dart:async';
import 'dart:ui';

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
  final ValueChanged<Duration>? onSeek;

  const LyricsWidget({
    super.key,
    required this.artist,
    required this.title,
    this.position = Duration.zero,
    this.onSeek,
  });

  @override
  ConsumerState<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends ConsumerState<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _lineKeys = [];
  int _lastActiveIndex = -1;
  bool _isUserScrolling = false;
  bool _isAutoScrolling = false;
  Timer? _releaseAutoScrollTimer;

  @override
  void didUpdateWidget(covariant LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.artist != widget.artist) {
      _lastActiveIndex = -1;
      _isUserScrolling = false;
      _isAutoScrolling = false;
      _releaseAutoScrollTimer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _releaseAutoScrollTimer?.cancel();
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

        _syncLineKeys(parsed.length);
        final activeIndex = _activeLyricIndex(parsed, widget.position);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActive(activeIndex);
        });

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _handleScrollNotification(notification, parsed);
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: _lyricsVerticalPadding,
            ),
            itemCount: parsed.length,
            itemBuilder: (context, index) {
              final lineKey = _lineKeys[index];
              final isActive = index == activeIndex;
              final distance = (index - activeIndex).abs();
              final isAfterActive = index > activeIndex;
              final opacity = switch (distance) {
                0 => 1.0,
                1 => isAfterActive ? 0.74 : 0.42,
                2 => isAfterActive ? 0.52 : 0.22,
                _ => 0.16,
              };
              final blur = switch (distance) {
                0 => 0.0,
                1 => isAfterActive ? 0.35 : 1.2,
                2 => isAfterActive ? 0.8 : 1.8,
                _ => 2.2,
              };
              final scale = switch (distance) {
                0 => 1.12,
                1 => isAfterActive ? 1.06 : 0.96,
                2 => isAfterActive ? 1.01 : 0.90,
                _ => isAfterActive ? 0.96 : 0.84,
              };
              final offsetY = switch (distance) {
                0 => 0.0,
                1 => isAfterActive ? 0.0 : -1.0,
                2 => isAfterActive ? 1.0 : -1.5,
                _ => isAfterActive ? 1.5 : -2.0,
              };

              return SizedBox(
                key: lineKey,
                height: _lyricsLineHeight,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    opacity: opacity,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      scale: scale,
                      child: Transform.translate(
                        offset: Offset(0, offsetY),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: blur,
                            sigmaY: blur,
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              color: isActive
                                  ? ListenerColors.foreground
                                  : ListenerColors.foreground.withValues(
                                      alpha: opacity,
                                    ),
                              fontSize: isActive ? 19 : 15,
                              height: 1.08,
                              fontWeight:
                                  isActive ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0,
                            ),
                            child: Text(
                              parsed[index].text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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

  void _syncLineKeys(int length) {
    if (_lineKeys.length == length) return;
    _lineKeys = List<GlobalKey>.generate(length, (_) => GlobalKey());
  }

  void _scrollToActive(int activeIndex) {
    if (!_scrollController.hasClients || activeIndex < 0) return;
    if (_isUserScrolling) return;
    if (activeIndex == _lastActiveIndex) return;
    if (activeIndex >= _lineKeys.length) return;
    final targetContext = _lineKeys[activeIndex].currentContext;
    if (targetContext == null) return;
    _lastActiveIndex = activeIndex;
    _isAutoScrolling = true;
    _releaseAutoScrollTimer?.cancel();
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    ).whenComplete(() {
      _releaseAutoScrollTimer?.cancel();
      _releaseAutoScrollTimer = Timer(const Duration(milliseconds: 80), () {
        _isAutoScrolling = false;
      });
    });
  }

  void _handleScrollNotification(
    ScrollNotification notification,
    List<_LyricLine> lines,
  ) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _isAutoScrolling = false;
      _isUserScrolling = true;
      return;
    }

    if (_isAutoScrolling) return;

    if (notification is ScrollEndNotification && _isUserScrolling) {
      _isUserScrolling = false;
      final centeredIndex = _centeredLyricIndex(lines.length);
      if (centeredIndex == null) return;
      _lastActiveIndex = centeredIndex;
      widget.onSeek?.call(lines[centeredIndex].time);
    }
  }

  int? _centeredLyricIndex(int lineCount) {
    if (!_scrollController.hasClients || lineCount == 0) return null;
    final position = _scrollController.position;
    final viewportCenter = position.pixels + position.viewportDimension / 2;
    final rawIndex =
        (viewportCenter - _lyricsVerticalPadding - _lyricsLineHeight / 2) /
            _lyricsLineHeight;
    return rawIndex.round().clamp(0, lineCount - 1);
  }
}

const double _lyricsLineHeight = 58;
const double _lyricsVerticalPadding = 120;

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
