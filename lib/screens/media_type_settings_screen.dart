import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_type_settings_provider.dart';

class MediaTypeSettingsScreen extends ConsumerWidget {
  const MediaTypeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(mediaTypeSettingsProvider);
    final notifier = ref.read(mediaTypeSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体类型'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择要显示的内容类型',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '（至少选择一项）',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // 音乐
          _buildMediaTypeCard(
            context,
            icon: Icons.music_note,
            color: Colors.blue,
            title: '音乐',
            subtitle: '专辑、歌曲、艺术家',
            enabled: settings.musicEnabled,
            onChanged: (value) => notifier.toggleMusic(value),
            canDisable: settings.enabledCount > 1,
          ),

          // 播客
          _buildMediaTypeCard(
            context,
            icon: Icons.mic,
            color: Colors.purple,
            title: '播客',
            subtitle: '订阅、单集、分类',
            enabled: settings.podcastEnabled,
            onChanged: (value) => notifier.togglePodcast(value),
            canDisable: settings.enabledCount > 1,
          ),

          // 有声书
          _buildMediaTypeCard(
            context,
            icon: Icons.menu_book,
            color: Colors.orange,
            title: '有声书',
            subtitle: '小说、传记、自我提升',
            enabled: settings.audiobookEnabled,
            onChanged: (value) => notifier.toggleAudiobook(value),
            canDisable: settings.enabledCount > 1,
          ),

          // 电台
          _buildMediaTypeCard(
            context,
            icon: Icons.radio,
            color: Colors.green,
            title: '电台',
            subtitle: '心情、场景、流派',
            enabled: settings.radioEnabled,
            onChanged: (value) => notifier.toggleRadio(value),
            canDisable: settings.enabledCount > 1,
          ),

          // 提示信息
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '关闭的内容类型将不会在首页、发现页面和音乐库中显示',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
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

  Widget _buildMediaTypeCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required bool canDisable,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SwitchListTile(
        value: enabled,
        onChanged: canDisable || !enabled ? onChanged : null,
        secondary: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
