import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/song.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/listener_components.dart';

class GroupCastScreen extends ConsumerStatefulWidget {
  const GroupCastScreen({super.key});

  @override
  ConsumerState<GroupCastScreen> createState() => _GroupCastScreenState();
}

class _GroupCastScreenState extends ConsumerState<GroupCastScreen> {
  String? _roomId;
  bool _membersCollapsed = false;
  final _roomController = TextEditingController();
  final _chatController = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _roomController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue =
        ref.watch(currentPlaylistProvider).valueOrNull ?? const <Song>[];
    final currentSong = ref.watch(currentSongProvider).valueOrNull;

    return FScaffold(
      childPad: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: ListenerGradients.shell),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _TopBar(
                      roomId: _roomId,
                      onBack: () => Navigator.of(context).pop(),
                      onNowPlaying: () => context.push('/play-queue'),
                    ),
                    const SizedBox(height: 18),
                    _SummaryCard(
                      roomId: _roomId,
                      onlineCount: _roomId == null ? 0 : 1,
                      onCreate: _createRoom,
                      onLeave: _leaveRoom,
                    ),
                    const SizedBox(height: 16),
                    _JoinCard(
                      controller: _roomController,
                      roomId: _roomId,
                      onJoin: _joinRoom,
                    ),
                    const SizedBox(height: 26),
                    _MembersSection(
                      roomId: _roomId,
                      collapsed: _membersCollapsed,
                      onToggle: () {
                        setState(() => _membersCollapsed = !_membersCollapsed);
                      },
                    ),
                    const SizedBox(height: 26),
                    _QueueSection(
                      queue: queue,
                      currentSong: currentSong,
                      onNowPlaying: () => context.push('/play-queue'),
                    ),
                    const SizedBox(height: 26),
                    _LyricsSection(currentSong: currentSong),
                    const SizedBox(height: 26),
                    _ChatSection(
                      enabled: _roomId != null,
                      messages: _messages,
                      controller: _chatController,
                      onSend: _sendChat,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createRoom() {
    setState(() {
      _roomId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      _messages
        ..clear()
        ..add('系统：已创建本机同步房间 $_roomId');
    });
  }

  void _joinRoom() {
    final value = _roomController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _roomId = value;
      _messages
        ..clear()
        ..add('系统：已加入本机同步房间 $value');
    });
  }

  void _leaveRoom() {
    setState(() {
      if (_roomId != null) {
        _messages.add('系统：已离开房间 $_roomId');
      }
      _roomId = null;
    });
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty || _roomId == null) return;
    setState(() {
      _messages.add('我：$text');
      _chatController.clear();
    });
  }
}

class _TopBar extends StatelessWidget {
  final String? roomId;
  final VoidCallback onBack;
  final VoidCallback onNowPlaying;

  const _TopBar({
    required this.roomId,
    required this.onBack,
    required this.onNowPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ListenerCircleButton(icon: FLucideIcons.chevronLeft, onPress: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '同步播放',
                style: TextStyle(
                  color: ListenerColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                roomId == null ? '让多台设备一起进入同一份节奏' : '房间 $roomId · 在线 1 人',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ListenerColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ListenerCircleButton(
            icon: FLucideIcons.panelTop, onPress: onNowPlaying),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String? roomId;
  final int onlineCount;
  final VoidCallback onCreate;
  final VoidCallback onLeave;

  const _SummaryCard({
    required this.roomId,
    required this.onlineCount,
    required this.onCreate,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(27),
        boxShadow: ListenerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '多端同播',
            style: TextStyle(
              color: ListenerColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roomId == null ? '把这一刻的音乐分享给更多设备' : '房间 $roomId 正在同步播放',
            style: const TextStyle(
              color: ListenerColors.foreground,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            roomId == null
                ? '当前版本提供本机同步面板；接入同步后端后可扩展为多端房间。'
                : '在线 $onlineCount 人，本机控制播放、进度和切歌。',
            style: const TextStyle(
              color: ListenerColors.softText,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: onCreate,
                  child: const Text('创建房间'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: roomId == null ? null : onLeave,
                  child: const Text('离开房间'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  final TextEditingController controller;
  final String? roomId;
  final VoidCallback onJoin;

  const _JoinCard({
    required this.controller,
    required this.roomId,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        boxShadow: ListenerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '加入现有房间',
            style: TextStyle(
              color: ListenerColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(controller: controller),
                  hint: '输入房间号',
                  enabled: roomId == null,
                ),
              ),
              const SizedBox(width: 10),
              FButton(
                onPress: roomId == null ? onJoin : null,
                child: const Text('加入'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final String? roomId;
  final bool collapsed;
  final VoidCallback onToggle;

  const _MembersSection({
    required this.roomId,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '房间成员',
      action: roomId == null ? null : (collapsed ? '展开' : '收起'),
      onAction: roomId == null ? null : onToggle,
      child: roomId == null
          ? const _EmptyInline(label: '暂无成员')
          : collapsed
              ? const _CompactMember()
              : const _MemberRow(),
    );
  }
}

class _CompactMember extends StatelessWidget {
  const _CompactMember();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '在线 1 人 · 房主: 我',
      style: TextStyle(color: ListenerColors.softText, fontSize: 13),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        boxShadow: ListenerShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              ),
            ),
            child: const Text(
              '我',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我',
                  style: TextStyle(
                    color: ListenerColors.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '房主',
                  style: TextStyle(color: ListenerColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            '我',
            style: TextStyle(
              color: ListenerColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueSection extends StatelessWidget {
  final List<Song> queue;
  final Song? currentSong;
  final VoidCallback onNowPlaying;

  const _QueueSection({
    required this.queue,
    required this.currentSong,
    required this.onNowPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '同步列表',
      action: '当前播放',
      onAction: onNowPlaying,
      child: queue.isEmpty
          ? const _EmptyInline(label: '暂无队列')
          : Column(
              children: [
                for (final song in queue.take(8))
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: song.id == currentSong?.id
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          song.id == currentSong?.id
                              ? FLucideIcons.audioLines
                              : FLucideIcons.music,
                          color: ListenerColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ListenerColors.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LyricsSection extends StatelessWidget {
  final Song? currentSong;

  const _LyricsSection({required this.currentSong});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '滚动歌词',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          currentSong == null ? '暂无歌词' : '正在播放：${currentSong!.title}',
          style: const TextStyle(color: ListenerColors.softText, fontSize: 13),
        ),
      ),
    );
  }
}

class _ChatSection extends StatelessWidget {
  final bool enabled;
  final List<String> messages;
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatSection({
    required this.enabled,
    required this.messages,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '房间聊天',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(22),
            ),
            child: messages.isEmpty
                ? const Text(
                    '暂无消息',
                    style: TextStyle(color: ListenerColors.muted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final message in messages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: ListenerColors.softText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(controller: controller),
                  hint: '输入消息',
                  enabled: enabled,
                ),
              ),
              const SizedBox(width: 10),
              FButton(
                onPress: enabled ? onSend : null,
                child: const Text('发送'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListenerSectionHeader(
          title: title,
          actionLabel: action,
          onAction: onAction,
        ),
        child,
      ],
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String label;

  const _EmptyInline({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 110,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: const TextStyle(color: ListenerColors.muted),
      ),
    );
  }
}
