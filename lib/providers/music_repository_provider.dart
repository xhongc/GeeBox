import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/music_repository.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/genre.dart';
import 'subsonic_provider.dart';

class ListenerHomeData {
  final List<Song> randomSongs;
  final List<Album> recentAlbums;
  final List<Artist> artists;
  final List<Genre> genres;

  const ListenerHomeData({
    required this.randomSongs,
    required this.recentAlbums,
    required this.artists,
    required this.genres,
  });
}

// MusicRepository Provider
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return MusicRepository(subsonicService: subsonicService);
});

// 随机歌曲 Provider
final randomSongsProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getRandomSongs(size: 20);
});

// 最近专辑 Provider
final recentAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbumList(type: 'newest', size: 10);
});

// 随机专辑 Provider
final randomAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbumList(type: 'random', size: 10);
});

// 热门专辑 Provider
final frequentAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbumList(type: 'frequent', size: 10);
});

// 艺术家 Provider
final artistsProvider = FutureProvider.autoDispose<List<Artist>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getArtists();
});

// Listener 首页聚合 Provider
final listenerHomeProvider =
    FutureProvider.autoDispose<ListenerHomeData>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final randomSongs = await repository.getRandomSongs(size: 20);
  final recentAlbums = await repository.getAlbumList(type: 'newest', size: 10);
  final artists = await repository.getArtists();
  final genres = await repository.getGenres();
  final sortedGenres = List<Genre>.from(genres)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return ListenerHomeData(
    randomSongs: randomSongs,
    recentAlbums: recentAlbums,
    artists: artists,
    genres: sortedGenres,
  );
});

// 风格 Provider
final genresProvider =
    FutureProvider.family.autoDispose<List<Genre>, String>((ref, sort) async {
  final repository = ref.watch(musicRepositoryProvider);
  final genres = await repository.getGenres();
  final sorted = List<Genre>.from(genres);

  switch (sort) {
    case 'most-albums':
      sorted.sort((a, b) => b.albumCount.compareTo(a.albumCount));
      break;
    case 'most-tracks':
      sorted.sort((a, b) => b.trackCount.compareTo(a.trackCount));
      break;
    case 'a-z':
    default:
      sorted
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
  }

  return sorted;
});

// 风格歌曲 Provider
final genreSongsProvider =
    FutureProvider.family.autoDispose<List<Song>, String>((ref, genre) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getSongsByGenre(genre, count: 100);
});

// Listener 歌曲库 Provider
final songsLibraryProvider =
    FutureProvider.family.autoDispose<List<Song>, String>((ref, sort) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getSongLibrary(sort: sort, size: 100);
});

// 艺术家歌曲 Provider
final artistSongsProvider = FutureProvider.family
    .autoDispose<List<Song>, String>((ref, artistId) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getArtistSongs(artistId);
});
