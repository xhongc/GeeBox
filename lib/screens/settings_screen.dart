import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/forui_components.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);

    return ChansonScaffold(
      title: '设置',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
        children: [
          ChansonSection(
            title: '服务器',
            children: [
              ChansonTile(
                icon: FLucideIcons.serverCog,
                title: '服务器配置',
                subtitle: '配置 Subsonic 服务器',
                onPress: () => context.push('/config'),
              ),
            ],
          ),
          ChansonSection(
            title: '内容显示',
            children: [
              ChansonTile(
                icon: FLucideIcons.layoutDashboard,
                title: '媒体类型',
                subtitle: '选择要显示的内容类型',
                onPress: () => context.push('/media-type-settings'),
              ),
            ],
          ),
          ChansonSection(
            title: '外观',
            children: [
              ChansonTile(
                icon: FLucideIcons.sunMoon,
                title: '主题模式',
                subtitle: _getThemeModeText(themeSettings.mode),
                onPress: () => _showThemeModeDialog(context, ref),
              ),
              ChansonTile(
                icon: FLucideIcons.palette,
                title: '主题色',
                details: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: themeSettings.seedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.theme.colors.border,
                        ),
                      ),
                    ),
                  ],
                ),
                onPress: () => _showThemeColorDialog(context, ref),
              ),
            ],
          ),
          ChansonSection(
            title: '播放',
            children: [
              ChansonTile(
                icon: FLucideIcons.badgeCheck,
                title: '音质设置',
                subtitle: '高品质',
                onPress: () {},
              ),
              ChansonTile(
                icon: FLucideIcons.download,
                title: '下载设置',
                subtitle: '管理下载和缓存',
                onPress: () {},
              ),
            ],
          ),
          const ChansonSection(
            title: '关于',
            children: [
              ChansonTile(
                icon: FLucideIcons.info,
                title: '关于 Chanson',
                subtitle: '版本 1.0.0',
              ),
            ],
          ),
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
