import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/music_repository.dart';
import 'subsonic_provider.dart';

// MusicRepository Provider
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return MusicRepository(subsonicService: subsonicService);
});
