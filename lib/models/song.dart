import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? album;

  @HiveField(3)
  final String? artist;

  @HiveField(4)
  final int? duration;

  @HiveField(5)
  final String? coverArt;

  @HiveField(6)
  final int? year;

  @HiveField(7)
  final String? genre;

  @HiveField(8)
  final int? bitRate;

  @HiveField(9)
  final String? contentType;

  @HiveField(10)
  final DateTime? cacheTime;

  Song({
    required this.id,
    required this.title,
    this.album,
    this.artist,
    this.duration,
    this.coverArt,
    this.year,
    this.genre,
    this.bitRate,
    this.contentType,
    this.cacheTime,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      album: json['album'] as String?,
      artist: json['artist'] as String?,
      duration: json['duration'] as int?,
      coverArt: json['coverArt'] as String?,
      year: json['year'] as int?,
      genre: json['genre'] as String?,
      bitRate: json['bitRate'] as int?,
      contentType: json['contentType'] as String?,
      cacheTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'artist': artist,
      'duration': duration,
      'coverArt': coverArt,
      'year': year,
      'genre': genre,
      'bitRate': bitRate,
      'contentType': contentType,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? album,
    String? artist,
    int? duration,
    String? coverArt,
    int? year,
    String? genre,
    int? bitRate,
    String? contentType,
    DateTime? cacheTime,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      album: album ?? this.album,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      coverArt: coverArt ?? this.coverArt,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      bitRate: bitRate ?? this.bitRate,
      contentType: contentType ?? this.contentType,
      cacheTime: cacheTime ?? this.cacheTime,
    );
  }
}
