# Plan: `application/game_controller.dart` (Phase 2, BUILD_PROMPTS 2.1)

## Context findings

- The `Stage` model (`lib/domain/models/stage.dart`) is a **stub** — `startStage(Stage)` can't compile without implementing it. In scope for this task.
- Codebase conventions: no `copyWith`/equatable anywhere yet — hand-written `operator ==`/`hashCode` on immutable models; Riverpod style is **`Notifier`/`NotifierProvider`** (chosen by user); tests use `flutter_test` with `ProviderContainer` overrides; doc comments cite PRD/AI_RULES sections; no magic numbers (read from `game_constants.dart`).
- Domain contract: `BoardEngine()` → empty 8×8; `canPlace` → `place` (asserts canPlace; special piece clears its own row+col inside `place`) → `clearLines(result.fullRows, result.fullCols)`; `moveScore(piece, result)`; `hasReachedTarget(score, target)` (win, PRD 5.3); `isLoseConditionMet(engine, tray)` (PRD 5.4); `PieceGenerator.generateTray()` → 3 pieces; refill only when tray is empty (PRD 5.2); `engine.reset()` exists specifically for the ad-continue flow (AI_RULES #19: board clears, **score is preserved**).
- Decisions (user-confirmed): `Notifier` API; win triggers **immediately** when `hasReachedTarget` becomes true; after that `attemptPlacePiece` is a no-op returning false.

## 1. Implement `lib/domain/models/stage.dart` (replaces stub)

```dart
class Stage {
  final String id;
  final int orderIndex;   // 1..30 within its civilization
  final int targetScore;
  const Stage({required this.id, required this.orderIndex, required this.targetScore});
  // hand-written == / hashCode / toString (codebase convention)
}
```
Pure Dart, doc comment per PRD 11.

## 2. Create `lib/application/game_controller.dart`

Imports: `flutter_riverpod` + domain files only (no Flutter widgets/material).

**`GameState`** — immutable state class (hand-written `==`/`hashCode`/`copyWith`):
- `String? stageId` — null before `startStage` (idle); needed later to build `GameResult` for the win/lose dialogs
- `int targetScore`
- `BoardEngine board` — held by reference (the engine is deliberately mutable; every controller mutation emits a new `GameState` so Riverpod listeners fire while the grid mutates in place)
- `List<Piece> tray`
- `int score`
- `bool isLost`, `bool isWon`
- `const GameState._(...)`, public factory `GameState.initial()` (fresh `BoardEngine()`, empty tray, score 0, both flags false)

**Provider + controller**:
```dart
final pieceGeneratorProvider = Provider<PieceGenerator>((ref) => PieceGenerator());
final gameProvider = NotifierProvider<GameController, GameState>(GameController.new);

class GameController extends Notifier<GameState> {
  @override
  GameState build() => GameState.initial();
  BoardEngine get _engine => state.board;
```
- `pieceGeneratorProvider` is overridable so tests can inject a seeded/fixed generator (same DI pattern as `sharedPreferencesProvider`).

**`void startStage(Stage stage)`**
- New `BoardEngine()`; set state to fresh session: `stageId: stage.id`, `targetScore: stage.targetScore`, score 0, flags false, tray = `ref.read(pieceGeneratorProvider).generateTray()`.

**`bool attemptPlacePiece(Piece piece, int row, int col)`** — returns whether the placement happened (lets the UI treat invalid drops as no-ops):
1. No-op `return false` when: no active stage (`stageId == null`), `isLost`, `isWon`, piece not in current tray, or `!_engine.canPlace(piece, row, col)`.
2. `final result = _engine.place(piece, row, col);` then `_engine.clearLines(result.fullRows, result.fullCols);` (uniform place → clear flow per documented PROJECT_STATE decision; special piece double-clear is a harmless no-op).
3. Remove the piece from the tray (new immutable list); if the tray becomes empty, refill via `generateTray()` (PRD 5.2).
4. `score += moveScore(piece, result)`.
5. Win check first: `hasReachedTarget(score, targetScore)` → `isWon = true` (immediate, per user decision; takes precedence over lose).
6. Else `isLoseConditionMet(_engine, tray)` → `isLost = true`.
7. Emit new state via `copyWith`, `return true`.

**`void resetBoardKeepingScore()`** (PRD 5.4 ad-continue, AI_RULES #19)
- No-op when no active stage or `isWon`.
- `_engine.reset()`; `isLost = false`; tray **unchanged** (the same 3 pieces resume on the cleared board); score and `targetScore` untouched. Emit new state.

## 3. Create `test/application/game_controller_test.dart`

Mirrors `test/domain/*_test.dart` conventions (flutter_test, `ProviderContainer` + `addTearDown`). Uses a `_FixedTrayGenerator extends PieceGenerator` (overrides `generateTray` to return a fixed tray) via `pieceGeneratorProvider.overrideWithValue` for determinism. Cases:
1. Initial state is idle (no stage, empty tray, score 0, flags false).
2. `startStage`: fresh empty board, tray of `traySize`, score 0, target from stage.
3. Valid placement: returns true, correct cell filled with the piece's landmarkId, score = filledCellCount × pointsPerCellFilled, piece removed from tray.
4. Invalid placement (off-board/occupied/no active stage): returns false, state unchanged.
5. Tray refills to 3 after all 3 placed (PRD 5.2).
6. Win: stage whose target equals one placement's score → `isWon` true immediately after that placement; further `attemptPlacePiece` returns false (no-op).
7. Lose: fixed tray of three 2×2 squares; greedily place until the board is full → `isLost` true.
8. `resetBoardKeepingScore` after lose: board empty, score preserved, `isLost` false, tray unchanged; next placement succeeds (ad-continue flow).
9. `resetBoardKeepingScore` with no active stage: harmless no-op.

## 4. Update `PROJECT_STATE.md`

Mark game controller (BUILD_PROMPTS 2.1) + `Stage` model done; note the two confirmed decisions (Notifier API, immediate win); set next steps to the minimal `game_screen.dart` / theme work.

## Verification

- `flutter analyze` → 0 issues (current baseline).
- `flutter test` → all existing tests stay green + new controller tests pass.