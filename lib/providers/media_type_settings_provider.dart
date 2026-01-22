import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/media_type_settings.dart';

final mediaTypeSettingsProvider =
    StateNotifierProvider<MediaTypeSettingsNotifier, MediaTypeSettings>((ref) {
  return MediaTypeSettingsNotifier();
});

class MediaTypeSettingsNotifier extends StateNotifier<MediaTypeSettings> {
  MediaTypeSettingsNotifier() : super(MediaTypeSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = Hive.box('settings');
    final musicEnabled =
        box.get('media_music_enabled', defaultValue: true) as bool;
    final podcastEnabled =
        box.get('media_podcast_enabled', defaultValue: true) as bool;
    final audiobookEnabled =
        box.get('media_audiobook_enabled', defaultValue: false) as bool;
    final radioEnabled =
        box.get('media_radio_enabled', defaultValue: true) as bool;

    state = MediaTypeSettings(
      musicEnabled: musicEnabled,
      podcastEnabled: podcastEnabled,
      audiobookEnabled: audiobookEnabled,
      radioEnabled: radioEnabled,
    );
  }

  void toggleMusic(bool value) {
    // 确保至少有一个类型启用
    if (!value &&
        !state.podcastEnabled &&
        !state.audiobookEnabled &&
        !state.radioEnabled) {
      return;
    }
    state = state.copyWith(musicEnabled: value);
    _saveSettings();
  }

  void togglePodcast(bool value) {
    if (!value &&
        !state.musicEnabled &&
        !state.audiobookEnabled &&
        !state.radioEnabled) {
      return;
    }
    state = state.copyWith(podcastEnabled: value);
    _saveSettings();
  }

  void toggleAudiobook(bool value) {
    if (!value &&
        !state.musicEnabled &&
        !state.podcastEnabled &&
        !state.radioEnabled) {
      return;
    }
    state = state.copyWith(audiobookEnabled: value);
    _saveSettings();
  }

  void toggleRadio(bool value) {
    if (!value &&
        !state.musicEnabled &&
        !state.podcastEnabled &&
        !state.audiobookEnabled) {
      return;
    }
    state = state.copyWith(radioEnabled: value);
    _saveSettings();
  }

  void _saveSettings() {
    final box = Hive.box('settings');
    box.put('media_music_enabled', state.musicEnabled);
    box.put('media_podcast_enabled', state.podcastEnabled);
    box.put('media_audiobook_enabled', state.audiobookEnabled);
    box.put('media_radio_enabled', state.radioEnabled);
  }
}
