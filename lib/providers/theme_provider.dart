import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,
  dark,
  system,
}

/// 主题设置状态
class ThemeSettings {
  final AppThemeMode mode;
  final Color seedColor;

  const ThemeSettings({
    required this.mode,
    required this.seedColor,
  });

  ThemeSettings copyWith({
    AppThemeMode? mode,
    Color? seedColor,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

/// 主题设置 Provider
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';

  ThemeSettingsNotifier()
      : super(const ThemeSettings(
          mode: AppThemeMode.system,
          seedColor: Color(0xFF1DB954), // 默认 Spotify 绿
        )) {
    _loadSettings();
  }

  /// 加载保存的设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载主题模式
    final modeIndex = prefs.getInt(_themeModeKey);
    final mode = modeIndex != null
        ? AppThemeMode.values[modeIndex]
        : AppThemeMode.system;

    // 加载主题色
    final colorValue = prefs.getInt(_seedColorKey);
    final seedColor =
        colorValue != null ? Color(colorValue) : const Color(0xFF1DB954);

    state = ThemeSettings(mode: mode, seedColor: seedColor);
  }

  /// 设置主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  /// 设置主题色
  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }
}

/// 主题设置 Provider
final themeSettingsProvider =
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});
