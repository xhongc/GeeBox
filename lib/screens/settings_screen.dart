import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          const SliverAppBar(
            floating: true,
            title: Text(
              '设置',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 服务器设置
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '服务器',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('服务器配置'),
                  subtitle: const Text('配置 Subsonic 服务器'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 外观设置
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '外观',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('主题模式'),
                  subtitle: Text(_getThemeModeText(themeSettings.mode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeModeDialog(context, ref),
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('主题色'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeSettings.seedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showThemeColorDialog(context, ref),
                ),
              ],
            ),
          ),

          // 播放设置
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '播放',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.high_quality),
                  title: const Text('音质设置'),
                  subtitle: const Text('高品质'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('下载设置'),
                  subtitle: const Text('管理下载和缓存'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 关于
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '关于',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于 Chanson'),
                  subtitle: const Text('版本 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  String _getThemeModeText(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '浅色';
      case AppThemeMode.dark:
        return '深色';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.read(themeSettingsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppThemeMode>(
              title: const Text('浅色'),
              value: AppThemeMode.light,
              groupValue: themeSettings.mode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeSettingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('深色'),
              value: AppThemeMode.dark,
              groupValue: themeSettings.mode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeSettingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('跟随系统'),
              value: AppThemeMode.system,
              groupValue: themeSettings.mode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeSettingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.read(themeSettingsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: AppTheme.themeColors.length,
            itemBuilder: (context, index) {
              final color = AppTheme.themeColors[index];
              final isSelected = color.value == themeSettings.seedColor.value;

              return InkWell(
                onTap: () {
                  ref.read(themeSettingsProvider.notifier).setSeedColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
