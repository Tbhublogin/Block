/// Game controller (Phase 2, BUILD_PROMPTS 2.1): a Riverpod `Notifier`
/// orchestrating `BoardEngine` + `PieceGenerator` + the scoring functions +
/// `isLoseConditionMet` into one game-session state (PRD 5.1–5.4).
///
/// Depends only on domain/ logic and core/constants — no UI widgets, no
/// Flutter material imports (AI_RULES #2/#4). The board is the deliberately
/// mutable `BoardEngine`; every controller mutation emits a fresh
/// [GameState] instance so Riverpod listeners fire, while the grid itself
/// mutates in place.
///
/// Win (PRD 5.3): the instant `hasReachedTarget` becomes true, `isWon` is
/// set and the stage is frozen — further placement attempts are no-ops.
/// Lose (PRD 5.4): none of the current tray pieces fits anywhere.
/// Continue (PRD 5.4, AI_RULES #19): `resetBoardKeepingScore` empties the
/// board for the rewarded-ad flow while preserving the stage score and the
/// current tray.
///
/// Museum side effect (PRD 6, BUILD_PROMPTS 2.2): every successful
/// placement unlocks the piece's landmark for the museum via
/// [museumProvider] — the first time a landmarkId is placed, it is
/// discovered.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:block_civilizations/application/museum_controller.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
import 'package:block_civilizations/domain/logic/lose_condition_checker.dart';
import 'package:block_civilizations/domain/logic/piece_generator.dart';
import 'package:block_civilizations/domain/logic/score_calculator.dart';
import 'package:block_civilizations/domain/models/piece.dart';
import 'package:block_civilizations/domain/models/stage.dart';

/// Provides the tray generator; overridable so tests can inject a seeded or
/// fixed generator (same DI pattern as `sharedPreferencesProvider`).
final pieceGeneratorProvider = Provider<PieceGenerator>(
  (ref) => PieceGenerator(),
);

/// The single active game session: current board, tray, score, stage target,
/// and win/lose flags. Idle (no stage) before the first `startStage`.
final gameProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Immutable snapshot of one game session.
class GameState {
  /// Active stage id, or null while idle (no `startStage` yet). Non-null
  /// implies `board` is non-null as well.
  final String? stageId;

  /// The active stage's target score (PRD 5.3); meaningless while idle.
  final int targetScore;

  /// The live board, or null while idle (no `startStage` yet). The engine
  /// is deliberately mutable — treat this as a reference that changes in
  /// place whenever the controller emits a new [GameState].
  final BoardEngine? board;

  /// Current tray pieces (up to [traySize]); refilled when it empties.
  final List<Piece> tray;

  /// Score accumulated during the current stage attempt.
  final int score;

  /// Whether the stage was lost (no tray piece fits anywhere, PRD 5.4).
  final bool isLost;

  /// Whether the stage was won (target score reached, PRD 5.3).
  final bool isWon;

  const GameState._({
    required this.stageId,
    required this.targetScore,
    required this.board,
    required this.tray,
    required this.score,
    required this.isLost,
    required this.isWon,
  });

  /// Idle state before any stage has started: no board yet.
  const GameState.initial()
    : stageId = null,
      targetScore = 0,
      board = null,
      tray = const [],
      score = 0,
      isLost = false,
      isWon = false;

  GameState copyWith({
    String? stageId,
    int? targetScore,
    BoardEngine? board,
    List<Piece>? tray,
    int? score,
    bool? isLost,
    bool? isWon,
  }) => GameState._(
    stageId: stageId ?? this.stageId,
    targetScore: targetScore ?? this.targetScore,
    board: board ?? this.board,
    tray: tray ?? this.tray,
    score: score ?? this.score,
    isLost: isLost ?? this.isLost,
    isWon: isWon ?? this.isWon,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          other.stageId == stageId &&
          other.targetScore == targetScore &&
          identical(other.board, board) &&
          other.tray.length == tray.length &&
          other.tray.every(tray.contains) &&
          other.score == score &&
          other.isLost == isLost &&
          other.isWon == isWon;

  @override
  int get hashCode => Object.hash(
    stageId,
    targetScore,
    identityHashCode(board),
    Object.hashAllUnordered(tray),
    score,
    isLost,
    isWon,
  );

  @override
  String toString() =>
      'GameState($stageId, score: $score/$targetScore, '
      'tray: ${tray.length}, isLost: $isLost, isWon: $isWon)';
}

/// Orchestrates one game session on top of the pure domain logic.
class GameController extends Notifier<GameState> {
  @override
  GameState build() => const GameState.initial();

  /// Starts a fresh session for [stage]: empty board, score 0, first tray
  /// generated (PRD 5.2), win/lose flags cleared.
  void startStage(Stage stage) {
    state = GameState._(
      stageId: stage.id,
      targetScore: stage.targetScore,
      board: BoardEngine(),
      tray: ref.read(pieceGeneratorProvider).generateTray(),
      score: 0,
      isLost: false,
      isWon: false,
    );
  }

  /// Attempts to place [piece] at anchor (`row`, `col`).
  ///
  /// Returns whether the placement happened. The attempt is a no-op
  /// (`false`) when no stage is active, the stage already ended (`isWon`
  /// per PRD 5.3, or `isLost`), the piece is not in the current tray, or
  /// `canPlace` rejects the anchor — the UI can then treat invalid drops
  /// as nothing having happened.
  bool attemptPlacePiece(Piece piece, int row, int col) {
    final current = state;
    final engine = current.board;
    if (engine == null ||
        current.isLost ||
        current.isWon ||
        !current.tray.contains(piece) ||
        !engine.canPlace(piece, row, col)) {
      return false;
    }

    final result = engine.place(piece, row, col);
    engine.clearLines(result.fullRows, result.fullCols);

    final remaining = [...current.tray]..remove(piece);
    // Tray refills only when all of its pieces are placed (PRD 5.2).
    final tray = remaining.isEmpty
        ? ref.read(pieceGeneratorProvider).generateTray()
        : remaining;

    final score = current.score + moveScore(piece, result);

    // Win takes precedence over lose: a placement that both reaches the
    // target and blocks the tray is still a win (PRD 5.3, immediate).
    final isWon = hasReachedTarget(score, current.targetScore);
    final isLost = !isWon && isLoseConditionMet(engine, tray);

    state = current.copyWith(
      tray: tray,
      score: score,
      isLost: isLost,
      isWon: isWon,
    );

    // Museum discovery (PRD 6): a newly placed landmarkId joins the
    // collection. Fire-and-forget — the Hive write must not block gameplay,
    // and unlockLandmark is idempotent. Only placed pieces count (PRD 2.2:
    // "whenever a piece ... is placed"), not tray generation.
    ref.read(museumProvider.notifier).unlockLandmark(piece.landmarkId);
    return true;
  }

  /// Rewarded-ad continue flow (PRD 5.4, AI_RULES #19): empties the board
  /// while preserving the stage score and the current tray, clearing the
  /// lose flag so play resumes toward the same target. A no-op while idle
  /// or already won.
  void resetBoardKeepingScore() {
    final current = state;
    final engine = current.board;
    if (engine == null || current.isWon) return;

    engine.reset();
    state = current.copyWith(isLost: false);
  }
}
