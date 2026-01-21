import 'package:go_router/go_router.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/server_config_screen.dart';

final router = GoRouter(
  initialLocation: '/config',
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
