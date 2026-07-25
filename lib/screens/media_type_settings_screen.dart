import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../providers/media_type_settings_provider.dart';
import '../widgets/forui_components.dart';

class MediaTypeSettingsScreen extends ConsumerWidget {
  const MediaTypeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(mediaTypeSettingsProvider);
    final notifier = ref.read(mediaTypeSettingsProvider.notifier);
    final theme = context.theme;

    return ChansonScaffold(
      title: '媒体类型',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Text(
              '至少选择一项要显示的内容类型。',
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          ChansonSection(
            title: '内容类型',
            children: [
              _MediaTypeTile(
                icon: FLucideIcons.music,
                title: '音乐',
                subtitle: '专辑、歌曲、艺术家',
                enabled: settings.musicEnabled,
                canDisable: settings.enabledCount > 1,
                onChanged: notifier.toggleMusic,
              ),
              _MediaTypeTile(
                icon: FLucideIcons.mic,
                title: '播客',
                subtitle: '订阅、单集、分类',
                enabled: settings.podcastEnabled,
                canDisable: settings.enabledCount > 1,
                onChanged: notifier.togglePodcast,
              ),
              _MediaTypeTile(
                icon: FLucideIcons.bookOpen,
                title: '有声书',
                subtitle: '小说、传记、自我提升',
                enabled: settings.audiobookEnabled,
                canDisable: settings.enabledCount > 1,
                onChanged: notifier.toggleAudiobook,
              ),
              _MediaTypeTile(
                icon: FLucideIcons.radio,
                title: '电台',
                subtitle: '心情、场景、流派',
                enabled: settings.radioEnabled,
                canDisable: settings.enabledCount > 1,
                onChanged: notifier.toggleRadio,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ChansonAlert(
            title: '显示范围',
            message: '关闭的内容类型将不会在首页、发现页面和音乐库中显示',
          ),
        ],
      ),
    );
  }
}

class _MediaTypeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool canDisable;
  final ValueChanged<bool> onChanged;

  const _MediaTypeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.canDisable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canChange = canDisable || !enabled;

    return FTile(
      prefix: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      suffix: FSwitch(
        value: enabled,
        enabled: canChange,
        onChange: canChange ? onChanged : null,
      ),
      onPress: canChange ? () => onChanged(!enabled) : null,
    );
  }
}
