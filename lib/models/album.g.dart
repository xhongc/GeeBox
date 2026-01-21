// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlbumAdapter extends TypeAdapter<Album> {
  @override
  final int typeId = 1;

  @override
  Album read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Album(
      id: fields[0] as String,
      name: fields[1] as String,
      artist: fields[2] as String?,
      artistId: fields[3] as String?,
      coverArt: fields[4] as String?,
      songCount: fields[5] as int?,
      duration: fields[6] as int?,
      year: fields[7] as int?,
      genre: fields[8] as String?,
      cacheTime: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Album obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.artistId)
      ..writeByte(4)
      ..write(obj.coverArt)
      ..writeByte(5)
      ..write(obj.songCount)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.year)
      ..writeByte(8)
      ..write(obj.genre)
      ..writeByte(9)
      ..write(obj.cacheTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
