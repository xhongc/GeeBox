import 'package:hive/hive.dart';

part 'search_history.g.dart';

@HiveType(typeId: 2)
class SearchHistory extends HiveObject {
  @HiveField(0)
  String query;

  @HiveField(1)
  DateTime timestamp;

  SearchHistory({
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
