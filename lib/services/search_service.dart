import 'package:hive/hive.dart';
import '../models/search_history.dart';
import '../models/song.dart';
import '../models/album.dart';
import 'subsonic_service.dart';

class SearchService {
  final SubsonicService _subsonicService;
  Box<SearchHistory>? _historyBox;
  static const int _maxHistoryItems = 20;

  SearchService(this._subsonicService) {
    _initBox();
  }

  /// 初始化搜索历史存储
  Future<void> _initBox() async {
    _historyBox = await Hive.openBox<SearchHistory>('search_history');
  }

  /// 确保 box 已初始化
  Future<Box<SearchHistory>> _ensureBox() async {
    if (_historyBox == null || !_historyBox!.isOpen) {
      _historyBox = await Hive.openBox<SearchHistory>('search_history');
    }
    return _historyBox!;
  }

  /// 执行搜索
  Future<SearchResult> search(String query) async {
    if (query.trim().isEmpty) {
      return SearchResult(songs: [], albums: []);
    }

    // 保存搜索历史
    await _saveSearchHistory(query);

    // 执行搜索
    final result = await _subsonicService.search(query);
    return SearchResult(
      songs: result['songs'] as List<Song>,
      albums: result['albums'] as List<Album>,
    );
  }

  /// 保存搜索历史
  Future<void> _saveSearchHistory(String query) async {
    final box = await _ensureBox();

    // 检查是否已存在相同的查询
    final existingIndex = box.values.toList().indexWhere(
          (item) => item.query.toLowerCase() == query.toLowerCase(),
        );

    if (existingIndex != -1) {
      // 如果存在，删除旧的
      await box.deleteAt(existingIndex);
    }

    // 添加新的搜索历史
    final history = SearchHistory(
      query: query,
      timestamp: DateTime.now(),
    );
    await box.add(history);

    // 限制历史记录数量
    if (box.length > _maxHistoryItems) {
      // 删除最旧的记录
      final oldestKey = box.keys.first;
      await box.delete(oldestKey);
    }
  }

  /// 获取搜索历史
  List<SearchHistory> getSearchHistory() {
    if (_historyBox == null || !_historyBox!.isOpen) {
      return [];
    }
    final history = _historyBox!.values.toList();
    // 按时间倒序排列
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return history;
  }

  /// 异步获取搜索历史（确保 box 已初始化）
  Future<List<SearchHistory>> getSearchHistoryAsync() async {
    await _ensureBox();
    return getSearchHistory();
  }

  /// 清除搜索历史
  Future<void> clearSearchHistory() async {
    final box = await _ensureBox();
    await box.clear();
  }

  /// 删除单条搜索历史
  Future<void> deleteSearchHistory(String query) async {
    final box = await _ensureBox();
    final index = box.values.toList().indexWhere(
          (item) => item.query == query,
        );
    if (index != -1) {
      await box.deleteAt(index);
    }
  }
}

/// 搜索结果模型
class SearchResult {
  final List<Song> songs;
  final List<Album> albums;

  SearchResult({
    required this.songs,
    required this.albums,
  });

  bool get isEmpty => songs.isEmpty && albums.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
