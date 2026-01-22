import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/server_config_screen.dart';
import '../screens/album_detail_screen.dart';
import '../screens/artist_detail_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/albums_screen.dart';
import '../screens/artists_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/play_history_screen.dart';
import '../screens/play_queue_screen.dart';
import '../screens/playlist_management_screen.dart';
import '../screens/search_screen.dart';
import '../screens/media_type_settings_screen.dart';

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
    GoRoute(
      path: '/album-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AlbumDetailScreen(
          albumId: extra['albumId'] as String,
          albumName: extra['albumName'] as String,
          albumArtist: extra['albumArtist'] as String?,
          coverArtId: extra['coverArtId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/artist-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ArtistDetailScreen(
          artistId: extra['artistId'] as String,
          artistName: extra['artistName'] as String,
          coverArtId: extra['coverArtId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/playlist-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PlaylistDetailScreen(
          playlistId: extra['playlistId'] as String,
        );
      },
    ),
    GoRoute(
      path: '/albums',
      builder: (context, state) => const AlbumsScreen(),
    ),
    GoRoute(
      path: '/artists',
      builder: (context, state) => const ArtistsScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/play-history',
      builder: (context, state) => const PlayHistoryScreen(),
    ),
    GoRoute(
      path: '/play-queue',
      builder: (context, state) => const PlayQueueScreen(),
    ),
    GoRoute(
      path: '/playlist-management',
      builder: (context, state) => const PlaylistManagementScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/media-type-settings',
      builder: (context, state) => const MediaTypeSettingsScreen(),
    ),
  ],
);
