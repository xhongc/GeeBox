# Flutter Architecture Review (findings only)

This document lists architecture risks and improvement opportunities observed
in the current Flutter/Riverpod setup. No changes are made yet.

## Findings

1. Playback state is not fully reactive and has multiple sources of truth.
   - `AudioPlayerService` is a mutable singleton; `audioPlayerServiceProvider`
     is a plain `Provider`, so state changes do not notify listeners.
   - UI uses `ref.listen(currentSongProvider, ...)` with an empty callback,
     which does not trigger rebuilds; `MiniPlayer` and `PlayerScreen` read
     `audioService.currentSong` directly, so updates can be missed.
   - Queue/play mode have dual state: internal service state and separate
     `StateProvider`s (`currentPlaylistProvider`, `currentIndexProvider`,
     `playModeProvider`), which can drift.
   - Files: `lib/services/audio_player_service.dart`,
     `lib/providers/audio_player_provider.dart`,
     `lib/widgets/mini_player.dart`, `lib/screens/player_screen.dart`,
     `lib/screens/play_queue_screen.dart`

2. Mixed routing approach (go_router + Navigator) causes stack inconsistency.
   - `go_router` is configured at app level, but many screens use
     `Navigator.push` directly, which bypasses router state.
   - Deep links, URL sync, and back behavior may become inconsistent.
   - Files: `lib/router/app_router.dart`, `lib/screens/*_screen.dart`

3. Server configuration lifecycle is brittle.
   - `SubsonicService` uses `late` fields and will crash if called before
     `configure` (e.g. user skips config and enters home).
   - Stored config is not hydrated into the service on app start.
   - Files: `lib/services/subsonic_service.dart`,
     `lib/providers/subsonic_provider.dart`,
     `lib/screens/server_config_screen.dart`, `lib/main.dart`

4. Album caching conflates multiple list types into a single box.
   - `MusicRepository.getAlbumList` stores all album lists into one Hive box
     keyed only by album id, not by list type (newest/random/frequent).
   - Cache validation uses the first album's `cacheTime`, which may cause
     random/recent lists to serve stale or wrong data.
   - Files: `lib/repositories/music_repository.dart`

5. Search history is not reactive and mixes async init with sync reads.
   - `SearchService` opens Hive asynchronously in constructor; UI can read
     history before box is ready and see empty results.
   - `searchHistoryProvider` is a plain `Provider<List>` and uses sync
     `getSearchHistory`; UI resorts to `setState` to refresh.
   - Files: `lib/services/search_service.dart`,
     `lib/providers/search_provider.dart`, `lib/screens/search_screen.dart`

6. Lyrics provider uses a mutable Map key, defeating caching semantics.
   - `lyricsProvider` uses `Map<String, String?>` as the family parameter.
     Maps use identity equality, so each call is a new key and refetches.
   - File: `lib/providers/lyrics_provider.dart`

7. Timer state is represented as a dummy counter.
   - `sleepTimerStateProvider` uses an `int` increment to force refresh, which
     is fragile and not expressive for remaining time / state transitions.
   - Files: `lib/providers/sleep_timer_provider.dart`,
     `lib/services/sleep_timer_service.dart`

## Confirmations Needed

1. Do you want playback state to be fully owned by Riverpod
   (StateNotifier/AsyncNotifier), or keep a service + streams model?
2. Should routing be fully standardized on `go_router`?
3. For server config, do you want "skip" to allow offline mode, or block
   until config is valid?

