# Repository Guidelines

This repository contains Chanson, a Flutter-based Subsonic music client targeting mobile, desktop, and web.

## Project Structure & Module Organization

- `lib/` contains all Dart source code.
  - `lib/models/` data models and Hive adapters (`*.g.dart`).
  - `lib/services/` API and playback services.
  - `lib/repositories/` data access and caching.
  - `lib/providers/` Riverpod state providers.
  - `lib/screens/`, `lib/widgets/`, `lib/router/`, `lib/theme/` UI and navigation.
- `test/` contains Flutter tests (e.g., `test/widget_test.dart`).
- Platform folders: `android/`, `ios/`, `macos/`, `linux/`, `windows/`.
- Docs: `README.md`, `QUICKSTART.md`, `PROJECT_SUMMARY.md`, `UI_DESIGN.md`, `subsonic_api_docs.md`.

## Build, Test, and Development Commands

- `flutter pub get` installs dependencies.
- `dart run build_runner build --delete-conflicting-outputs` regenerates Hive adapters after model changes.
- `dart run build_runner watch --delete-conflicting-outputs` watches and regenerates code during development.
- `flutter run -d macos` runs the desktop app (recommended for full functionality).
- `flutter run -d chrome` runs web (UI only due to CORS limits).
- `./start.sh` launches Chrome with CORS disabled and runs the web app (macOS dev helper).
- `flutter analyze` runs static analysis; `flutter test` runs tests; `flutter clean` clears build artifacts.

## Coding Style & Naming Conventions

- Follow `analysis_options.yaml` (Flutter lints) and format with `dart format`.
- Use Dart conventions: files in `lower_snake_case`, types in `UpperCamelCase`.
- Do not edit generated files (`*.g.dart`). When adding models, include Hive annotations, a `cacheTime` field, and register adapters in `lib/main.dart`.
- Access services via Riverpod providers in `lib/providers/` instead of calling services directly from widgets.

## Testing Guidelines

- Use `flutter_test`; keep tests under `test/` with names like `*_test.dart`.
- Run `flutter test` before submitting changes. No explicit coverage target is defined.

## Commit & Pull Request Guidelines

- Commit history uses short, feature-focused messages, often in Chinese (e.g., `播放器`, `mini player`). Keep one-line summaries and stay consistent with that style.
- PRs should include a brief description, key files or screens touched, and the tests you ran. Add screenshots for UI changes.

## Security & Configuration Tips

- Do not commit real Subsonic credentials. Server settings are stored locally in app data.
- Web builds are CORS-limited; prefer desktop targets or use `./start.sh` for development.
