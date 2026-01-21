import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/search_service.dart';
import 'subsonic_provider.dart';

/// 搜索服务 Provider
final searchServiceProvider = Provider<SearchService>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return SearchService(subsonicService);
});

/// 搜索结果 Provider
final searchResultProvider = StateProvider<SearchResult?>((ref) => null);

/// 搜索历史 Provider
final searchHistoryProvider = Provider<List<dynamic>>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return searchService.getSearchHistory();
});
