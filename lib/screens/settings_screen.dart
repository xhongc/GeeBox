import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../providers/audio_player_provider.dart';
import '../providers/subsonic_provider.dart';
import '../services/audio_player_service.dart';
import '../widgets/forui_components.dart';
import '../widgets/listener_components.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsBox = Hive.box('settings');
    final username = settingsBox.get('username', defaultValue: '') as String;
    final serverUrl = settingsBox.get('serverUrl', defaultValue: '') as String;
    final playMode =
        ref.watch(playModeProvider).valueOrNull ?? PlayMode.sequence;

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
                    _AccountHero(
                      username: username,
                      serverUrl: serverUrl,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 26),
                    _LanguageSection(),
                    const SizedBox(height: 26),
                    _PlaybackSection(playMode: playMode),
                    const SizedBox(height: 26),
                    _ConnectionSection(
                      serverUrl: serverUrl,
                      onSwitchServer: () => _switchServer(context, ref),
                    ),
                    const SizedBox(height: 26),
                    _AccountActions(
                      onLogout: () => _confirmLogout(context, ref),
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

  Future<void> _switchServer(BuildContext context, WidgetRef ref) async {
    await _clearServerConfig(ref);
    if (!context.mounted) return;
    context.go('/config');
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    showFDialog(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('退出登录', style: style.titleTextStyle),
              const SizedBox(height: 8),
              Text(
                '将清除本地保存的服务器连接信息，并返回配置页面。',
                style: style.bodyTextStyle,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () async {
                      await _clearServerConfig(ref);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      context.go('/config');
                    },
                    child: const Text('退出'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearServerConfig(WidgetRef ref) async {
    final settingsBox = Hive.box('settings');
    await settingsBox.delete('serverUrl');
    await settingsBox.delete('username');
    await settingsBox.delete('password');
    await settingsBox.put('skip_config', false);
    ref.read(serverConfigProvider.notifier).state = null;
    await ref.read(audioPlayerServiceProvider).stop();
  }
}

class _AccountHero extends StatelessWidget {
  final String username;
  final String serverUrl;
  final VoidCallback onBack;

  const _AccountHero({
    required this.username,
    required this.serverUrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = username.trim().isEmpty ? '当前用户' : username.trim();
    final initial = displayName.characters.first.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenerCircleButton(
              icon: FLucideIcons.chevronLeft,
              onPress: onBack,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      color: ListenerColors.muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '个人配置',
                    style: TextStyle(
                      color: ListenerColors.foreground,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFFBFDBFE).withValues(alpha: 0.36),
                Colors.white.withValues(alpha: 0.86),
              ],
            ),
            borderRadius: BorderRadius.circular(27),
            boxShadow: ListenerShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ListenerColors.foreground,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: ListenerShadows.elevated,
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '听众',
                      style: TextStyle(
                        color: ListenerColors.softText,
                        fontSize: 13,
                      ),
                    ),
                    if (serverUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '服务器 · $serverUrl',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ListenerColors.softText,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _AccountSection(
      title: '语言',
      trailing: '简体中文',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _AccountPill(label: '简体中文', active: true, onPress: () {}),
          _AccountPill(
            label: '繁體中文',
            active: false,
            onPress: () => showChansonToast(context, '语言切换暂未开放'),
          ),
          _AccountPill(
            label: 'English',
            active: false,
            onPress: () => showChansonToast(context, '语言切换暂未开放'),
          ),
        ],
      ),
    );
  }
}

class _PlaybackSection extends ConsumerWidget {
  final PlayMode playMode;

  const _PlaybackSection({required this.playMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AccountSection(
      title: '播放偏好',
      trailing: '本地保存',
      child: Column(
        children: [
          _AccountSettingRow(
            title: '列表循环',
            subtitle: '播放结束后继续从队列中循环。',
            active: playMode == PlayMode.repeatOne,
            onPress: () {
              ref.read(audioPlayerServiceProvider).setPlayMode(
                    playMode == PlayMode.repeatOne
                        ? PlayMode.sequence
                        : PlayMode.repeatOne,
                  );
            },
          ),
          const SizedBox(height: 10),
          _AccountSettingRow(
            title: '随机播放',
            subtitle: '下一首按随机顺序选择。',
            active: playMode == PlayMode.shuffle,
            onPress: () {
              ref.read(audioPlayerServiceProvider).setPlayMode(
                    playMode == PlayMode.shuffle
                        ? PlayMode.sequence
                        : PlayMode.shuffle,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _ConnectionSection extends StatelessWidget {
  final String serverUrl;
  final VoidCallback onSwitchServer;

  const _ConnectionSection({
    required this.serverUrl,
    required this.onSwitchServer,
  });

  @override
  Widget build(BuildContext context) {
    return _AccountSection(
      title: '连接',
      trailing: '应用模式',
      child: _AccountActionRow(
        icon: FLucideIcons.serverCog,
        title: '切换服务器',
        subtitle: serverUrl.isEmpty ? '重新配置 Subsonic 服务器' : serverUrl,
        onPress: onSwitchServer,
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  final VoidCallback onLogout;

  const _AccountActions({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return _AccountSection(
      title: '账户',
      trailing: '安全',
      child: _AccountActionRow(
        icon: FLucideIcons.logOut,
        title: '退出登录',
        subtitle: '清除本地连接信息',
        danger: true,
        onPress: onLogout,
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  final String title;
  final String trailing;
  final Widget child;

  const _AccountSection({
    required this.title,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ListenerColors.foreground,
                fontSize: 25,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                color: ListenerColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _AccountPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPress;

  const _AccountPill({
    required this.label,
    required this.active,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? ListenerColors.foreground
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            boxShadow: ListenerShadows.soft,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : ListenerColors.softText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}

class _AccountSettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onPress;

  const _AccountSettingRow({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            boxShadow: ListenerShadows.soft,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ListenerColors.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ListenerColors.softText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _ListenerSwitch(active: active),
            ],
          ),
        );
      },
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback onPress;

  const _AccountActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPress,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : ListenerColors.foreground;

    return FTappable(
      onPress: onPress,
      builder: (context, states, child) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: danger
                ? const Color(0xFFFEE2E2).withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            boxShadow: ListenerShadows.soft,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ListenerColors.softText,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FLucideIcons.chevronRight,
                color: danger ? color : ListenerColors.muted,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListenerSwitch extends StatelessWidget {
  final bool active;

  const _ListenerSwitch({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 46,
      height: 27,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: active ? ListenerColors.foreground : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 21,
          height: 21,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
