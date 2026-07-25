import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'router/app_router.dart';
import 'models/song.dart';
import 'models/album.dart';
import 'models/artist.dart';
import 'models/search_history.dart';
import 'models/playlist.dart';
import 'providers/theme_provider.dart';
import 'providers/subsonic_provider.dart';
import 'services/subsonic_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await Hive.initFlutter();

  // 注册 Hive 适配器
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(AlbumAdapter());
  Hive.registerAdapter(ArtistAdapter());
  Hive.registerAdapter(SearchHistoryAdapter());
  Hive.registerAdapter(PlaylistAdapter());

  // 打开 Hive boxes
  await Hive.openBox<Song>('songs');
  await Hive.openBox<Album>('albums');
  await Hive.openBox<Artist>('artists');
  await Hive.openBox<SearchHistory>('search_history');
  await Hive.openBox<Playlist>('playlists');
  final settingsBox = await Hive.openBox('settings');

  // 初始化 Subsonic 服务配置（如果已有保存）
  final subsonicService = SubsonicService();
  final serverUrl = settingsBox.get('serverUrl', defaultValue: '') as String;
  final username = settingsBox.get('username', defaultValue: '') as String;
  final password = settingsBox.get('password', defaultValue: '') as String;
  if (serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
    subsonicService.configure(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        subsonicServiceProvider.overrideWithValue(subsonicService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);

    // 根据设置决定使用的主题模式
    final isDark = themeSettings.mode == AppThemeMode.dark ||
        (themeSettings.mode == AppThemeMode.system &&
            brightness == Brightness.dark);

    final foruiTheme = AppTheme.foruiTheme(isDark: isDark);
    final platform = (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)
        ? FPlatformVariant.iOS
        : FPlatformVariant.macOS;

    return MaterialApp.router(
      title: 'Chanson',
      theme: AppTheme.lightTheme(themeSettings.seedColor),
      darkTheme: AppTheme.darkTheme(themeSettings.seedColor),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => FTheme(
        data: foruiTheme,
        platform: platform,
        child: FToaster(
          child: FTooltipGroup(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
