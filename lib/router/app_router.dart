import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/server_config_screen.dart';

bool _canEnterApp() {
  final settingsBox = Hive.box('settings');
  final skipConfig = settingsBox.get('skip_config', defaultValue: false) as bool;
  if (skipConfig) return true;
  final serverUrl = settingsBox.get('serverUrl', defaultValue: '') as String;
  final username = settingsBox.get('username', defaultValue: '') as String;
  final password = settingsBox.get('password', defaultValue: '') as String;
  return serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final canEnterApp = _canEnterApp();
    final isConfigRoute = state.matchedLocation == '/config';
    if (!canEnterApp && !isConfigRoute) {
      return '/config';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/config',
      builder: (context, state) => const ServerConfigScreen(),
    ),
  ],
);
