import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'router/app_router.dart';
import 'models/song.dart';
import 'models/album.dart';
import 'models/artist.dart';
import 'models/search_history.dart';
import 'models/playlist.dart';
import 'providers/theme_provider.dart';
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
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);

    // 根据设置决定使用的主题模式
    final isDark = themeSettings.mode == AppThemeMode.dark ||
        (themeSettings.mode == AppThemeMode.system && brightness == Brightness.dark);

    return MaterialApp.router(
      title: 'Chanson',
      theme: AppTheme.lightTheme(themeSettings.seedColor),
      darkTheme: AppTheme.darkTheme(themeSettings.seedColor),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
