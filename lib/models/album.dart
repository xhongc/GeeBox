import 'package:hive/hive.dart';

part 'album.g.dart';

@HiveType(typeId: 1)
class Album extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? artist;

  @HiveField(3)
  final String? artistId;

  @HiveField(4)
  final String? coverArt;

  @HiveField(5)
  final int? songCount;

  @HiveField(6)
  final int? duration;

  @HiveField(7)
  final int? year;

  @HiveField(8)
  final String? genre;

  @HiveField(9)
  final DateTime? cacheTime;

  Album({
    required this.id,
    required this.name,
    this.artist,
    this.artistId,
    this.coverArt,
    this.songCount,
    this.duration,
    this.year,
    this.genre,
    this.cacheTime,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String?,
      artistId: json['artistId'] as String?,
      coverArt: json['coverArt'] as String?,
      songCount: json['songCount'] as int?,
      duration: json['duration'] as int?,
      year: json['year'] as int?,
      genre: json['genre'] as String?,
      cacheTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'artistId': artistId,
      'coverArt': coverArt,
      'songCount': songCount,
      'duration': duration,
      'year': year,
      'genre': genre,
    };
  }

  Album copyWith({
    String? id,
    String? name,
    String? artist,
    String? artistId,
    String? coverArt,
    int? songCount,
    int? duration,
    int? year,
    String? genre,
    DateTime? cacheTime,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      coverArt: coverArt ?? this.coverArt,
      songCount: songCount ?? this.songCount,
      duration: duration ?? this.duration,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      cacheTime: cacheTime ?? this.cacheTime,
    );
  }
}
