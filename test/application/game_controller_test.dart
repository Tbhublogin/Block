/// Unit tests for the game controller (Phase 2, BUILD_PROMPTS 2.1):
/// stage lifecycle, placement + tray refill, scoring, win/lose transitions,
/// and the rewarded-ad continue flow (PRD 5.3/5.4).
///
/// Uses `flutter_test` like the rest of the suite; determinism comes from
/// overriding [pieceGeneratorProvider] with fixed/queued tray generators,
/// not from widget pumping (no widget tree involved).
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:block_civilizations/application/game_controller.dart';
import 'package:block_civilizations/application/museum_controller.dart';
import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
import 'package:block_civilizations/domain/logic/lose_condition_checker.dart';
import 'package:block_civilizations/domain/logic/piece_generator.dart';
import 'package:block_civilizations/domain/models/piece.dart';
import 'package:block_civilizations/domain/models/stage.dart';

const String _landmark = 'ziggurat_of_ur';

const Piece _single = Piece(
  id: 'single',
  shapeMatrix: [
    [true],
  ],
  landmarkId: _landmark,
);

const Piece _domino = Piece(
  id: 'domino',
  shapeMatrix: [
    [true, true],
  ],
  landmarkId: _landmark,
);

const Piece _square = Piece(
  id: 'square',
  shapeMatrix: [
    [true, true],
    [true, true],
  ],
  landmarkId: _landmark,
);

/// Vertical 1x3: taller than the 2-row free band of the blocked scenario,
/// so it cannot fit anywhere once that scenario's squares are placed.
const Piece _tallTriple = Piece(
  id: 'triple_vert',
  shapeMatrix: [
    [true],
    [true],
    [true],
  ],
  landmarkId: _landmark,
);

const Stage _stage = Stage(id: 'iraq_01', orderIndex: 1, targetScore: 1000);

/// Generator whose every tray is the given fixed [pieces], so controller
/// tests never depend on the shape library or RNG.
class _FixedTrayGenerator extends PieceGenerator {
  _FixedTrayGenerator(this.pieces);

  final List<Piece> pieces;

  @override
  List<Piece> generateTray() => [...pieces];
}

/// Generator serving a queued list of trays in order (the last one repeats),
/// for scenarios whose post-placement refill must differ from the initial
/// tray.
class _QueuedTrayGenerator extends PieceGenerator {
  _QueuedTrayGenerator(this._trays);

  final List<List<Piece>> _trays;
  int _next = 0;

  @override
  List<Piece> generateTray() {
    final tray = [..._trays[_next]];
    if (_next < _trays.length - 1) _next++;
    return tray;
  }
}

ProviderContainer _container({PieceGenerator? generator}) {
  final container = ProviderContainer(
    overrides: [
      if (generator != null)
        pieceGeneratorProvider.overrideWithValue(generator),
      // attemptPlacePiece unlocks landmarks via museumProvider (PRD 6);
      // tests back it with a real temp-dir Hive box like the dedicated
      // museum controller tests do.
      museumBoxProvider.overrideWithValue(_museumBox),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Fills every cell of rows [fromRow]..[toRow] (inclusive) with a 1x1
/// placement — direct engine use, as board setup for blocked scenarios.
void _fillRows(BoardEngine engine, int fromRow, int toRow) {
  for (var row = fromRow; row <= toRow; row++) {
    for (var col = 0; col < gridSize; col++) {
      engine.place(_single, row, col);
    }
  }
}

/// Blocked-board scenario shared by the lose and win-precedence tests:
/// rows 2..5 are pre-filled, and the controller places three 2x2 squares in
/// the remaining free bands — (0,0), (0,2) on top, (6,4) at the bottom.
///
/// No row or column ever completes (rows 0/1 keep cols 4..7 free, rows 6/7
/// keep cols 6..7 free, and every column keeps at least one free cell), so
/// there are no line clears to unblock the board. Afterwards the only free
/// cells are the 2-row bands at the top and bottom, so the refilled
/// [_tallTriple] tray (3 cells tall) fits nowhere.
///
/// A function, not a shared instance: the generator is stateful (queued
/// trays), so every test needs its own.
_QueuedTrayGenerator _blockedScenario() => _QueuedTrayGenerator([
  [_square, _square, _square],
  [_tallTriple, _tallTriple, _tallTriple],
]);

void _placeScenarioSquares(ProviderContainer container) {
  final controller = container.read(gameProvider.notifier);
  expect(controller.attemptPlacePiece(_square, 0, 0), isTrue);
  expect(controller.attemptPlacePiece(_square, 0, 2), isTrue);
  expect(controller.attemptPlacePiece(_square, 6, 4), isTrue);
}

late Directory _museumTempDir;
late Box<List> _museumBox;

void main() {
  setUp(() async {
    _museumTempDir = await Directory.systemTemp.createTemp(
      'game_controller_museum_test',
    );
    Hive.init(_museumTempDir.path);
    _museumBox = await Hive.openBox<List>(museumBoxName);
  });

  tearDown(() async {
    await _museumBox.deleteFromDisk();
    await _museumTempDir.delete(recursive: true);
    Hive.resetAdapters();
  });

  group('GameController — idle state', () {
    test('initial state has no stage, no board, empty tray, score 0', () {
      final container = _container();
      final state = container.read(gameProvider);

      expect(state.stageId, isNull);
      expect(state.targetScore, 0);
      expect(state.board, isNull);
      expect(state.tray, isEmpty);
      expect(state.score, 0);
      expect(state.isLost, isFalse);
      expect(state.isWon, isFalse);
    });

    test(
      'attemptPlacePiece and resetBoardKeepingScore are no-ops while idle',
      () {
        final container = _container();
        final controller = container.read(gameProvider.notifier);

        expect(controller.attemptPlacePiece(_single, 0, 0), isFalse);
        controller.resetBoardKeepingScore();

        final state = container.read(gameProvider);
        expect(state.stageId, isNull);
        expect(state.score, 0);
        expect(state.isLost, isFalse);
        expect(state.isWon, isFalse);
      },
    );
  });

  group('GameController — startStage', () {
    test(
      'starts a fresh session: empty board, full tray, score 0, target set',
      () {
        final container = _container(
          generator: _FixedTrayGenerator([_square, _domino, _single]),
        );
        final controller = container.read(gameProvider.notifier);

        controller.startStage(_stage);
        final state = container.read(gameProvider);

        expect(state.stageId, 'iraq_01');
        expect(state.targetScore, 1000);
        expect(state.board, isNotNull);
        expect(state.score, 0);
        expect(state.isLost, isFalse);
        expect(state.isWon, isFalse);
        expect(state.tray.length, traySize);
        expect(state.tray, [_square, _domino, _single]);
        expect(
          state.board!.grid.every((row) => row.every((cell) => cell.isEmpty)),
          isTrue,
          reason: 'a new stage starts on an empty grid',
        );
      },
    );

    test('starting a new stage resets a previous session entirely', () {
      final container = _container(
        generator: _FixedTrayGenerator([_single, _single, _single]),
      );
      final controller = container.read(gameProvider.notifier);

      controller.startStage(_stage);
      expect(controller.attemptPlacePiece(_single, 0, 0), isTrue);
      controller.startStage(
        const Stage(id: 'iraq_02', orderIndex: 2, targetScore: 5),
      );

      final state = container.read(gameProvider);
      expect(state.stageId, 'iraq_02');
      expect(state.targetScore, 5);
      expect(state.score, 0);
      expect(state.board!.grid[0][0].isEmpty, isTrue);
      expect(state.isLost, isFalse);
      expect(state.isWon, isFalse);
    });
  });

  group('GameController — attemptPlacePiece', () {
    test('valid placement fills the grid, scores, and consumes the piece', () {
      final container = _container(
        generator: _FixedTrayGenerator([_square, _domino, _single]),
      );
      final controller = container.read(gameProvider.notifier);
      controller.startStage(_stage);

      expect(controller.attemptPlacePiece(_square, 3, 4), isTrue);

      final state = container.read(gameProvider);
      expect(state.board!.grid[3][4].landmarkId, _landmark);
      expect(state.board!.grid[4][5].landmarkId, _landmark);
      expect(state.board!.grid[2][4].isEmpty, isTrue);
      expect(state.score, _square.filledCellCount * pointsPerCellFilled);
      expect(state.tray, [_domino, _single]);
    });

    test('placing a piece no longer in the tray is rejected', () {
      final container = _container(
        generator: _FixedTrayGenerator([_square, _domino, _single]),
      );
      final controller = container.read(gameProvider.notifier);
      controller.startStage(_stage);

      expect(controller.attemptPlacePiece(_square, 0, 6), isTrue);
      expect(controller.attemptPlacePiece(_square, 6, 0), isFalse);

      final state = container.read(gameProvider);
      expect(state.tray, [_domino, _single]);
      expect(state.score, _square.filledCellCount * pointsPerCellFilled);
    });

    test(
      'overlapping or off-board anchors are rejected without side effects',
      () {
        final container = _container(
          generator: _FixedTrayGenerator([_square, _domino, _single]),
        );
        final controller = container.read(gameProvider.notifier);
        controller.startStage(_stage);
        expect(controller.attemptPlacePiece(_square, 0, 0), isTrue);

        expect(
          controller.attemptPlacePiece(_domino, 0, 1),
          isFalse,
          reason: 'overlaps the placed square',
        );
        expect(controller.attemptPlacePiece(_domino, -1, 0), isFalse);
        expect(
          controller.attemptPlacePiece(_domino, gridSize - 1, gridSize - 1),
          isFalse,
          reason: 'a 1x2 piece anchored at the last cell runs off the board',
        );

        final state = container.read(gameProvider);
        expect(state.score, _square.filledCellCount * pointsPerCellFilled);
        expect(state.tray, [_domino, _single]);
        expect(state.isLost, isFalse);
        expect(state.isWon, isFalse);
      },
    );

    test('completing a full row awards the line bonus and clears it', () {
      final container = _container(
        generator: _FixedTrayGenerator([_single, _single, _single]),
      );
      final controller = container.read(gameProvider.notifier);
      controller.startStage(_stage);

      // Board setup: fill row 0 except cell (0,0) directly on the engine —
      // the same object the controller holds, so its canPlace probe sees
      // the setup while the controller's tray/score bookkeeping is
      // untouched.
      final engine = container.read(gameProvider).board!;
      for (var col = 1; col < gridSize; col++) {
        engine.place(_single, 0, col);
      }

      expect(controller.attemptPlacePiece(_single, 0, 0), isTrue);

      final state = container.read(gameProvider);
      expect(state.score, pointsPerCellFilled + bonusPerLineCleared);
      expect(
        state.board!.grid[0].every((cell) => cell.isEmpty),
        isTrue,
        reason: 'the completed row was cleared',
      );
      expect(state.isLost, isFalse);
    });

    group('museum unlocks (PRD 6, BUILD_PROMPTS 2.2)', () {
      test('a placed piece unlocks its landmarkId on first placement', () {
        final container = _container(
          generator: _FixedTrayGenerator([_square, _domino, _single]),
        );
        final controller = container.read(gameProvider.notifier);
        controller.startStage(_stage);
        expect(
          container.read(museumProvider).unlockedLandmarkIds,
          isEmpty,
          reason: 'generating or holding pieces must not unlock anything',
        );

        expect(controller.attemptPlacePiece(_square, 3, 4), isTrue);

        expect(container.read(museumProvider).unlockedLandmarkIds, {_landmark});
      });

      test('unlocking is idempotent across repeated placements', () {
        final container = _container(
          generator: _FixedTrayGenerator([_single, _single, _single]),
        );
        final controller = container.read(gameProvider.notifier);
        controller.startStage(_stage);

        expect(controller.attemptPlacePiece(_single, 0, 0), isTrue);
        expect(controller.attemptPlacePiece(_single, 2, 0), isTrue);
        expect(controller.attemptPlacePiece(_single, 4, 0), isTrue);

        expect(container.read(museumProvider).unlockedLandmarkIds, {_landmark});
      });

      test('a rejected placement unlocks nothing', () {
        final container = _container(
          generator: _FixedTrayGenerator([_square, _domino, _single]),
        );
        final controller = container.read(gameProvider.notifier);
        controller.startStage(_stage);

        expect(controller.attemptPlacePiece(_square, -1, 0), isFalse);

        expect(container.read(museumProvider).unlockedLandmarkIds, isEmpty);
      });

      test('different landmarkIds accumulate across placements', () {
        const otherLandmark = 'ishtar_gate';
        const otherPiece = Piece(
          id: 'single_other',
          shapeMatrix: [
            [true],
          ],
          landmarkId: otherLandmark,
        );
        final container = _container(
          generator: _FixedTrayGenerator([_single, otherPiece, _single]),
        );
        final controller = container.read(gameProvider.notifier);
        controller.startStage(_stage);

        expect(controller.attemptPlacePiece(_single, 0, 0), isTrue);
        expect(controller.attemptPlacePiece(otherPiece, 2, 0), isTrue);

        expect(container.read(museumProvider).unlockedLandmarkIds, {
          _landmark,
          otherLandmark,
        });
      });
    });

    test('tray refills with a fresh tray only after all pieces are placed', () {
      final container = _container(
        generator: _FixedTrayGenerator([_square, _square, _square]),
      );
      final controller = container.read(gameProvider.notifier);
      controller.startStage(_stage);

      expect(controller.attemptPlacePiece(_square, 0, 0), isTrue);
      expect(container.read(gameProvider).tray.length, traySize - 1);

      expect(controller.attemptPlacePiece(_square, 4, 4), isTrue);
      expect(container.read(gameProvider).tray.length, traySize - 2);

      expect(controller.attemptPlacePiece(_square, 6, 6), isTrue);
      final refilled = container.read(gameProvider).tray;
      expect(refilled.length, traySize);
      expect(refilled, everyElement(_square));
      expect(container.read(gameProvider).isLost, isFalse);
    });

    test('reaching the target score wins the stage immediately (PRD 5.3)', () {
      final container = _container(
        generator: _FixedTrayGenerator([_single, _domino, _single]),
      );
      final controller = container.read(gameProvider.notifier);
      controller.startStage(
        const Stage(id: 'iraq_01', orderIndex: 1, targetScore: 2),
      );

      expect(controller.attemptPlacePiece(_single, 0, 0), isTrue);
      expect(
        container.read(gameProvider).isWon,
        isFalse,
        reason: '1 point is below the target of 2',
      );

      expect(controller.attemptPlacePiece(_domino, 1, 0), isTrue);
      final state = container.read(gameProvider);
      expect(
        state.isWon,
        isTrue,
        reason: '1 (single) + 2 (domino) = 3 reaches the target of 2',
      );
      expect(state.isLost, isFalse);
      expect(state.score, 3);

      expect(
        controller.attemptPlacePiece(_single, 7, 7),
        isFalse,
        reason: 'a won stage is frozen — no further placements',
      );
    });

    test('blocked board with an unplaceable refill tray loses (PRD 5.4)', () {
      final container = _container(generator: _blockedScenario());
      final controller = container.read(gameProvider.notifier);
      controller.startStage(_stage);
      final engine = container.read(gameProvider).board!;
      _fillRows(engine, 2, 5);

      expect(controller.attemptPlacePiece(_square, 0, 0), isTrue);
      expect(container.read(gameProvider).isLost, isFalse);

      expect(controller.attemptPlacePiece(_square, 0, 2), isTrue);
      expect(container.read(gameProvider).isLost, isFalse);

      expect(controller.attemptPlacePiece(_square, 6, 4), isTrue);

      final state = container.read(gameProvider);
      expect(state.score, 3 * _square.filledCellCount * pointsPerCellFilled);
      expect(
        state.tray,
        everyElement(_tallTriple),
        reason: 'the emptied tray was refilled from the queued generator',
      );
      expect(
        state.isLost,
        isTrue,
        reason:
            'only 2-row free bands remain and the tray pieces are '
            '3 cells tall',
      );
      expect(state.isWon, isFalse);
    });

    test('win takes precedence over lose on the same placement', () {
      final container = _container(generator: _blockedScenario());
      final controller = container.read(gameProvider.notifier);
      // Target 12 = exactly the three 2x2 squares' cell points, so the
      // third placement wins and simultaneously leaves a board where the
      // refilled tray fits nowhere.
      controller.startStage(
        const Stage(id: 'iraq_01', orderIndex: 1, targetScore: 12),
      );
      _fillRows(container.read(gameProvider).board!, 2, 5);

      _placeScenarioSquares(container);

      final state = container.read(gameProvider);
      expect(state.isWon, isTrue);
      expect(
        state.isLost,
        isFalse,
        reason: 'win takes precedence when both conditions are met',
      );
      expect(state.score, 12);
      expect(
        isLoseConditionMet(state.board!, state.tray),
        isTrue,
        reason:
            'the position itself is a losing one — precedence, not '
            'absence of the lose condition',
      );
    });
  });

  group('GameController — resetBoardKeepingScore', () {
    test('after a loss: board cleared, score and tray kept, play resumes', () {
      final container = _container(generator: _blockedScenario());
      final controller = container.read(gameProvider.notifier);
      controller.startStage(_stage);
      _fillRows(container.read(gameProvider).board!, 2, 5);
      _placeScenarioSquares(container);
      expect(container.read(gameProvider).isLost, isTrue);

      controller.resetBoardKeepingScore();

      final state = container.read(gameProvider);
      expect(state.isLost, isFalse);
      expect(state.isWon, isFalse);
      expect(
        state.score,
        12,
        reason: 'the stage score is preserved (PRD 5.4, AI_RULES #19)',
      );
      expect(
        state.tray,
        everyElement(_tallTriple),
        reason: 'the current tray is kept, not refilled',
      );
      expect(
        state.board!.grid.every((row) => row.every((cell) => cell.isEmpty)),
        isTrue,
        reason: 'the whole board was emptied',
      );

      // The stage is playable again — the same target still applies.
      expect(controller.attemptPlacePiece(_tallTriple, 0, 0), isTrue);
      final resumed = container.read(gameProvider);
      expect(resumed.score, 12 + _tallTriple.filledCellCount);
      expect(resumed.isLost, isFalse);
    });

    test('after a win: no-op — the stage stays frozen', () {
      final container = _container(
        generator: _FixedTrayGenerator([_single, _domino, _single]),
      );
      final controller = container.read(gameProvider.notifier);
      controller.startStage(
        const Stage(id: 'iraq_01', orderIndex: 1, targetScore: 2),
      );
      expect(controller.attemptPlacePiece(_single, 0, 0), isTrue);
      expect(controller.attemptPlacePiece(_domino, 1, 0), isTrue);
      expect(container.read(gameProvider).isWon, isTrue);

      controller.resetBoardKeepingScore();

      final state = container.read(gameProvider);
      expect(state.isWon, isTrue);
      expect(state.score, 3);
      expect(
        state.board!.grid[0][0].isFilled,
        isTrue,
        reason: 'the board was not reset after a win',
      );
    });
  });
}
