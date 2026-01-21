import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../services/audio_player_service.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playerStateProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final audioService = ref.watch(audioPlayerServiceProvider);
    final subsonicService = ref.watch(subsonicServiceProvider);
    final repository = ref.watch(musicRepositoryProvider);

    // 如果没有歌曲，返回空页面
    if (currentSong == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('暂无播放内容'),
        ),
      );
    }

    final isPlaying = playerState.value?.playing ?? false;
    final currentPosition = position.value ?? Duration.zero;
    final totalDuration = duration.value ?? Duration.zero;
    final progress = totalDuration.inSeconds > 0
        ? currentPosition.inSeconds / totalDuration.inSeconds
        : 0.0;
    final playMode = ref.watch(playModeProvider);

    // 模拟专辑颜色
    final albumColor = colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              albumColor.withOpacity(0.6),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 专辑封面
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // 封面图片
                          currentSong.coverArt != null
                              ? Image.network(
                                  repository.getCoverArtUrl(currentSong.coverArt!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                      child: const Center(
                                        child: Icon(
                                          Icons.music_note,
                                          size: 120,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.music_note,
                                      size: 120,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                          // 毛玻璃效果（可选）
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // 歌曲信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentSong.artist ?? '未知艺术家',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          iconSize: 28,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 进度条
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final newPosition = Duration(
                            seconds: (value * totalDuration.inSeconds).toInt(),
                          );
                          audioService.seek(newPosition);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(currentPosition),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            _formatDuration(totalDuration),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 控制按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        playMode == PlayMode.shuffle
                            ? Icons.shuffle_on_outlined
                            : Icons.shuffle,
                        color: playMode == PlayMode.shuffle
                            ? colorScheme.primary
                            : null,
                      ),
                      iconSize: 28,
                      onPressed: () {
                        if (playMode == PlayMode.shuffle) {
                          audioService.setPlayMode(PlayMode.sequence);
                          ref.read(playModeProvider.notifier).state = PlayMode.sequence;
                        } else {
                          audioService.setPlayMode(PlayMode.shuffle);
                          ref.read(playModeProvider.notifier).state = PlayMode.shuffle;
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 40,
                      onPressed: () {
                        audioService.previous((id) => subsonicService.getStreamUrl(id));
                      },
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 36,
                        ),
                        color: Colors.white,
                        onPressed: () {
                          audioService.playPause();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 40,
                      onPressed: () {
                        audioService.next((id) => subsonicService.getStreamUrl(id));
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        playMode == PlayMode.repeatOne
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: playMode == PlayMode.repeatOne
                            ? colorScheme.primary
                            : null,
                      ),
                      iconSize: 28,
                      onPressed: () {
                        if (playMode == PlayMode.repeatOne) {
                          audioService.setPlayMode(PlayMode.sequence);
                          ref.read(playModeProvider.notifier).state = PlayMode.sequence;
                        } else {
                          audioService.setPlayMode(PlayMode.repeatOne);
                          ref.read(playModeProvider.notifier).state = PlayMode.repeatOne;
                        }
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // 底部额外功能
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
