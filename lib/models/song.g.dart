// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      album: fields[2] as String?,
      artist: fields[3] as String?,
      duration: fields[4] as int?,
      coverArt: fields[5] as String?,
      year: fields[6] as int?,
      genre: fields[7] as String?,
      bitRate: fields[8] as int?,
      contentType: fields[9] as String?,
      cacheTime: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.album)
      ..writeByte(3)
      ..write(obj.artist)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.coverArt)
      ..writeByte(6)
      ..write(obj.year)
      ..writeByte(7)
      ..write(obj.genre)
      ..writeByte(8)
      ..write(obj.bitRate)
      ..writeByte(9)
      ..write(obj.contentType)
      ..writeByte(10)
      ..write(obj.cacheTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
