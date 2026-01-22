import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/search_service.dart';
import '../models/search_history.dart';
import 'subsonic_provider.dart';

/// 搜索服务 Provider
final searchServiceProvider = Provider<SearchService>((ref) {
  final subsonicService = ref.watch(subsonicServiceProvider);
  return SearchService(subsonicService);
});

/// 搜索结果 Provider
final searchResultProvider = StateProvider<SearchResult?>((ref) => null);

/// 搜索历史 Provider
final searchHistoryProvider = FutureProvider.autoDispose<List<SearchHistory>>((ref) async {
  final searchService = ref.watch(searchServiceProvider);
  return await searchService.getSearchHistoryAsync();
});
