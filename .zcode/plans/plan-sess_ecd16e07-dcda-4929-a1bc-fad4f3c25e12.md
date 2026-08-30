# Implement PieceGenerator (BUILD_PROMPTS 1.3)

## Context found
- `lib/domain/logic/piece_generator.dart` and `lib/core/constants/piece_shapes.dart` already exist as 5–6 line TODO stubs — we fill them, not create files.
- `Piece` (`lib/domain/models/piece.dart`) is const-constructible with `id`, `shapeMatrix`, `isSpecial`, `landmarkId`; special pieces can only be built via `Piece.special` (default ctor asserts `!isSpecial`). The 1.1 plan recorded that Piece was made const *specifically* so `piece_shapes.dart` could be a const list.
- `game_constants.dart` has `gridSize = 8` and its own TODO reserving `SPECIAL_PIECE_SPAWN_RATE`.
- PRD 5.2: special piece appears "roughly every 5–8 piece-tray refreshes" → **per-tray** probability, not per-piece.
- AI_RULES: no Flutter imports in `domain/` (#2), no magic numbers (#5). Package name: `block_civilizations`. Tests use `flutter_test` with `group('ClassName')` + lowercase-sentence test names in `test/domain/`.

## Changes

### 1. `lib/core/constants/game_constants.dart` — add three constants (next to `gridSize`)
- `const double SPECIAL_PIECE_SPAWN_RATE = 1 / 6;` — per-tray probability that one of the 3 pieces is special (≈ every 6 tray refreshes, centered in PRD 5.2's 5–8 example range). Kept in SCREAMING_SNAKE_CASE exactly as named in BUILD_PROMPTS 1.3 and this file's existing TODO.
- `const int traySize = 3;` — PRD 5.2 "tray shows 3 pieces"; avoids a magic number (AI_RULES #5).
- `const String placeholderLandmarkId = 'placeholder';` — the generic placeholder until civilization content lands.
- Trim the TODO line to only mention the remaining 1.4 scoring constants.

### 2. `lib/core/constants/piece_shapes.dart` — const shape library
- `const List<Piece> pieceShapeLibrary` with 27 standard block-blast shapes (all with `landmarkId: placeholderLandmarkId`):
  - **Singles**: 1×1
  - **I variants**: horizontal + vertical at lengths 2, 3, 4, 5 (8 shapes)
  - **Squares**: 2×2, 3×3
  - **Small L / corners** (3 cells, 2×2): all 4 rotations
  - **Large L** (4 cells, 3×3): all 4 rotations
  - **T** (4 cells): all 4 orientations (`t_up/t_down/t_left/t_right`)
  - **S/Z**: horizontal + vertical for each (4 shapes)
  - Shape ids are snake_case (`i3_horiz`, `l_small_top_left`, …), matching the `l_shape` convention in existing tests.
- `const Piece specialPiece = Piece.special(id: 'special', landmarkId: placeholderLandmarkId);` — so every piece definition lives in core/constants and the generator stays pure selection logic.
- All entries are compile-time consts (max dimension 5 < gridSize 8).

### 3. `lib/domain/logic/piece_generator.dart` — `PieceGenerator` class
```dart
class PieceGenerator {
  PieceGenerator({Random? random});   // injectable Random (seedable for tests); defaults to Random()
  List<Piece> generateTray();
}
```
`generateTray()` semantics:
1. Fill `traySize` slots by picking uniformly from `pieceShapeLibrary` **with replacement** (duplicate shapes in one tray are standard block-blast behavior).
2. Roll once per tray: `nextDouble() < SPECIAL_PIECE_SPAWN_RATE` → replace one random slot with a copy of `specialPiece`.
3. Each returned piece is a fresh `Piece` with a **deep-copied matrix** (the const library would otherwise share mutable lists) carrying the shape's id and the placeholder landmarkId.
- Pure Dart: only `dart:math` + core/constants + domain/models imports (AI_RULES #2). Doc comments cite BUILD_PROMPTS 1.3 / PRD 5.2 / AI_RULES #5, matching board_engine.dart's style.

### 4. `test/domain/piece_generator_test.dart` — new tests
Group `PieceGenerator` with a seeded `Random` throughout (deterministic, no flakiness by construction):
- **Tray size**: repeated `generateTray()` calls always return exactly `traySize` pieces.
- **Shape validity**: every library entry is non-empty, rectangular, `filledCellCount ≥ 1`, and fits the grid (`rows/cols ≤ gridSize`); every piece from many generated trays is either a library shape (matched by matrix equality) or a special (1×1, `isSpecial == true`).
- **Placeholder landmark**: every generated piece (normal and special) has `landmarkId == placeholderLandmarkId`.
- **Spawn rate over many trials**: seed `Random(42)`, generate 2000 trays, count trays containing a special; assert the frequency is within 0.04 of `SPECIAL_PIECE_SPAWN_RATE` (~4.8σ at n=2000 — effectively non-flaky), plus sanity bounds (at least one special appeared, not every tray special).
- **Special piece shape**: the first special encountered is 1×1, `isSpecial == true`, id `special`.
- **Seed determinism**: two generators with the same seed produce identical tray sequences (validates the injectable-Random design).

### 5. `PROJECT_STATE.md` (AI_RULES #27)
Update the phase line, move BUILD_PROMPTS 1.3 out of "Immediate Next Steps", and record the piece generator in the implemented section with the chosen spawn-rate value.

## Verification
`dart format` on the four touched Dart files, then `flutter analyze` (0 issues) and `flutter test` (all suites pass, including existing board_engine/models tests).