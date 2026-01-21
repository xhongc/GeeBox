import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/music_repository.dart';
import '../models/song.dart';
import '../models/album.dart';
import 'subsonic_provider.dart';

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
final recentAlbumsProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbumList(type: 'newest', size: 10);
});

// 随机专辑 Provider
final randomAlbumsProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbumList(type: 'random', size: 10);
});

// 热门专辑 Provider
final frequentAlbumsProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  return await repository.getAlbumList(type: 'frequent', size: 10);
});
