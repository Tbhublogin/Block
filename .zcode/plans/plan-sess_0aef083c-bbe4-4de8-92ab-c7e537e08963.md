## Context

BUILD_PROMPTS 1.4 (the task) asks for two pure-logic files whose stubs already exist (`lib/domain/logic/score_calculator.dart`, `lib/domain/logic/lose_condition_checker.dart` — each currently just a doc comment + TODO). Everything they need is already in place: `BoardEngine.canPlace/place` and `PlacementResult(fullRows, fullCols)` (board_engine.dart:65,92), `Piece.filledCellCount`/`rows`/`cols`, the mutable public `engine.grid`, and `gridSize = 8`.

Two facts shape the design:
- **Scoring numbers are unspecified in the PRD** — you chose **1 point per filled cell, 10 bonus per cleared line**. They'll be named constants in `game_constants.dart`, whose existing TODO explicitly reserves a spot for scoring constants (AI_RULES #5: no magic numbers).
- **No rotation iteration needed**: `piece_shapes.dart` pre-enumerates every rotation as separate const entries (27 shapes, comments literally say "all four rotations"), and no runtime rotation exists anywhere. The lose checker probes each piece in its stored orientation only, with a code comment confirming that assumption as the task requires.

## Changes

### 1. `lib/core/constants/game_constants.dart`
Remove the scoring TODO, add:
- `const int pointsPerCellFilled = 1;`
- `const int bonusPerLineCleared = 10;`
with doc comments referencing BUILD_PROMPTS 1.4.

### 2. `lib/domain/logic/score_calculator.dart` (replace stub)
Top-level pure functions (the task says "pure functions"):
- `int placementScore(Piece piece)` → `piece.filledCellCount * pointsPerCellFilled`
- `int clearBonus(PlacementResult result)` → `(fullRows.length + fullCols.length) * bonusPerLineCleared` (rows and columns count equally as "lines")
- `int moveScore(Piece piece, PlacementResult result)` → sum of the two, the per-move total the future GameController will use
- `bool hasReachedTarget(int score, int targetScore)` → `score >= target` — small addition justified because the stub's own doc comment lists "stage target handling (PRD 5.3)" as part of this file's duty

### 3. `lib/domain/logic/lose_condition_checker.dart` (replace stub)
- `bool isLoseConditionMet(BoardEngine engine, List<Piece> tray)` — returns true iff NO piece in the tray fits at ANY anchor position. Tight loops `row ≤ gridSize - piece.rows`, `col ≤ gridSize - piece.cols` calling `engine.canPlace`; returns false on the first fit. A piece larger than the grid (or an empty tray) naturally yields true. Header comment documents the fixed-orientation assumption per the task.

### 4. `test/domain/score_calculator_test.dart` (new)
Follows suite conventions: doc header + `library;`, `package:block_civilizations/...` imports, `flutter_test`, one top-level `group('ScoreCalculator')` with const piece fixtures (`_single`, `_domino`, `_square`, `_row8`) and `reason:` on expects. Covers: placement score for 1/2/4-cell pieces; clear bonus 0/1/2 lines and row+col; combined move score (e.g. `_row8` completing a row and column → 8 + 2×10 = 28); target comparison below/equal/above; sanity pins that the constants equal the chosen 1/10 values.

### 5. `test/domain/lose_condition_checker_test.dart` (new)
Group `('LoseConditionChecker')` covering:
- Empty board + tray → not lost.
- **Explicit "guaranteed lose" scenario**: fill all 64 cells via `_single` placements, then punch 4 pairwise non-adjacent holes (e.g. (0,0), (0,2), (5,3), (7,7)) by writing `BoardCell.empty()` into the public grid. Tray of `[_square2x2, _domino, _lCorner]` — no multi-cell piece can fit isolated holes → checker returns true. Plus the negative control: make two holes adjacent and the domino fits → false.
- Board full except one hole: tray containing `_single` → false; tray without it → true.
- Edge cases: empty tray → true; tray piece wider than the grid → true even on an empty board.

### 6. Verification
- `dart format` on the five touched files
- `flutter analyze` → 0 issues
- `flutter test` → full suite green

### 7. `PROJECT_STATE.md`
Per its own convention (sections must be updated after each session): mark BUILD_PROMPTS 1.4 done in the relevant sections, record the chosen scoring constants, and update "Immediate Next Steps".