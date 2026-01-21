import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/browse_screen.dart';
import '../screens/player_screen.dart';
import '../screens/server_config_screen.dart';

final router = GoRouter(
  initialLocation: '/config',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/browse',
      builder: (context, state) => const BrowseScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const PlayerScreen(),
    ),
    GoRoute(
      path: '/config',
      builder: (context, state) => const ServerConfigScreen(),
    ),
  ],
);
