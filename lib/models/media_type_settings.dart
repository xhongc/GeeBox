import 'package:hive/hive.dart';

part 'media_type_settings.g.dart';

@HiveType(typeId: 10)
class MediaTypeSettings extends HiveObject {
  @HiveField(0)
  bool musicEnabled;

  @HiveField(1)
  bool podcastEnabled;

  @HiveField(2)
  bool audiobookEnabled;

  @HiveField(3)
  bool radioEnabled;

  MediaTypeSettings({
    this.musicEnabled = true,
    this.podcastEnabled = true,
    this.audiobookEnabled = false,
    this.radioEnabled = true,
  });

  /// 至少要启用一个类型
  bool get hasAtLeastOneEnabled =>
      musicEnabled || podcastEnabled || audiobookEnabled || radioEnabled;

  /// 获取已启用的类型列表
  List<String> get enabledTypes {
    final types = <String>[];
    if (musicEnabled) types.add('music');
    if (podcastEnabled) types.add('podcast');
    if (audiobookEnabled) types.add('audiobook');
    if (radioEnabled) types.add('radio');
    return types;
  }

  /// 获取已启用的类型数量
  int get enabledCount => enabledTypes.length;

  /// 复制并修改
  MediaTypeSettings copyWith({
    bool? musicEnabled,
    bool? podcastEnabled,
    bool? audiobookEnabled,
    bool? radioEnabled,
  }) {
    return MediaTypeSettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      podcastEnabled: podcastEnabled ?? this.podcastEnabled,
      audiobookEnabled: audiobookEnabled ?? this.audiobookEnabled,
      radioEnabled: radioEnabled ?? this.radioEnabled,
    );
  }
}
