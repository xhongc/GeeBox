class Genre {
  final String name;
  final int albumCount;
  final int trackCount;

  const Genre({
    required this.name,
    this.albumCount = 0,
    this.trackCount = 0,
  });

  String get id => name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    final rawName = json['value'] ?? json['name'] ?? json['id'];
    return Genre(
      name: rawName?.toString() ?? '',
      albumCount: _asInt(json['albumCount']),
      trackCount: _asInt(json['songCount'] ?? json['trackCount']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
