import 'package:hive/hive.dart';

part 'playlist.g.dart';

@HiveType(typeId: 3)
class Playlist extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<String> songIds;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  String? coverUrl;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
    this.coverUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverUrl': coverUrl,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      songIds: (json['songIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      coverUrl: json['coverUrl'] as String?,
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverUrl,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}
