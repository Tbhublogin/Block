# AI Assistant Rules
 
These rules are binding for any AI coding assistant (e.g., in-editor AI in VS Code) working on this codebase. They exist to keep the project consistent, maintainable, and aligned with PRD.md. If any instruction from the user conflicts with these rules, the assistant should point out the conflict before proceeding, rather than silently breaking a rule.
 
## 1. Architecture Rules
 
1. **No game engine.** Never introduce Flame, Unity, Godot, or any other game engine/package. This project is pure Flutter + Dart widgets and `CustomPainter`.
2. **`domain/` must stay pure Dart.** Files under `lib/domain/` must never import `package:flutter/...`. Game logic (board engine, piece generation, scoring, win/lose detection) must be unit-testable without a widget tree.
3. **Respect the layered structure** defined in `PRD.md` §4 (`core/`, `domain/`, `data/`, `application/`, `presentation/`, `ads/`). Do not put business logic inside widget files. Do not put widget/UI code inside `domain/` or `data/`.
4. **State management is Riverpod only.** Do not introduce Provider, Bloc, GetX, or setState-heavy patterns for cross-widget state. Local, purely-visual widget state (e.g., an animation controller) is fine as `StatefulWidget` state.
5. **No hardcoded magic numbers/strings in logic or widgets.** Grid size, scoring targets, spawn probabilities, colors, and all user-facing text must come from `core/constants/`, `data/datasources/civilizations_data.dart`, or localization files — never inlined ad hoc in a widget or controller.
## 2. Localization Rules
 
6. **Every user-facing string must be localized** via the ARB/`intl` system (or the historical-content data layer for landmark facts). Never hardcode a Arabic or English string literal directly inside a widget's `Text(...)`.
7. Any new UI string added must be added to **both** `app_ar.arb` and `app_en.arb` in the same change — never add a key to only one language file.
8. Respect RTL for Arabic. Do not assume LTR layout assumptions when building new screens (use `Directionality`-aware widgets, avoid hardcoded `left`/`right` padding where `start`/`end` should be used).
## 3. Code Quality Rules
 
9. Write **null-safe, modern Dart** only. No deprecated APIs.
10. Every new class in `domain/logic/` that contains non-trivial rules (scoring, board placement validation, lose-condition detection) must be accompanied by at least a basic unit test in the corresponding `test/` folder.
11. Keep widgets small and composable. If a `build()` method exceeds roughly 100 lines, extract sub-widgets.
12. Follow standard Dart/Flutter naming and formatting conventions (`dart format` clean, no analyzer warnings introduced).
13. Do not leave `print()` debug statements in committed code — use a logging utility or remove before finishing a task.
## 4. Dependency Rules
 
14. **Do not add a new pub.dev package without explicitly flagging it to the user first** and stating why it's needed and what alternative was considered. The approved package list for v1 is: `flutter_riverpod`, `shared_preferences`, `hive` (or `sqflite` — pick one and stay consistent, do not mix both), `flutter_localizations`, `intl`, `google_mobile_ads`, `audioplayers` (or `soundpool` — pick one and stay consistent).
15. Never silently upgrade/downgrade Flutter SDK constraints or existing dependency versions without calling it out.
## 5. Gameplay Fidelity Rules
 
16. The special "line/column clear" piece must always be rendered as a single small square, visually distinct from all multi-cell shapes, per PRD §5.2. Do not implement it as a shape variant of the normal piece set.
17. The special piece clears its full row **and** full column on placement **unconditionally** (even if not full) — this is a deliberate deviation from standard block-blast rules and must not be "corrected" to standard behavior.
18. Lose condition = none of the current 3 tray pieces can be legally placed anywhere on the 8x8 grid. Do not implement alternative lose conditions (e.g., timers, move limits) unless explicitly requested.
19. On lose + successful rewarded ad: board resets, **score for the stage is preserved**, per PRD §5.4. This is a deliberate rule — do not reset score to zero on this path.
20. Stage target scores increase progressively across the 30 sub-stages of a civilization. Never hardcode a single global target score for all stages.
## 6. Ads Rules
 
21. Use **AdMob** (`google_mobile_ads`) exclusively. Never implement or reference Google AdSense — it is not applicable to native Android apps.
22. Always use AdMob **test ad unit IDs** during development. Never commit real production ad unit IDs into the repo in plaintext without explicit confirmation this is the release build step.
23. Ad-related code must fail gracefully — a failed/unavailable ad must never soft-lock the player from progressing or exiting the lose screen.
## 7. Content/Assets Rules
 
24. Landmark artwork files are supplied externally by the user (AI-generated, manually placed into `assets/`). The assistant should never attempt to generate, fetch, or hallucinate image assets — only reference expected file paths/naming conventions.
25. Historical fact text (museum content) must be treated as real user-provided content once supplied — do not invent historical facts. If content is missing for a landmark, use a clearly marked placeholder (e.g., `TODO_HISTORICAL_FACT`) rather than fabricating information.
## 8. Process Rules
 
26. Before starting any new feature/task, the assistant should check `PROJECT_STATE.md` for current phase and pending decisions.
27. After completing any meaningful unit of work (a screen, a controller, a data model), the assistant must update `PROJECT_STATE.md`'s "Completed" and "Next Steps" sections in the same session — do not leave it stale.
28. If a requirement in the current user request contradicts `PRD.md`, the assistant should flag the contradiction explicitly rather than silently implementing the new instruction or silently keeping the old one.
29. Prefer editing/extending existing files over creating parallel/duplicate files that do similar things (e.g., do not create a second board widget instead of extending `board_widget.dart`).
30. Since this AI assistant writes directly into project files (no copy/paste step), it must double-check import paths, file names, and that it is editing the correct file before writing — mistakes are immediately live in the codebase