# Project State

**Last updated:** 2026-08-29
**Current phase:** Phase 0 — Project Scaffolding (complete). Phase 1 — Localization + Theme setup (next).

> This file must be kept up to date by whoever (human or AI) makes changes to the project. Read this file first before starting any new work session.

---

## 1. Summary of Where We Are

- Game concept, mechanics, monetization model, and content pipeline are fully defined (see `PRD.md`).
- Flutter project initialized (Flutter 3.47.1 stable / Dart 3.13.1, android platform only, package `block_civilizations`, applicationId `com.example.block_civilizations` — applicationId to revisit before release since the final app name is undecided).
- pubspec.yaml populated with the v1 dependency list: `flutter_riverpod`, `shared_preferences`, `hive`, `hive_flutter`, `flutter_localizations` (sdk), `intl`, `google_mobile_ads`, `audioplayers` (plus `flutter_test`/`flutter_lints` dev deps).
- Empty placeholder files created for every path in `PRD.md` §4, each with a `// TODO` responsibility comment; directories without defined filenames (`core/localization/`, `core/utils/`, `domain/repositories_interfaces/`, `data/repositories/`, `data/models_dto/`) have README stubs.
- `main.dart` + `app.dart` run a placeholder MaterialApp ("Under construction"). Strings are temporarily hardcoded; they move to ARB files in Phase 1.
- Smoke test in `test/widget_test.dart` (replaced the generated counter test).
- Verified: `flutter pub get` OK, `dart format` clean, `flutter analyze` 0 issues, `flutter test` all pass, `flutter build apk --debug` succeeds.
- Android toolchain fixed on this machine: SDK "licenses" are now accepted implicitly by installing the required packages — NDK 28.2.13676358, build-tools 36.0.0, platforms;android-35, cmake 3.22.1 — via the new sdk-style `sdkmanager` syntax (e.g. `sdkmanager --install "ndk/28.2.13676358"`; the old `pkg;version` syntax is broken in the new Android CLI and reports "Package not found"). `flutter doctor --android-licenses` is a no-op warning on this SDK version.
- Note: the 10 finalized Mesopotamia landmark PNGs are **not in the repo** — they must be copied into `assets/civilizations/iraq/` before Phase 3 asset wiring.
- No civilizations, stages, or landmark data have been finalized/entered yet.
- No art assets have been generated yet.

## 2. Completed

- [x] Core game concept locked: Block-Blast-style puzzle reskinned per civilization.
- [x] Decided: 8 civilizations total, 30 sub-stages each (240 stages total).
- [x] Decided: normal pieces = standard block-blast shape library, rendered with landmark art.
- [x] Decided: special piece = single small square, clears full row + column unconditionally on placement.
- [x] Decided: stage pass condition = reach a target score that increases per sub-stage.
- [x] Decided: lose condition = standard block-blast (no tray piece fits anywhere).
- [x] Decided: lose flow = show lose screen → offer rewarded ad → on success, board clears, score preserved, retry.
- [x] Decided: Map screen shows each civilization via its own emblem/icon, not a national flag.
- [x] Decided: Museum screen shows all individual pieces (normal + special) as single square tiles per civilization, tapping opens historical info.
- [x] Decided: Settings screen (language ar/en toggle + SFX volume) accessible from both Main Menu and in-game.
- [x] Decided (superseded 2026-08-29 — see below): initial audio scope was SFX only, no background music.
- [x] Decided: Monetization = Google AdMob (corrected from an earlier incorrect mention of AdSense), rewarded ad for continue flow only in v1.
- [x] Tech stack decided: Flutter/Dart, no game engine, Riverpod, shared_preferences + Hive/sqflite, flutter_localizations + intl, google_mobile_ads, audioplayers/soundpool.
- [x] Full folder/architecture structure defined (`PRD.md` §4).
- [x] `AI_RULES.md` written and agreed.
- [x] AI image-generation prompt template created for landmark artwork consistency.
- [x] All 10 Mesopotamia landmark artworks finalized (transparent PNG), including Ziggurat of Ur — Iraq/Mesopotamia content is 100% asset-ready.
- [x] Decided: no star-rating mechanic on the museum screen (rejected, not part of the game).
- [x] Decided: no coin/currency system anywhere in the app (rejected, not part of the game).
- [x] Decided (2026-08-29, supersedes the earlier "SFX only" decision): background music **is** now in scope for v1, alongside SFX. Sequencing decision: both SFX and music are implemented **last**, only after all screens, UI, and gameplay logic are fully built (moved to Phase 7 in `BUILD_PROMPTS.md`, after the screens phase and before final polish). `PRD.md` §8 and §13 should be updated to drop "no background music" / SFX-only language.
- [x] Phase 0 — Project Scaffolding complete (2026-08-29): Flutter project initialized, all PRD §4 placeholder files created, dependencies added, analyzer/tests/build verified.
- [x] Decided (2026-08-29, resolves earlier open questions): persistence = **Hive** (+ hive_flutter, with shared_preferences for simple settings); audio = **audioplayers**. Neither sqflite nor soundpool will be used.

## 3. Open Decisions / Not Yet Finalized

- [ ] Final list of all 8 civilizations (only civilization #1 = Iraq/Mesopotamia confirmed so far).
- [ ] Full landmark roster per civilization (need enough unique landmarks to cover all piece shapes across 30 stages).
- [ ] Exact target-score formula/table across the 30 sub-stages per civilization (difficulty curve).
- [ ] Exact special-piece spawn probability/tuning constant.
- [ ] Exact behavior if the player declines the rewarded ad or it fails to load on the lose screen (full reset vs. return to stage select) — flagged as open question in PRD §14.
- [ ] Whether "stage win" triggers the instant the target score is hit mid-board, or only at a natural stopping point.
- [ ] Final app name (candidates discussed: "إرث" / "Legacy Blast", "زقورة" / Ziggurat, etc. — not finalized).
- [ ] Board grid size confirmed as 8x8 (standard) — not yet explicitly reconfirmed by user, currently just PRD default.
- [ ] ~~Persistence choice between Hive and sqflite not yet finalized~~ **Resolved 2026-08-29: Hive** (see Completed).
- [ ] ~~Persistence choice between audioplayers and soundpool not yet finalized~~ **Resolved 2026-08-29: audioplayers** (see Completed).
- [ ] Stage progress denominator on stage_select_screen top bar (e.g. "X/90") — what it should represent is still undefined.

## 4. Immediate Next Steps

1. Phase 1 (BUILD_PROMPTS 0.2): localization scaffolding — `l10n.yaml`, `lib/l10n/app_ar.arb` (default) / `app_en.arb`, `languageProvider` in `application/settings_controller.dart` persisted via shared_preferences, wire MaterialApp delegates/locales, add appTitle/mainMenuPlay/mainMenuMuseum/mainMenuSettings strings (and move the current hardcoded placeholder strings into ARB).
2. Base theme setup (`core/theme/app_theme.dart`).
3. Implement `domain/logic/board_engine.dart` (pure Dart, unit-tested) — grid state, placement validation, row/column clear detection (BUILD_PROMPTS 1.2).
4. Implement `domain/logic/piece_generator.dart` including special-piece spawn logic (BUILD_PROMPTS 1.3).
5. Implement `domain/logic/score_calculator.dart` and `lose_condition_checker.dart` (BUILD_PROMPTS 1.4).
6. Build a minimal `game_screen.dart` with a placeholder color-based board (no landmark art yet) to validate core loop end-to-end before wiring real assets.
7. Only after the core loop is validated: wire in civilization #1 (Iraq) real data/art and build Map + Stage Select screens around it.

## 5. Content Status

| Civilization | Status | Landmarks defined | Art generated |
|---|---|---|---|
| 1. Iraq (Mesopotamia) | Confirmed as first civilization, v1 scope | Yes (10/10: Hanging Gardens, Tower of Babel, Lamassu, Lion of Babylon, Naram-Sin Stele, Hammurabi Stele, Cuneiform Tablet, Golden Lyre of Ur, Ishtar Gate, Ziggurat of Ur) | Yes — all 10 landmark artworks complete (transparent PNG), including Ziggurat of Ur (last missing piece, provided 2026-08-29) |
| 2–8 (post-launch) | Deferred to post-launch content updates, not part of v1 | No | No |

## 6. Decision Log (chronological)

- **2026-08-28:** Initial concept discussion — Block Blast + civilizations theme approved.
- **2026-08-28:** Corrected monetization plan from Google AdSense (invalid for native apps) to Google AdMob.
- **2026-08-28:** Finalized special piece behavior, lose/retry flow, 30 sub-stages per civilization (up from an earlier unspecified count), museum screen concept, settings screen scope (language + SFX volume only, no other options), and map using civilization emblems instead of country flags.
- **2026-08-28:** PRD.md, AI_RULES.md, and this PROJECT_STATE.md created.
- **2026-08-29:** Ziggurat of Ur artwork (final missing landmark for Iraq/Mesopotamia) provided. All 10 Mesopotamian landmark artworks are now complete — content for civilization #1 is fully asset-ready.
- **2026-08-29:** Decided: **no star-rating mechanic** on the museum screen. The 3-star rating row shown in the museum mockup is rejected and must not be implemented — museum tiles show artwork, name, and lock state only.
- **2026-08-29:** Decided: **no coin/currency system**. The coin counter shown in the museum mockup is rejected and must not be implemented anywhere in the app — no currency economy exists in this game.
- **2026-08-29:** Decided: background music is added back into v1 scope (reversing the earlier SFX-only decision), but sequenced deliberately last — audio (SFX + music) is implemented only after all screens, UI, and gameplay logic are fully complete. `BUILD_PROMPTS.md` restructured: Ads is now Phase 5 (unchanged position, audio removed from it), screens remain Phase 6, a new Audio & Music phase is Phase 7, and Polish/QA moved to Phase 8.
- **2026-08-29:** Phase 0 scaffolding executed. Resolved the "pick one" choices: **Hive** for structured persistence, **audioplayers** for audio. Fixed the local Android toolchain (NDK 28.2.13676358, build-tools 36.0.0, platform 35, CMake 3.22.1 installed; the new Android CLI sdkmanager requires sdk-style paths like `"ndk/28.2.13676358"`). Debug APK builds successfully.

---

**Instruction to AI assistant:** After every work session, update sections 2, 3, 4, 5, and 6 above to reflect new progress before ending the session.
