# ملف البرومبتات (Build Prompts)

مجموعة برومبتات مرتبة بالتسلسل لاستخدامها مع الذكاء الاصطناعي المدمج داخل VS Code. استخدمها **بالترتيب** — كل مرحلة تعتمد على المرحلة التي قبلها. حاول دائماً إبقاء ملفات `PRD.md` و `AI_RULES.md` و `PROJECT_STATE.md` مرفقة كسياق (context) إذا كانت الأداة تدعم ذلك، حتى يبقى الذكاء الاصطناعي متسق بين الجلسات المختلفة.

## شرح الرموز

- 🟢 **لا يحتاج مدخلات خارجية** — الذكاء الاصطناعي يقدر ينفذ هذه المرحلة بالكامل من الكود والمنطق فقط.
- 🔴 **يتطلب منك إرفاق شيء** — لازم ترفق/تلصق صور أو نصوص عربية أو أسماء ملفات قبل أو أثناء هذا البرومبت. المتطلبات موضحة بالتفصيل تحت كل برومبت من هذا النوع.

---

## المرحلة 0 — إعداد المشروع

### برومبت 0.1 🟢
```
Read PRD.md, AI_RULES.md, and PROJECT_STATE.md in this repository before doing anything else.

Initialize a new Flutter project for this game following the exact folder structure defined in PRD.md section 4 (core/, domain/, data/, application/, presentation/, ads/). 

Set up:
- pubspec.yaml with these dependencies only: flutter_riverpod, shared_preferences, hive, hive_flutter, flutter_localizations (sdk), intl, google_mobile_ads, audioplayers.
- Null-safety enabled, latest stable Flutter/Dart constraints.
- Empty placeholder files for every path listed in PRD.md section 4, each with a short `// TODO` comment describing its responsibility (do not implement logic yet).
- A basic main.dart that just runs an empty MaterialApp with a placeholder Scaffold saying "Under construction".

After finishing, update PROJECT_STATE.md: mark Phase 0 (Project Scaffolding) as complete and list the new next steps as Phase 1 (Localization + Theme setup).
```

### برومبت 0.2 🟢
```
Set up the localization system as defined in PRD.md section 7:
- Configure flutter_localizations + intl with ARB files: lib/l10n/app_ar.arb (Arabic, default) and lib/l10n/app_en.arb (English).
- Add a `languageProvider` (Riverpod) in application/settings_controller.dart that holds the current Locale, defaulting to Arabic, and persists the choice via shared_preferences.
- Wire MaterialApp to use this provider for its `locale`, with `supportedLocales` = [ar, en] and proper localizationsDelegates.
- Add placeholder strings: appTitle, mainMenuPlay, mainMenuMuseum, mainMenuSettings — in both ARB files.
- Ensure the app defaults to RTL layout correctly when Arabic is active (test with Directionality).

Update PROJECT_STATE.md accordingly when done.
```

---

## المرحلة 1 — منطق اللعبة الأساسي (Dart خالص، بدون واجهات)

### برومبت 1.1 🟢
```
Implement domain/models/board_cell.dart, domain/models/piece.dart, and domain/models/game_result.dart exactly as summarized in PRD.md section 11, expanding fields as needed for a working board engine. Piece must support:
- shapeMatrix: List<List<bool>> for normal pieces (variable size, e.g. up to 5x5).
- isSpecial: bool — true means this is the single small-square "line/column clear" piece (shapeMatrix will just be a 1x1 true).
- landmarkId: String — a reference key only, do NOT reference any actual image asset yet.

These files must contain zero Flutter imports (pure Dart), per AI_RULES.md rule 2.
```

### برومبت 1.2 🟢
```
Implement domain/logic/board_engine.dart as a pure Dart class `BoardEngine`:
- Holds an 8x8 grid state (constant from core/constants, not hardcoded inline).
- Method `canPlace(Piece piece, int row, int col)` → bool, checking bounds and cell occupancy.
- Method `place(Piece piece, int row, int col)` → applies the piece to the grid, returns which rows/columns became full as a result.
- Method `clearLines(List<int> rows, List<int> cols)` → clears those rows/columns from the grid.
- Special handling: if piece.isSpecial is true, placing it must clear its full row AND full column UNCONDITIONALLY, even if not full (per PRD.md section 5.2 and AI_RULES.md rule 17) — this is intentional, do not treat it as a bug.

Write unit tests in test/domain/board_engine_test.dart covering: normal placement, boundary rejection, overlap rejection, full-row clear, full-column clear, and the special piece's unconditional clear behavior.
```

### برومبت 1.3 🟢
```
Implement domain/logic/piece_generator.dart:
- Generates a tray of 3 pieces at a time from a fixed shape library (standard block-blast shapes: I variants, L variants, T, square, S/Z, singles — define the shape library as a constant list in core/constants/piece_shapes.dart).
- Includes a tunable constant SPECIAL_PIECE_SPAWN_RATE in core/constants/ (not hardcoded inline) controlling how often a special (line/column clear) piece appears in a generated tray, per PRD.md section 5.2.
- landmarkId assignment on generated pieces should be left as a generic placeholder for now (e.g., "placeholder") — actual landmark mapping comes in a later phase once civilization content is provided.

Add unit tests validating tray size, shape validity, and that the special piece spawn rate roughly matches the configured probability over many trials.
```

### برومبت 1.4 🟢
```
Implement domain/logic/score_calculator.dart and domain/logic/lose_condition_checker.dart:
- score_calculator.dart: pure functions to compute score gained from a placement (cells filled) and from line/column clears (bonus per line, bonus should be a named constant, not a magic number).
- lose_condition_checker.dart: given the current board state and current 3-piece tray, returns true if NONE of the 3 pieces can be legally placed anywhere on the grid (per PRD.md section 5.4) — iterate all rotations only if the shape library requires rotation, otherwise assume fixed orientations per PRD (confirm assumption in code comments).

Add unit tests for both, including an explicit "guaranteed lose" board scenario.
```

---

## المرحلة 2 — طبقة التطبيق (Riverpod Controllers)

### برومبت 2.1 🟢
```
Implement application/game_controller.dart as a Riverpod StateNotifier that orchestrates BoardEngine + PieceGenerator + ScoreCalculator + LoseConditionChecker into a single game session state (current board, current tray, current score, target score for the active stage, isLost, isWon flags). Expose methods: startStage(Stage stage), attemptPlacePiece(Piece piece, int row, int col), and resetBoardKeepingScore() (needed later for the ad-continue flow per PRD.md section 5.4).

This controller must depend only on domain/ logic, not on any UI widget.
```

### برومبت 2.2 🟢
```
Implement application/progress_controller.dart (Riverpod) responsible for:
- Tracking highestUnlockedStageIndexPerCivilization and completed civilizations, persisted via Hive (per PRD.md section 3 tech stack).
- Method markStageCompleted(civilizationId, stageIndex) that unlocks the next stage, or unlocks the next civilization if stageIndex == 30.
- Method isCivilizationUnlocked(civilizationId) and isStageUnlocked(civilizationId, stageIndex).

Implement application/museum_controller.dart tracking unlockedLandmarkIds (Set<String>), persisted via Hive, with a method unlockLandmark(String landmarkId) to be called whenever a piece with a new landmarkId is placed for the first time in gameplay.
```

---

## المرحلة 3 — طبقة المحتوى 🔴

### برومبت 3.1 🔴 يتطلب منك إرفاق بيانات
```
I will now provide the full content list for [CIVILIZATION NAME, e.g. "Iraq / Mesopotamia"]. Using this content, populate data/datasources/civilizations_data.dart (or a JSON asset if you prefer, loaded at startup) with:
- The Civilization entry (id, nameKey, emblemAsset path, themeColorHex).
- All Stage entries (30 total) with progressively increasing targetScore values, following [DESCRIBE YOUR PREFERRED CURVE, e.g. "linear from 500 to 5000" or "let the assistant propose a curve and I will approve it"].
- All LandmarkInfo entries for this civilization (id, nameKey, imageAsset path, historicalFactKey).

Add the corresponding nameKey and historicalFactKey strings into app_ar.arb (using the Arabic text I provide below) and app_en.arb (translate my Arabic text into natural, accurate English — do not invent facts beyond what I provide).

--- DATA I AM PROVIDING BELOW ---
[PASTE HERE: list of landmark names in Arabic + the historical fact paragraph for each, in Arabic. Also specify each image file name you will place in assets/civilizations/iraq/, e.g. ziggurat_of_ur.png, so the assistant maps imageAsset paths correctly to the landmarkId.]
```

**⚠️ ما يجب عليك إرفاقه/إرساله في هذا البرومبت، في كل مرة تبدأ فيها بحضارة جديدة:**
1. قائمة أسماء المعالم التاريخية (بالعربي، ويمكن أيضاً بالإنجليزي إن كان لديك ترجمة مسبقة).
2. الفقرة التاريخية الخاصة بكل معلم، **بالعربي** (الذكاء الاصطناعي سيتولى ترجمتها للإنجليزية).
3. اسم ملف الصورة الذي ستعتمده لكل معلم (حتى يتطابق الكود مع الأصول لاحقاً) — لا تحتاج إرفاق الصورة الفعلية في هذه الخطوة، فقط الأسماء التي ستستخدمها.
4. اسم ملف أيقونة/شعار الحضارة (المستخدم في شاشة الخريطة).
5. تفضيلك لمنحنى صعوبة السكور، أو إعطاء الذكاء الاصطناعي الصلاحية لاقتراح واحد بنفسه.

### برومبت 3.2 🔴 يتطلب منك إرفاق الصور
```
I am attaching the final PNG image assets for [CIVILIZATION NAME]'s landmarks and emblem now. Place them into assets/civilizations/[civilization_id]/ using the exact filenames referenced in civilizations_data.dart from the previous step. Register all new files in pubspec.yaml's assets section. Do not regenerate, edit, or alter the images — only wire them into the project.
```

**⚠️ ما يجب عليك إرفاقه:** ملفات الصور PNG الفعلية (بخلفية شفافة، والناتجة من معالجتك بالذكاء الاصطناعي) — صورة واحدة لكل معلم، بالإضافة لأيقونة/شعار الحضارة.

> كرر البرومبتين 3.1 و 3.2 مرة واحدة لكل حضارة (8 مرات إجمالاً).

---

## المرحلة 4 — واجهة اللعب الأساسية

### برومبت 4.1 🟢
```
Build presentation/widgets/board_widget.dart using CustomPainter to render the 8x8 grid from game_controller's state (per PRD.md section 4/9). Each occupied cell should render the landmarkId's associated image asset (looked up via a repository, not hardcoded) clipped to the cell bounds. Empty cells render a simple placeholder background using the current civilization's themeColorHex.

Keep this widget purely presentational — it reads from game_controller (Riverpod) and calls attemptPlacePiece on drag-drop; it must not contain game rules itself.
```

### برومبت 4.2 🟢
```
Build presentation/widgets/piece_tray_widget.dart and draggable_piece_widget.dart implementing drag-and-drop of the 3 current tray pieces onto board_widget, using Draggable/DragTarget. The special (line/column clear) piece must render visually distinct — smaller, single square, with a glowing/highlighted border — per PRD.md section 5.2 and AI_RULES.md rule 16. Play the correct SFX (pickup/valid placement/invalid placement) via a not-yet-implemented `AudioService` interface — stub it with TODO calls for now; the real AudioService is implemented later in Phase 7, by design, after all screens and UI are complete.
```

### برومبت 4.3 🟢
```
Build presentation/screens/game_screen.dart combining score_bar_widget.dart (current score / target score), board_widget.dart, piece_tray_widget.dart, and an in-game settings icon button that opens settings_screen.dart as an overlay/dialog (per PRD.md section 6, settings must be reachable both from Main Menu and in-game). Wire win detection (score >= target) to show stage_win_dialog.dart, and lose detection to show stage_lose_dialog.dart per PRD.md section 5.3/5.4.
```

---

## المرحلة 5 — الإعلانات

### برومبت 5.1 🟢
```
Implement ads/ad_service.dart wrapping google_mobile_ads for a Rewarded Ad only, using AdMob TEST ad unit IDs for now (per AI_RULES.md rule 22). Wire it into stage_lose_dialog.dart's "Watch Ad to Retry" button: on successful ad completion, call game_controller.resetBoardKeepingScore() and dismiss the dialog; on failure/decline, follow the fallback behavior noted as an open question in PRD.md section 14 — for now, implement "full stage reset, return to stage select" and flag this clearly in PROJECT_STATE.md as pending my confirmation.
```

**ملاحظة:** الصوت (SFX + الموسيقى) لم يعد جزءاً من هذه المرحلة — تم تأجيله عمداً إلى المرحلة 7، بعد اكتمال كل الشاشات والواجهة ومنطق اللعب بالكامل (قرار 2026-08-29، راجع PROJECT_STATE.md).

---

## المرحلة 6 — الخريطة، اختيار المراحل، المتحف، القوائم

### برومبت 6.1 🟢 (الأصول تم توفيرها مسبقاً في المرحلة 3)
```
Build presentation/screens/map_screen.dart: display all 8 civilizations using their emblemAsset icons (NOT flags, per PRD.md section 6) positioned on a background map image [I will provide this background image — see note below]. Locked civilizations (per progress_controller) render greyed out/locked. Tapping an unlocked emblem navigates to stage_select_screen.dart for that civilization.
```

**⚠️ ما يجب عليك إرفاقه بشكل منفصل:** صورة خلفية الخريطة الكاملة (صورة واحدة توضح كل المناطق/الحضارات بشكل مرسوم)، إذا كنت تريد خريطة مرسومة مخصصة بدل شبكة بسيطة من الأزرار. إذا لم تكن هذه الصورة جاهزة بعد، أخبر الذكاء الاصطناعي أن يبني تخطيطاً مؤقتاً بسيطاً (مثلاً شبكة قابلة للتمرير من الشعارات) لحين جهوزية التصميم النهائي.

### برومبت 6.2 🟢
```
Build presentation/screens/stage_select_screen.dart: show all 30 sub-stages for the selected civilization as a node path or grid (locked/unlocked/completed states from progress_controller). Tapping an unlocked node starts game_controller.startStage() and navigates to game_screen.dart.
```

### برومبت 6.3 🟢
```
Build presentation/screens/museum_screen.dart per PRD.md section 6: a grid of single square tiles, one per unlocked landmark (museum_controller), grouped by civilization with a section header per civilization. Locked/undiscovered landmarks show a silhouette/lock icon instead of the artwork. Tapping an unlocked tile opens a detail view showing the landmark's name and historicalFactKey text (already localized from Phase 3 content). Add a small "X of Y discovered" counter per civilization section.
```

### برومبت 6.4 🟢
```
Build presentation/screens/main_menu_screen.dart (Play → map_screen, Museum → museum_screen, Settings → settings_screen) and presentation/screens/settings_screen.dart (language toggle ar/en calling settings_controller, and an SFX volume slider UI element calling settings_controller — wiring to the actual AudioService happens later in Phase 7, build the slider/state now against a stub), reachable both standalone from the menu and as an overlay from within game_screen, per PRD.md section 6.
```

---

## المرحلة 7 — الصوت والموسيقى (تُنفَّذ بعد اكتمال كل الشاشات والواجهة ومنطق اللعب بالكامل)

> **قرار 2026-08-29:** الصوت (مؤثرات SFX + موسيقى خلفية) يُضاف عمداً في آخر مراحل البناء، بعد أن تكون كل الشاشات والـ UI ومنطق اللعب جاهزة تماماً — وليس مبكراً كما كان مخططاً سابقاً. هذا يُلغي القرار السابق "SFX only, no music" في PRD.md §8/§13؛ تلك الفقرات يجب تحديثها لتعكس أن الموسيقى الآن ضمن نطاق v1، فقط بترتيب تنفيذ متأخر.

### برومبت 7.1 🟢
```
Now that all screens, UI, and gameplay logic are fully complete, implement AudioService (core/services/audio_service.dart) using audioplayers. It must support BOTH of the following, per the updated PRD.md section 8:

1. Short SFX for: piece_pickup, piece_place_valid, piece_place_invalid, line_clear, special_clear, stage_win, stage_lose — volume read from settings_controller's persisted sfxVolume, updating live when changed in Settings.
2. Looping background music with an independent musicVolume + musicEnabled toggle — add these fields to UserSettings and settings_controller (persisted via shared_preferences the same way as sfxVolume), and play/pause music appropriately per screen (e.g., a menu theme on main_menu/map/stage_select, a gameplay theme during game_screen), stopping cleanly on navigation without overlapping tracks.

Update settings_screen.dart to add a music volume slider and mute toggle next to the existing SFX slider, matching the existing settings dialog visual style (per BUILD_PROMPTS_ADDENDUM_v2.md).

Reference expected file paths (I will provide the actual files afterward once generated):
- assets/audio/sfx/: pickup.mp3, place_valid.mp3, place_invalid.mp3, line_clear.mp3, special_clear.mp3, stage_win.mp3, stage_lose.mp3
- assets/audio/music/: main_menu_theme.mp3, gameplay_theme.mp3 (exact track names/count to be finalized once music is generated)
```

**⚠️ ملاحظة:** ستحتاج لإرفاق ملفات المؤثرات الصوتية السبعة وملفات الموسيقى في برومبت لاحق بمجرد تجهيزها (SFX من مكتبة جاهزة أو مولّدة، والموسيقى عبر Soundraw كأداة أساسية أو Mubert كبديل — بنفس أسلوب البرومبت 3.2).

---

## المرحلة 8 — التلميع والمراجعة النهائية (Polish & QA)

### برومبت 8.1 🟢
```
Review the full app for AI_RULES.md compliance: no hardcoded strings outside ARB files, no game-engine dependency, domain/ free of Flutter imports, no leftover print() statements, no unapproved dependencies in pubspec.yaml. Report any violations found and fix them.
```

### برومبت 8.2 🟢
```
Add a splash_screen.dart that loads persisted Hive/shared_preferences data before navigating to main_menu_screen.dart, with a simple logo placeholder [I will provide the real logo image separately].
```

**⚠️ ما يجب عليك إرفاقه بشكل منفصل:** صورة شعار/أيقونة اللعبة النهائية، عند جهوزيتها — تُستخدم لشاشة البداية (Splash) وأيقونة تطبيق الأندرويد.

---

## تذكيرات مهمة لكل جلسة عمل

- دائماً أخبر الذكاء الاصطناعي أن يعيد قراءة ملف `PROJECT_STATE.md` أولاً إذا كنت تبدأ جلسة/محادثة جديدة.
- المعلومات التاريخية تصلك دائماً منك أنت **بالعربي أولاً**، والذكاء الاصطناعي يترجمها للإنجليزية كجزء من تعبئة ملفات الـ ARB — لا تسمح له أبداً باختلاق محتوى عربي من عنده.
- أي برومبت مُعلَّم بـ 🔴 لن ينتج نتيجة حقيقية وكاملة إلا بعد أن ترفق المتطلبات الموضحة تحته — يمكن للذكاء الاصطناعي مع ذلك أن يبني هيكل الكود ويستخدم عناصر مؤقتة (placeholders) إذا أردت تحرير باقي العمل أولاً.
