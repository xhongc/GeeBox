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
              Text('主题模式', style: style.titleTextStyle),
              const SizedBox(height: 16),
              _ThemeModeTile(
                title: '浅色',
                icon: FLucideIcons.sun,
                selected: themeSettings.mode == AppThemeMode.light,
                onPress: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(AppThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              _ThemeModeTile(
                title: '深色',
                icon: FLucideIcons.moon,
                selected: themeSettings.mode == AppThemeMode.dark,
                onPress: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(AppThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              _ThemeModeTile(
                title: '跟随系统',
                icon: FLucideIcons.monitorCog,
                selected: themeSettings.mode == AppThemeMode.system,
                onPress: () {
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setThemeMode(AppThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.read(themeSettingsProvider);

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
              Text('选择主题色', style: style.titleTextStyle),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: AppTheme.themeColors.length,
                itemBuilder: (context, index) {
                  final color = AppTheme.themeColors[index];
                  final isSelected =
                      color.toARGB32() == themeSettings.seedColor.toARGB32();

                  return FTappable(
                    onPress: () {
                      ref
                          .read(themeSettingsProvider.notifier)
                          .setSeedColor(color);
                      Navigator.pop(context);
                    },
                    builder: (context, variants, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? context.theme.colors.foreground
                              : context.theme.colors.border,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(FLucideIcons.check, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onPress;

  const _ThemeModeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FTile(
      prefix: Icon(icon),
      title: Text(title),
      suffix: selected
          ? Icon(
              FLucideIcons.check,
              color: context.theme.colors.primary,
            )
          : null,
      onPress: onPress,
    );
  }
}
