import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../providers/music_repository_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/play_history_provider.dart';
import '../providers/sleep_timer_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/lyrics_widget.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    // 设置 scrobble 回调
    final audioService = ref.read(audioPlayerServiceProvider);
    final playHistoryService = ref.read(playHistoryServiceProvider);
    audioService.setScrobbleCallback((songId) {
      playHistoryService.scrobble(songId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final audioService = ref.watch(audioPlayerServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final subsonicService = ref.watch(subsonicServiceProvider);
    final repository = ref.watch(musicRepositoryProvider);
    final currentSong = ref.watch(currentSongProvider).value;

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
    final playMode = ref.watch(playModeProvider).value ?? PlayMode.sequence;

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
            icon: const Icon(Icons.timer),
            onPressed: () {
              _showSleepTimerDialog(context);
            },
            tooltip: '睡眠定时器',
          ),
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
                        // 收藏按钮
                        Consumer(
                          builder: (context, ref, child) {
                            final isStarred = ref.watch(isSongStarredProvider(currentSong.id));

                            return isStarred.when(
                              data: (starred) => IconButton(
                                icon: Icon(
                                  starred ? Icons.favorite : Icons.favorite_border,
                                  color: starred ? Colors.red : null,
                                ),
                                iconSize: 28,
                                onPressed: () async {
                                  final service = ref.read(favoriteServiceProvider);
                                  final messenger = ScaffoldMessenger.of(context);
                                  if (starred) {
                                    await service.unstarSong(currentSong.id);
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('已取消收藏')),
                                    );
                                  } else {
                                    await service.starSong(currentSong.id);
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('已添加到我喜欢的音乐')),
                                    );
                                  }
                                  // 刷新收藏状态
                                  ref.invalidate(starredSongsProvider);
                                },
                              ),
                              loading: () => const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (_, __) => IconButton(
                                icon: const Icon(Icons.favorite_border),
                                iconSize: 28,
                                onPressed: () {},
                              ),
                            );
                          },
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
                      data: const SliderThemeData(
                        trackHeight: 3,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: RoundSliderOverlayShape(
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
                        } else {
                          audioService.setPlayMode(PlayMode.shuffle);
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
                        } else {
                          audioService.setPlayMode(PlayMode.repeatOne);
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
                      icon: const Icon(Icons.lyrics),
                      onPressed: () {
                        _showLyricsDialog(context, currentSong);
                      },
                      tooltip: '歌词',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      onPressed: () {
                        context.push('/play-queue');
                      },
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

  void _showLyricsDialog(BuildContext context, currentSong) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist ?? '未知艺术家',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: LyricsWidget(
                  artist: currentSong.artist,
                  title: currentSong.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final sleepTimerState = ref.watch(sleepTimerControllerProvider);
          final sleepTimerController = ref.read(sleepTimerControllerProvider.notifier);
          final isRunning = sleepTimerState.isRunning;

          return AlertDialog(
            title: const Text('睡眠定时器'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRunning) ...[
                  Text(
                    '定时器正在运行',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      sleepTimerController.cancel();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已取消睡眠定时器')),
                      );
                    },
                    child: const Text('取消定时器'),
                  ),
                  const SizedBox(height: 8),
                ],
                ListTile(
                  title: const Text('15 分钟'),
                  onTap: () => _setSleepTimer(context, const Duration(minutes: 15)),
                ),
                ListTile(
                  title: const Text('30 分钟'),
                  onTap: () => _setSleepTimer(context, const Duration(minutes: 30)),
                ),
                ListTile(
                  title: const Text('45 分钟'),
                  onTap: () => _setSleepTimer(context, const Duration(minutes: 45)),
                ),
                ListTile(
                  title: const Text('60 分钟'),
                  onTap: () => _setSleepTimer(context, const Duration(minutes: 60)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setSleepTimer(BuildContext context, Duration duration) {
    final sleepTimerController = ref.read(sleepTimerControllerProvider.notifier);
    final audioService = ref.read(audioPlayerServiceProvider);

    sleepTimerController.setTimer(duration, () {
      // 定时器结束时停止播放
      audioService.stop();
    });

    Navigator.pop(context);

    final minutes = duration.inMinutes;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已设置 $minutes 分钟后停止播放')),
    );
  }
}
