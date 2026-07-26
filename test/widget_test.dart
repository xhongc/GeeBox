import 'dart:async';
import 'dart:io';

import 'package:chanson/main.dart';
import 'package:chanson/models/album.dart';
import 'package:chanson/models/artist.dart';
import 'package:chanson/models/genre.dart';
import 'package:chanson/models/playlist.dart';
import 'package:chanson/models/search_history.dart';
import 'package:chanson/models/song.dart';
import 'package:chanson/models/starred_items.dart';
import 'package:chanson/providers/audio_player_provider.dart';
import 'package:chanson/providers/favorite_provider.dart';
import 'package:chanson/providers/music_repository_provider.dart';
import 'package:chanson/providers/playlist_provider.dart';
import 'package:chanson/providers/search_provider.dart';
import 'package:chanson/providers/subsonic_provider.dart';
import 'package:chanson/screens/album_detail_screen.dart';
import 'package:chanson/screens/albums_screen.dart';
import 'package:chanson/screens/artist_detail_screen.dart';
import 'package:chanson/screens/artist_tracks_screen.dart';
import 'package:chanson/screens/artists_screen.dart';
import 'package:chanson/screens/favorites_screen.dart';
import 'package:chanson/screens/genre_detail_screen.dart';
import 'package:chanson/screens/genres_screen.dart';
import 'package:chanson/screens/group_cast_screen.dart';
import 'package:chanson/screens/home_screen.dart';
import 'package:chanson/screens/play_queue_screen.dart';
import 'package:chanson/screens/player_screen.dart';
import 'package:chanson/screens/playlist_detail_screen.dart';
import 'package:chanson/screens/playlist_management_screen.dart';
import 'package:chanson/screens/search_screen.dart';
import 'package:chanson/screens/settings_screen.dart';
import 'package:chanson/screens/songs_screen.dart';
import 'package:chanson/services/audio_player_service.dart';
import 'package:chanson/services/search_service.dart';
import 'package:chanson/services/subsonic_service.dart';
import 'package:chanson/theme/app_theme.dart';
import 'package:chanson/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  late Directory tempDir;
  late _FakeSubsonicService subsonicService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('chanson_test_');
    Hive.init(tempDir.path);
    _registerAdapters();
    await Hive.openBox<Song>('songs');
    await Hive.openBox<Album>('albums');
    await Hive.openBox<Artist>('artists');
    await Hive.openBox<SearchHistory>('search_history');
    await Hive.openBox<Playlist>('playlists');
    await Hive.openBox('settings');
    subsonicService = _FakeSubsonicService();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('shows server config when no server is configured',
      (tester) async {
    await _pumpApp(tester, subsonicService);

    expect(find.text('服务器配置'), findsOneWidget);
    expect(find.text('测试连接'), findsOneWidget);
  });

  testWidgets('builds Listener home from configured data', (tester) async {
    await _pumpPage(tester, subsonicService, const HomeScreen());

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('为你打开今天的旋律'), findsOneWidget);
    expect(find.text('播放列表'), findsWidgets);
    expect(find.text('Midnight Signal'), findsWidgets);
  });

  testWidgets('builds Listener library pages with fake Subsonic data',
      (tester) async {
    await _expectPageBuilds(
      tester,
      subsonicService,
      const AlbumsScreen(),
      ['专辑收藏', '最近添加', 'Aurora Archive'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const ArtistsScreen(),
      ['艺术家收藏', 'Nova'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const SongsScreen(),
      ['歌曲馆', 'Midnight Signal'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const GenresScreen(),
      ['风格列表', 'Synthwave'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const FavoritesScreen(),
      ['喜爱', 'Midnight Signal'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const PlaylistManagementScreen(),
      ['播放列表', 'Night Drive'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const GroupCastScreen(),
      ['同步播放', '让多台设备一起进入同一份节奏'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const SearchScreen(),
      ['Search', '搜索你想听的声音'],
    );
  });

  testWidgets('builds Listener detail pages with fake Subsonic data',
      (tester) async {
    await _expectPageBuilds(
      tester,
      subsonicService,
      const AlbumDetailScreen(
        albumId: 'album-1',
        albumName: 'Aurora Archive',
        albumArtist: 'Nova',
        coverArtId: 'cover-album-1',
      ),
      ['Aurora Archive', 'Midnight Signal'],
    );

    await _expectPageBuilds(
      tester,
      subsonicService,
      const ArtistDetailScreen(
        artistId: 'artist-1',
        artistName: 'Nova',
        coverArtId: 'cover-artist-1',
      ),
      ['Nova', 'Aurora Archive'],
    );

    await _expectPageBuilds(
      tester,
      subsonicService,
      const ArtistTracksScreen(
        artistId: 'artist-1',
        artistName: 'Nova',
        coverArtId: 'cover-artist-1',
      ),
      ['Nova', 'Aurora Archive'],
    );

    await _expectPageBuilds(
      tester,
      subsonicService,
      const GenreDetailScreen(
        genreName: 'Synthwave',
        albumCount: 1,
        trackCount: 2,
      ),
      ['Synthwave', 'Midnight Signal'],
    );

    await _expectPageBuilds(
      tester,
      subsonicService,
      const PlaylistDetailScreen(playlistId: 'playlist-1'),
      ['Night Drive', 'Midnight Signal'],
    );
  });

  testWidgets('shows Listener search no-results state', (tester) async {
    await _pumpPage(
      tester,
      subsonicService,
      const SearchScreen(initialQuery: 'missing-track'),
      extraOverrides: [
        searchResultProvider.overrideWith(
          (ref) => SearchResult(songs: [], albums: [], artists: []),
        ),
      ],
    );

    await _expectText(tester, '没有找到结果', reason: 'SearchScreen no results');
  });

  testWidgets('shows Listener favorite failure feedback', (tester) async {
    subsonicService.favoriteSucceeds = false;
    await _pumpPage(tester, subsonicService, const FavoritesScreen());

    await tester.tap(find.byIcon(FLucideIcons.heart).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await _expectText(
      tester,
      '取消收藏失败',
      reason: 'FavoritesScreen favorite failure',
    );
  });

  testWidgets('shows Listener favorite success feedback', (tester) async {
    await _pumpPage(tester, subsonicService, const FavoritesScreen());

    await tester.tap(find.byIcon(FLucideIcons.heart).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await _expectText(
      tester,
      '已取消收藏',
      reason: 'FavoritesScreen favorite success',
    );
  });

  testWidgets('builds Listener mini player and queue from fake audio state',
      (tester) async {
    final songs = subsonicService._songs;

    await _pumpPage(
      tester,
      subsonicService,
      MiniPlayer(onTap: () {}),
      extraOverrides: _audioStateOverrides(
        currentSong: songs.first,
        playlist: songs,
        currentIndex: 0,
        playing: true,
      ),
    );

    expect(find.text('Midnight Signal'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);
    expect(find.byIcon(FLucideIcons.pause), findsOneWidget);

    await _pumpPage(
      tester,
      subsonicService,
      const PlayQueueScreen(),
      extraOverrides: _audioStateOverrides(
        currentSong: songs.first,
        playlist: songs,
        currentIndex: 0,
        playing: true,
      ),
    );

    await _expectText(tester, '播放队列', reason: 'PlayQueueScreen header');
    await _expectText(tester, '继续聆听', reason: 'PlayQueueScreen title');
    await _expectText(tester, '当前播放', reason: 'PlayQueueScreen current');
    await _expectText(tester, '同播', reason: 'PlayQueueScreen group cast');
    await _expectText(tester, 'Glass Horizon', reason: 'PlayQueueScreen row');
  });

  test('AudioPlayerService updates queue and current song when playing',
      () async {
    final backend = _FakeAudioPlaybackBackend();
    final service = AudioPlayerService.testing(backend);
    final songs = subsonicService._songs;

    await service.setPlaylist(songs, initialIndex: 1);
    await service.playAtIndex(1, (id) => 'https://example.test/stream/$id');

    expect(service.playlist, songs);
    expect(service.currentIndex, 1);
    expect(service.currentSong, songs[1]);
    expect(backend.lastUrl, 'https://example.test/stream/song-2');
    expect(backend.playCalls, 1);

    await service.dispose();
  });

  testWidgets('validates Listener key pages at mobile and desktop sizes',
      (tester) async {
    final fakeAudioService = AudioPlayerService.testing(
      _FakeAudioPlaybackBackend(),
    );
    final songs = subsonicService._songs;
    final audioOverrides = [
      audioPlayerServiceProvider.overrideWithValue(fakeAudioService),
      ..._audioStateOverrides(
        currentSong: songs.first,
        playlist: songs,
        currentIndex: 0,
        playing: true,
        duration: const Duration(minutes: 4),
      ),
      searchResultProvider.overrideWith(
        (ref) => SearchResult(songs: [], albums: [], artists: []),
      ),
    ];

    final cases = <_ViewportCase>[
      _ViewportCase('home', const HomeScreen(), audioOverrides),
      _ViewportCase(
        'album detail',
        const AlbumDetailScreen(
          albumId: 'album-1',
          albumName: 'Aurora Archive',
          albumArtist: 'Nova',
          coverArtId: 'cover-album-1',
        ),
        audioOverrides,
      ),
      _ViewportCase(
        'artist detail',
        const ArtistDetailScreen(
          artistId: 'artist-1',
          artistName: 'Nova',
          coverArtId: 'cover-artist-1',
        ),
        audioOverrides,
      ),
      _ViewportCase('songs', const SongsScreen(), audioOverrides),
      _ViewportCase(
        'playlist detail',
        const PlaylistDetailScreen(playlistId: 'playlist-1'),
        audioOverrides,
      ),
      _ViewportCase('player', const PlayerScreen(), audioOverrides),
      _ViewportCase('queue', const PlayQueueScreen(), audioOverrides),
      _ViewportCase(
        'search',
        const SearchScreen(initialQuery: 'missing-track'),
        audioOverrides,
      ),
      _ViewportCase('settings', const SettingsScreen(), audioOverrides),
      _ViewportCase('group cast', const GroupCastScreen(), audioOverrides),
    ];

    for (final size in const [Size(390, 844), Size(1024, 768)]) {
      await _setSurfaceSize(tester, size);
      for (final page in cases) {
        await _pumpPage(
          tester,
          subsonicService,
          page.child,
          extraOverrides: page.extraOverrides,
        );
        expect(tester.takeException(), isNull, reason: page.name);
      }
    }

    await _setSurfaceSize(tester, null);
    await fakeAudioService.dispose();
  });

  testWidgets('shows Listener empty states when API returns empty lists',
      (tester) async {
    subsonicService.empty = true;
    await _pumpPage(tester, subsonicService, const HomeScreen());

    await _expectText(tester, '暂无新专辑', reason: 'HomeScreen empty albums');
    await _expectText(tester, '暂无艺术家', reason: 'HomeScreen empty artists');
    await _expectText(tester, '暂无风格', reason: 'HomeScreen empty genres');
    await _expectText(tester, '暂无歌曲', reason: 'HomeScreen empty songs');

    await _expectPageBuilds(
      tester,
      subsonicService,
      const AlbumsScreen(),
      ['暂无专辑'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const ArtistsScreen(),
      ['还没有艺术家'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const SongsScreen(),
      ['这里还没有声音'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const GenresScreen(),
      ['这里还没有风格'],
    );
    await _expectPageBuilds(
      tester,
      subsonicService,
      const FavoritesScreen(),
      ['这里还没有内容'],
    );
  });
}

class _ViewportCase {
  final String name;
  final Widget child;
  final List<Override> extraOverrides;

  const _ViewportCase(
    this.name,
    this.child, [
    this.extraOverrides = const [],
  ]);
}

class _FakeAudioPlaybackBackend implements AudioPlaybackBackend {
  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  String? lastUrl;
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  bool _playing = false;

  @override
  bool get playing => _playing;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Future<void> setUrl(String url) async {
    lastUrl = url;
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    _playing = true;
    _playerStateController.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    _playing = false;
    _playerStateController.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _playing = false;
    _playerStateController.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> seek(Duration position) async {
    _positionController.add(position);
  }

  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {}

  @override
  Future<void> dispose() async {
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SongAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AlbumAdapter());
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(SearchHistoryAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlaylistAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ArtistAdapter());
}

Future<void> _pumpApp(
  WidgetTester tester,
  SubsonicService subsonicService,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subsonicServiceProvider.overrideWithValue(subsonicService),
      ],
      child: const MyApp(),
    ),
  );
  await _pumpFrames(tester);
}

Future<void> _pumpPage(
    WidgetTester tester, _FakeSubsonicService subsonicService, Widget child,
    {List<Override> extraOverrides = const []}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ..._pageOverrides(subsonicService),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme(AppTheme.themeColors.first),
        localizationsDelegates: FLocalizations.localizationsDelegates,
        supportedLocales: FLocalizations.supportedLocales,
        home: FTheme(
          data: AppTheme.foruiTheme(isDark: false),
          child: FToaster(
            child: FTooltipGroup(child: child),
          ),
        ),
      ),
    ),
  );
  await _pumpFrames(tester);
}

Future<void> _expectPageBuilds(
    WidgetTester tester,
    _FakeSubsonicService subsonicService,
    Widget child,
    List<String> expectedTexts,
    {List<Override> extraOverrides = const []}) async {
  await _pumpPage(
    tester,
    subsonicService,
    child,
    extraOverrides: extraOverrides,
  );
  for (final text in expectedTexts) {
    await _expectText(tester, text, reason: child.runtimeType.toString());
  }
}

List<Override> _pageOverrides(_FakeSubsonicService service) {
  return [
    subsonicServiceProvider.overrideWithValue(service),
    listenerHomeProvider.overrideWith(
      (ref) async => ListenerHomeData(
        randomSongs: await service.getRandomSongs(size: 20),
        recentAlbums: await service.getAlbumList(size: 10),
        artists: await service.getArtists(),
        genres: await service.getGenres(),
      ),
    ),
    recentAlbumsProvider.overrideWith(
      (ref) async => service.getAlbumList(type: 'newest', size: 10),
    ),
    randomAlbumsProvider.overrideWith(
      (ref) async => service.getAlbumList(type: 'random', size: 10),
    ),
    frequentAlbumsProvider.overrideWith(
      (ref) async => service.getAlbumList(type: 'frequent', size: 10),
    ),
    albumListProvider.overrideWith(
      (ref, type) async => service.getAlbumList(type: type, size: 100),
    ),
    albumDetailProvider.overrideWith(
      (ref, albumId) async => service.getAlbum(albumId),
    ),
    artistsProvider.overrideWith((ref) async => service.getArtists()),
    artistDetailProvider.overrideWith(
      (ref, artistId) async => service.getArtist(artistId),
    ),
    genresProvider.overrideWith((ref, sort) async {
      final genres = await service.getGenres();
      final sorted = List<Genre>.from(genres);
      switch (sort) {
        case 'most-albums':
          sorted.sort((a, b) => b.albumCount.compareTo(a.albumCount));
          break;
        case 'most-tracks':
          sorted.sort((a, b) => b.trackCount.compareTo(a.trackCount));
          break;
        default:
          sorted.sort((a, b) => a.name.compareTo(b.name));
      }
      return sorted;
    }),
    genreSongsProvider.overrideWith(
      (ref, genre) async => service.getSongsByGenre(genre),
    ),
    songsLibraryProvider.overrideWith(
      (ref, sort) async => service.getRandomSongs(size: 100),
    ),
    artistSongsProvider.overrideWith(
      (ref, artistId) async => service.getAlbum('album-1'),
    ),
    artistAlbumsProvider.overrideWith(
      (ref, artistId) async => service.empty ? <Album>[] : service._albums,
    ),
    starredItemsProvider.overrideWith((ref) async => service.getStarred2()),
    playlistsProvider.overrideWith((ref) async {
      final rows = await service.getPlaylists();
      return rows
          .map(
            (row) => Playlist(
              id: row['id'] as String,
              name: row['name'] as String,
              description: row['comment'] as String?,
              songIds: const [],
              createdAt: DateTime.parse(row['created'] as String),
              updatedAt: DateTime(2024),
            ),
          )
          .toList();
    }),
    playlistProvider.overrideWith((ref, id) async {
      final row = await service.getPlaylist(id);
      if (row == null) return null;
      return Playlist(
        id: row['id'] as String,
        name: row['name'] as String,
        description: row['comment'] as String?,
        songIds: const ['song-1', 'song-2'],
        createdAt: DateTime.parse(row['created'] as String),
        updatedAt: DateTime(2024),
      );
    }),
    playlistSongsProvider.overrideWith(
      (ref, playlistId) async => service.empty ? <Song>[] : service._songs,
    ),
  ];
}

List<Override> _audioStateOverrides({
  Song? currentSong,
  List<Song> playlist = const <Song>[],
  int currentIndex = -1,
  bool playing = false,
  Duration position = Duration.zero,
  Duration? duration = Duration.zero,
  PlayMode playMode = PlayMode.sequence,
}) {
  return [
    currentSongProvider.overrideWith((ref) => Stream.value(currentSong)),
    currentPlaylistProvider.overrideWith((ref) => Stream.value(playlist)),
    currentIndexProvider.overrideWith((ref) => Stream.value(currentIndex)),
    playerStateProvider.overrideWith(
      (ref) => Stream.value(
        PlayerState(playing, ProcessingState.ready),
      ),
    ),
    positionProvider.overrideWith((ref) => Stream.value(position)),
    durationProvider.overrideWith((ref) => Stream.value(duration)),
    playModeProvider.overrideWith((ref) => Stream.value(playMode)),
  ];
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i += 1) {
    await tester.pump();
  }
}

Future<void> _setSurfaceSize(WidgetTester tester, Size? size) async {
  tester.view.devicePixelRatio = 1;
  if (size == null) {
    tester.view.resetPhysicalSize();
  } else {
    tester.view.physicalSize = size;
  }
  await tester.pump();
}

Future<void> _expectText(
  WidgetTester tester,
  String text, {
  required String reason,
}) async {
  final finder = find.text(text);
  if (finder.evaluate().isNotEmpty) {
    expect(finder, findsWidgets, reason: reason);
    return;
  }

  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 8 && finder.evaluate().isEmpty; i += 1) {
    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pump();
  }
  expect(finder, findsWidgets, reason: reason);
}

class _FakeSubsonicService extends SubsonicService {
  bool empty = false;
  bool favoriteSucceeds = true;

  final List<Song> _songs = [
    Song(
      id: 'song-1',
      title: 'Midnight Signal',
      album: 'Aurora Archive',
      artist: 'Nova',
      duration: 245,
      year: 2024,
      genre: 'Synthwave',
    ),
    Song(
      id: 'song-2',
      title: 'Glass Horizon',
      album: 'Aurora Archive',
      artist: 'Nova',
      duration: 208,
      year: 2024,
      genre: 'Synthwave',
    ),
  ];

  final List<Album> _albums = [
    Album(
      id: 'album-1',
      name: 'Aurora Archive',
      artist: 'Nova',
      artistId: 'artist-1',
      songCount: 2,
      duration: 453,
      year: 2024,
      genre: 'Synthwave',
    ),
  ];

  final List<Artist> _artists = [
    Artist(
      id: 'artist-1',
      name: 'Nova',
      albumCount: 1,
    ),
  ];

  final List<Genre> _genres = [
    const Genre(name: 'Synthwave', albumCount: 1, trackCount: 2),
    const Genre(name: 'Ambient', albumCount: 0, trackCount: 0),
  ];

  @override
  bool get isConfigured => true;

  @override
  Future<bool> ping() async => true;

  @override
  Future<List<Song>> getRandomSongs({int size = 10}) async {
    if (empty) return <Song>[];
    return _songs.take(size).toList();
  }

  @override
  Future<List<Album>> getAlbumList({
    String type = 'newest',
    int size = 20,
    int offset = 0,
  }) async {
    if (empty) return <Album>[];
    return _albums.skip(offset).take(size).toList();
  }

  @override
  Future<List<Song>> getAlbum(String albumId) async {
    if (empty) return <Song>[];
    return _songs.where((song) => song.album == 'Aurora Archive').toList();
  }

  @override
  Future<Song?> getSong(String songId) async {
    if (empty) return null;
    return _songs.where((song) => song.id == songId).firstOrNull;
  }

  @override
  String getStreamUrl(String songId) => 'https://example.test/stream/$songId';

  @override
  String getCoverArtUrl(String coverArtId, {int size = 300}) => '';

  @override
  Future<Map<String, dynamic>> search(String query) async {
    if (empty || query.isEmpty) {
      return {
        'songs': <Song>[],
        'albums': <Album>[],
        'artists': <Artist>[],
      };
    }
    return {
      'songs': _songs,
      'albums': _albums,
      'artists': _artists,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    if (empty) return <Map<String, dynamic>>[];
    return [
      {
        'id': 'playlist-1',
        'name': 'Night Drive',
        'comment': 'Late hour favorites',
        'created': DateTime(2024).toIso8601String(),
        'songCount': 2,
      },
    ];
  }

  @override
  Future<Map<String, dynamic>?> getPlaylist(String playlistId) async {
    if (empty) return null;
    return {
      'id': 'playlist-1',
      'name': 'Night Drive',
      'comment': 'Late hour favorites',
      'created': DateTime(2024).toIso8601String(),
      'entry': _songs.map((song) => song.toJson()).toList(),
    };
  }

  @override
  Future<List<Artist>> getArtists() async {
    if (empty) return <Artist>[];
    return _artists;
  }

  @override
  Future<Map<String, dynamic>?> getArtist(String artistId) async {
    if (empty) return null;
    return {
      'id': 'artist-1',
      'name': 'Nova',
      'coverArt': 'cover-artist-1',
      'albumCount': 1,
      'album': _albums.map((album) => album.toJson()).toList(),
    };
  }

  @override
  Future<List<Genre>> getGenres() async {
    if (empty) return <Genre>[];
    return _genres;
  }

  @override
  Future<List<Song>> getSongsByGenre(
    String genre, {
    int count = 100,
    int offset = 0,
  }) async {
    if (empty) return <Song>[];
    return _songs
        .where((song) => song.genre == genre)
        .skip(offset)
        .take(count)
        .toList();
  }

  @override
  Future<StarredItems> getStarred2() async {
    if (empty) return const StarredItems();
    return StarredItems(
      songs: [_songs.first],
      albums: _albums,
      artists: _artists,
    );
  }

  @override
  Future<bool> star({String? id, String? albumId, String? artistId}) async {
    return favoriteSucceeds;
  }

  @override
  Future<bool> unstar({String? id, String? albumId, String? artistId}) async {
    return favoriteSucceeds;
  }
}
