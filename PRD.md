# Product Requirements Document (PRD)
## Project Name: [TBD] — Civilization Block Puzzle Game

**Version:** 1.0
**Platform:** Android (Flutter)
**Engine:** None — pure Flutter/Dart (no Flame or other game engine)
**Document Owner:** Product/Dev (single developer, AI-assisted)

---

## 1. Overview

A block-puzzle mobile game in the "Block Blast" genre (drag blocks onto an 8x8 grid, clear full rows/columns) reskinned around world civilizations. Instead of generic colored blocks, every piece is illustrated with a historical landmark relevant to the civilization currently being played. The game is structured as a world map of 8 civilizations. Each civilization contains 30 sub-stages of increasing score difficulty. Completing all 30 sub-stages unlocks the next civilization on the map, which changes the piece art style, color palette, and landmark set.

## 2. Goals

- Deliver the addictive core loop of classic block-blast puzzles.
- Layer a light educational/cultural theme (real historical landmarks) without slowing gameplay.
- Support long-term retention via 8 civilizations × 30 stages = 240 stages, plus a "Museum" collection screen.
- Monetize via Google AdMob (rewarded ads for continue; optionally banner/interstitial later).
- Ship as a single APK/AAB to the Google Play Store.

## 3. Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (stable channel) |
| Language | Dart (null-safety, no legacy code) |
| Game engine | **None.** Grid/pieces are built with plain Flutter widgets + `CustomPainter` for the board and piece rendering. Drag & drop via `Draggable`/`DragTarget` or a custom gesture-based drag implementation. |
| State management | Riverpod (`flutter_riverpod`) — chosen for testability, DI, and clear separation of game logic from UI. |
| Local persistence | `shared_preferences` for simple key-values (settings, volume, language) + `hive` (or `sqflite`) for structured data (progress per civilization/stage, unlocked museum pieces, high scores). |
| Localization | `flutter_localizations` + `intl` with ARB files (`app_ar.arb`, `app_en.arb`). All UI strings must be localized — no hardcoded strings in widgets. |
| Ads | `google_mobile_ads` (AdMob). Rewarded ad for the "second chance" continue flow. |
| Audio (SFX + background music) | `audioplayers` or `soundpool` for low-latency short sound effects (piece pickup, piece placement, line clear, special piece clear, stage win, stage lose) **and** looping background music tracks. Implemented last in the build order, after all screens/UI/gameplay logic are complete (see `BUILD_PROMPTS.md` Phase 7). |
| Asset format | PNG (transparent background) per landmark/piece, generated externally via AI image tools and manually imported into `assets/`. |
| Testing | `flutter_test` for widget tests; plain `test` package for game-logic unit tests (grid logic, scoring, win/lose detection) — logic must be engine-agnostic and unit-testable without widgets. |

## 4. High-Level Architecture

The codebase follows a layered architecture to keep game rules independent of Flutter widgets (critical since there's no engine doing this for us):

```
lib/
├── main.dart
├── app.dart                     # MaterialApp, routing, localization delegates
│
├── core/
│   ├── constants/                # grid size, scoring constants, asset paths
│   ├── theme/                    # per-civilization color palettes, text styles
│   ├── localization/             # ARB-generated classes, language provider
│   └── utils/
│
├── domain/                       # Pure Dart, NO Flutter imports. Fully unit-testable.
│   ├── models/
│   │   ├── civilization.dart
│   │   ├── stage.dart
│   │   ├── piece.dart            # shape matrix, isSpecial flag, landmarkId
│   │   ├── board_cell.dart
│   │   └── game_result.dart
│   ├── logic/
│   │   ├── board_engine.dart     # grid state, placement validation, line/column clear
│   │   ├── piece_generator.dart  # random piece set generation, special piece odds
│   │   ├── score_calculator.dart # scoring rules, target score per stage
│   │   └── lose_condition_checker.dart  # "no piece fits anywhere" detection
│   └── repositories_interfaces/  # abstract classes, implemented in data/
│
├── data/
│   ├── datasources/
│   │   ├── civilizations_data.dart   # static content: 8 civilizations, landmarks, historical facts (ar/en)
│   │   └── local_storage_service.dart
│   ├── repositories/             # implementations of domain repository interfaces
│   └── models_dto/               # if needed for persistence serialization
│
├── application/                  # Riverpod providers / state notifiers (the "glue" layer)
│   ├── game_controller.dart      # orchestrates board_engine + piece_generator + score
│   ├── progress_controller.dart  # tracks unlocked civilizations/stages, stars, high score
│   ├── settings_controller.dart  # language, volume
│   └── museum_controller.dart    # unlocked pieces tracking
│
├── presentation/
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── main_menu_screen.dart
│   │   ├── map_screen.dart              # 8 civilization emblems on a world/region map
│   │   ├── stage_select_screen.dart     # 30 sub-stages per civilization
│   │   ├── game_screen.dart             # the actual puzzle board
│   │   ├── museum_screen.dart           # gallery of all pieces + historical info
│   │   ├── settings_screen.dart         # language + volume (accessible from menu AND in-game)
│   │   └── stage_result_screens/
│   │       ├── stage_win_dialog.dart
│   │       └── stage_lose_dialog.dart   # includes "watch ad to retry" flow
│   └── widgets/
│       ├── board_widget.dart
│       ├── piece_tray_widget.dart
│       ├── draggable_piece_widget.dart
│       ├── score_bar_widget.dart
│       └── civilization_emblem_button.dart
│
└── ads/
    └── ad_service.dart           # AdMob init, rewarded ad load/show wrapper
```

**Rule of thumb for the AI coding assistant:** `domain/` must never import `package:flutter`. All Flutter-specific code lives in `presentation/`, `application/`, and `ads/`. This keeps board/scoring logic 100% unit-testable without a widget tree.

## 5. Core Gameplay Mechanics

### 5.1 Grid
- Standard 8x8 grid (configurable constant, not hardcoded magic number).
- Each cell holds either empty or a reference to the `landmarkId`/color of the piece occupying it (for rendering).

### 5.2 Pieces
- **Normal pieces**: same shape library as classic block-blast (I, L, T, square, S/Z variants, singles, etc.), each cell in the shape rendered with the current civilization's landmark artwork.
- **Special piece ("Line/Column Clear")**: visually a single small square (distinct border/glow), NOT one of the normal multi-cell shapes. When placed on the board, it immediately clears the entire row and entire column it was placed in, **regardless of whether those lines are full**.
  - Spawn rate: probabilistic, tuned constant (e.g., appears roughly every 5–8 piece-tray refreshes), stored as a tunable constant, not hardcoded inline in logic.
- Piece tray shows 3 pieces at a time (standard block-blast convention); tray refills when all 3 are placed.

### 5.3 Scoring & Stage Progression
- Every civilization has 30 sub-stages.
- Each sub-stage defines a **target score** the player must reach to pass. Target score increases progressively across the 30 sub-stages (difficulty curve — exact formula/table to be defined in `civilizations_data.dart`, not hardcoded per-widget).
- Reaching the target score within the stage triggers the **Stage Win** state immediately (or at natural stopping point — to be finalized during implementation) and unlocks the next sub-stage.
- Completing sub-stage 30 of a civilization unlocks the next civilization on the map and marks the current one as "completed" (e.g., visual checkmark on the map).

### 5.4 Lose Condition
- Standard block-blast lose condition: the board is full/blocked such that **none of the 3 current tray pieces can be legally placed anywhere on the grid**.
- On lose:
  1. Show **Stage Lose screen**.
  2. Offer a **second chance**: "Watch an ad to retry" (Rewarded Ad via AdMob).
  3. If the player watches the ad successfully: the board is cleared and the stage restarts from scratch, **but current score for that stage run is preserved** (not reset) — i.e., they resume attempting to reach the target score with an empty board and the same accumulated score.
  4. If the player declines or the ad fails to load: stage resets fully (score lost), returning to stage select or restarting the stage from zero — exact fallback behavior confirmed with product owner during implementation.
  5. Only one second-chance retry is guaranteed per stage attempt unless product later decides to allow repeated rewarded retries (out of scope for v1 unless specified).

## 6. Screens

| Screen | Description |
|---|---|
| Splash | Logo, load persisted data. |
| Main Menu | Play (→ Map), Museum, Settings, (future: Leaderboard). |
| Map | Shows all 8 civilizations as an illustrated map with the **civilization's own emblem/icon** marking each (NOT a national flag). Locked civilizations shown greyed out/locked until previous one is 100% completed. Tapping an emblem opens Stage Select. |
| Stage Select | Grid/path of 30 sub-stage nodes for the selected civilization. Locked/unlocked/completed states shown. |
| Game Screen | The board, piece tray, score bar, target score indicator, pause/settings button. |
| Stage Win Dialog | Congrats, score summary, stars (optional), button to next stage or map. |
| Stage Lose Dialog | Score summary, "Watch Ad to Retry" button, "Give up / Retry from scratch" button. |
| Museum | Grid of all individual pieces (normal + special) unlocked so far, organized per civilization, shown as single square tiles (not as multi-cell shapes). Tapping a tile opens a detail view with the historical fact (localized ar/en) about that landmark. |
| Settings | Language toggle (Arabic/English), SFX volume slider. Accessible from Main Menu AND from an in-game pause/settings button during gameplay. |

## 7. Localization

- Supported languages: Arabic (default/primary) and English.
- All UI strings, stage names, and historical facts must exist in both `app_ar.arb` and `app_en.arb` (or an equivalent structured JSON per civilization for historical content, loaded via a repository — see §4).
- Arabic requires RTL layout — `Directionality` must be respected across all screens; test both LTR and RTL rendering for board/tray widgets, which should remain mirrored appropriately for RTL but the grid coordinate logic itself stays LTR-orientation-agnostic internally.
- Language changes apply instantly across the whole app (no restart required) via the Riverpod-managed locale provider.

## 8. Audio

- **SFX and background music are both in scope for v1** (updated 2026-08-29 — reverses an earlier "SFX only" decision).
- Required SFX events: piece pickup, piece placement (valid), invalid placement (rejected), row/column clear, special piece clear, stage win, stage lose.
- Background music: looping theme(s) (e.g., a menu theme and a gameplay theme), independently toggleable/mutable from SFX.
- Separate volume controls in Settings for SFX and music (each 0–100% or mute toggle), persisted locally, applied to playback instantly.
- **Build sequencing note:** audio (both SFX and music) is deliberately implemented last, only after all screens, UI, and gameplay logic are fully built — see `BUILD_PROMPTS.md` Phase 7.

## 9. Monetization (Ads)

- **AdMob** (not AdSense — AdSense does not apply to native apps).
- v1 required ad unit: **Rewarded Ad** for the stage-lose "second chance" continue flow.
- Ad loading/showing must be wrapped in a single `AdService` with graceful fallback if an ad fails to load (never block the player indefinitely).
- Test ads (AdMob sample ad unit IDs) must be used during development; real ad unit IDs only wired in before Play Store release.

## 10. Content Pipeline (Landmarks & Historical Data)

- Landmark artwork is generated externally (AI image generation from a fixed style prompt, one per landmark) and manually placed into `assets/civilizations/<civilization_id>/<landmark_id>.png`.
- Historical facts (short paragraph, ar/en) are authored separately and stored in `civilizations_data.dart` (or a JSON asset loaded at startup) keyed by `landmarkId`.
- Each civilization needs enough unique landmark artworks to cover all the distinct piece shapes used across its 30 stages (exact count to be finalized once shape library is locked).

## 11. Data Models (summary)

```dart
class Civilization {
  final String id;
  final String nameKey;       // localization key
  final String emblemAsset;   // map icon (not flag)
  final String themeColorHex;
  final List<Stage> stages;   // 30 stages
}

class Stage {
  final String id;
  final int orderIndex;       // 1..30
  final int targetScore;
}

class PieceDefinition {
  final String id;
  final List<List<bool>> shapeMatrix; // null/empty for the 1x1 special piece
  final bool isSpecial;               // true = line/column clear piece
  final String landmarkId;            // links to artwork + museum entry
}

class LandmarkInfo {
  final String id;
  final String civilizationId;
  final String nameKey;
  final String historicalFactKey;
  final String imageAsset;
}

class UserProgress {
  final Map<String, int> highestUnlockedStageIndexPerCivilization;
  final Set<String> unlockedLandmarkIds; // for museum
  final int totalScore; // optional, if a global score is desired
}

class UserSettings {
  final String languageCode; // 'ar' | 'en'
  final double sfxVolume;    // 0.0 - 1.0
}
```

## 12. Non-Functional Requirements

- Must run smoothly on mid/low-end Android devices (avoid unnecessary rebuilds; use `CustomPainter` for the board rather than hundreds of individual animated widgets where possible).
- Fully offline-playable (no network dependency except ad requests).
- Responsive layout for varying Android screen sizes/aspect ratios.
- App must not lose player progress on crash — persist progress after every stage completion, not only on app close.

## 13. Out of Scope for v1

- Leaderboards / online multiplayer.
- In-app purchases (only ads for v1).
- iOS release.
- More than 8 civilizations (future content update, not v1).

## 14. Open Questions (to resolve during development, track in PROJECT_STATE.md)

- Exact target-score progression formula across 30 stages per civilization.
- Exact special-piece spawn probability tuning.
- Full list of 8 civilizations and their landmark sets.
- Whether stage win triggers immediately on reaching target score or only when the player chooses to end/board fills.
