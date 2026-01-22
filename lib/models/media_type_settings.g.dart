// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_type_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaTypeSettingsAdapter extends TypeAdapter<MediaTypeSettings> {
  @override
  final int typeId = 10;

  @override
  MediaTypeSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaTypeSettings(
      musicEnabled: fields[0] as bool,
      podcastEnabled: fields[1] as bool,
      audiobookEnabled: fields[2] as bool,
      radioEnabled: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MediaTypeSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.musicEnabled)
      ..writeByte(1)
      ..write(obj.podcastEnabled)
      ..writeByte(2)
      ..write(obj.audiobookEnabled)
      ..writeByte(3)
      ..write(obj.radioEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaTypeSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
