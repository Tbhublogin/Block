# Phase 0 — Flutter Project Scaffolding (BUILD_PROMPTS prompt 0.1)

## Context / environment facts
- Repo is docs-only (PRD.md, AI_RULES.md, BUILD_PROMPTS.md, PROJECT_STATE.md), clean on `main`. All Flutter files will be created from scratch.
- Flutter 3.47.1 stable / Dart 3.13.1 at `C:\src\flutter`. Android SDK present; **licenses not yet accepted** (see step 7).

## Steps

### 1. Scaffold the Flutter project
- `flutter create --project-name block_civilizations --platforms android .` (run in the repo root; the `--project-name` flag is needed because the folder name has a space/capitals).
- **Android-only** per PRD §1 ("Platform: Android"); web can be added later with one command if you want Chrome previews (useful since no Android device is currently connected).
- This generates: `pubspec.yaml`, `analysis_options.yaml` (flutter_lints → satisfies AI_RULES rule 12), `.gitignore` (currently missing), `android/`, `test/`.
- Org stays the default `com.example` — the applicationId can be changed in `build.gradle` before Play Store release (final app name is still an open decision); flagged here rather than silently assumed permanent.

### 2. Dependencies (exactly the prompt's list, nothing more)
- Add via `flutter pub add`: `flutter_riverpod`, `shared_preferences`, `hive`, `hive_flutter`, `audioplayers`, `google_mobile_ads` (latest stable compatible with Flutter 3.47), plus `flutter_localizations` (sdk) and `intl` (version pinned to match what the Flutter SDK pins).
- dev_dependencies stay: `flutter_test`, `flutter_lints`.
- This resolves the two open PROJECT_STATE decisions: **Hive** (not sqflite) and **audioplayers** (not soundpool) — will be recorded as decided.

### 3. Placeholder files (each gets a short `// TODO` responsibility comment; no logic)
- `lib/app.dart` — MaterialApp, routing, localization delegates (PRD §4)
- `core/constants/`: `game_constants.dart` (grid size, scoring, special-spawn rate), `piece_shapes.dart` (named in BUILD_PROMPTS 1.2/1.3), `asset_paths.dart`
- `core/theme/`: `app_theme.dart`, `civilization_palettes.dart`
- `domain/models/`: `civilization.dart`, `stage.dart`, `piece.dart`, `board_cell.dart`, `game_result.dart`
- `domain/logic/`: `board_engine.dart`, `piece_generator.dart`, `score_calculator.dart`, `lose_condition_checker.dart`
- `data/datasources/`: `civilizations_data.dart`, `local_storage_service.dart`
- `application/`: `game_controller.dart`, `progress_controller.dart`, `settings_controller.dart`, `museum_controller.dart`
- `presentation/screens/`: `splash_screen.dart`, `main_menu_screen.dart`, `map_screen.dart`, `stage_select_screen.dart`, `game_screen.dart`, `museum_screen.dart`, `settings_screen.dart`, plus `stage_result_screens/stage_win_dialog.dart` + `stage_lose_dialog.dart`
- `presentation/widgets/`: `board_widget.dart`, `piece_tray_widget.dart`, `draggable_piece_widget.dart`, `score_bar_widget.dart`, `civilization_emblem_button.dart`
- `ads/ad_service.dart`
- Directories listed in PRD §4 that have no filenames yet (`core/localization/`, `core/utils/`, `domain/repositories_interfaces/`, `data/repositories/`, `data/models_dto/`) get a one-line `README.md` stub describing their intended responsibility, so they're tracked and documented without inventing API surface that later phases might contradict.

### 4. Entry point
- `main.dart` → `runApp(const App())`; `app.dart` holds a minimal MaterialApp with a placeholder Scaffold showing "Under construction".
- **Flagged (AI_RULES rule 6):** the placeholder string is temporarily hardcoded because localization is deliberately Phase 1 (BUILD_PROMPT 0.2); it will be moved to ARB strings then. Same for the MaterialApp `title`.

### 5. Test
- Replace the generated counter `widget_test.dart` with a smoke test: app builds and the placeholder screen renders.

### 6. Verification
- `flutter pub get` → `dart format .` → `flutter analyze` (0 issues) → `flutter test` (pass).

### 7. Android toolchain (needs your approval — that's what this plan approval covers)
- Run `flutter doctor --android-licenses` to accept the SDK licenses on your machine, then `flutter build apk --debug` as an end-to-end proof. Skippable — not strictly required for Phase 0.

### 8. Update PROJECT_STATE.md (required by prompt + AI_RULES rule 27)
- Mark Phase 0 (Project Scaffolding) complete; next steps = Phase 1 (Localization + Theme setup, BUILD_PROMPT 0.2).
- Move Hive/audioplayers choices from "open decisions" to decided; add decision-log entry; note that landmark PNGs are not yet in the repo (docs say finalized — they must be copied in before Phase 3 asset wiring).

No git commit — changes stay uncommitted unless you ask.