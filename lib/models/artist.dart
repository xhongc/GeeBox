import 'package:hive/hive.dart';

part 'artist.g.dart';

@HiveType(typeId: 4)
class Artist extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? coverArt;

  @HiveField(3)
  final int? albumCount;

  @HiveField(4)
  final DateTime? cacheTime;

  Artist({
    required this.id,
    required this.name,
    this.coverArt,
    this.albumCount,
    this.cacheTime,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      coverArt: json['coverArt'] as String?,
      albumCount: json['albumCount'] as int?,
      cacheTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverArt': coverArt,
      'albumCount': albumCount,
    };
  }

  Artist copyWith({
    String? id,
    String? name,
    String? coverArt,
    int? albumCount,
    DateTime? cacheTime,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverArt: coverArt ?? this.coverArt,
      albumCount: albumCount ?? this.albumCount,
      cacheTime: cacheTime ?? this.cacheTime,
    );
  }
}
