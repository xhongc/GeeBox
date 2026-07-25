import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// 应用主题配置
class AppTheme {
  // 主题色选项
  static const List<Color> themeColors = [
    Color(0xFF1DB954), // Spotify 绿
    Color(0xFF31C27C), // QQ 音乐绿
    Color(0xFFFF6B6B), // 珊瑚红
    Color(0xFF4ECDC4), // 青色
    Color(0xFFFFBE0B), // 金黄色
    Color(0xFF8338EC), // 紫色
    Color(0xFF3A86FF), // 蓝色
    Color(0xFFFF006E), // 粉红色
  ];

  /// 获取 Forui 主题。Forui 当前使用预设设计令牌；Material 主题继续承接用户选择的强调色。
  static FThemeData foruiTheme({required bool isDark}) {
    final platformTheme = isDark ? FTheme.neutral.dark : FTheme.neutral.light;
    return platformTheme.touch;
  }

  /// 获取浅色主题
  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: seedColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: seedColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          );
        }),
      ),
    );
  }

  /// 获取深色主题
  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF1E1E1E),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: seedColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: seedColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          );
        }),
      ),
    );
  }
}
