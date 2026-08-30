/// Unit tests for the lose condition checker (BUILD_PROMPTS 1.4, PRD 5.4):
/// the stage is lost only when NONE of the 3 tray pieces can be legally
/// placed anywhere on the grid, including an explicit "guaranteed lose"
/// board scenario.
///
/// Uses `flutter_test` like the rest of the suite even though the checker
/// is pure Dart — no widget tree involved (AI_RULES #2/#10).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
import 'package:block_civilizations/domain/logic/lose_condition_checker.dart';
import 'package:block_civilizations/domain/models/board_cell.dart';
import 'package:block_civilizations/domain/models/piece.dart';

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

const Piece _lCorner = Piece(
  id: 'l_small_top_left',
  shapeMatrix: [
    [true, false],
    [true, true],
  ],
  landmarkId: _landmark,
);

const Piece _row8 = Piece(
  id: 'row8',
  shapeMatrix: [
    [true, true, true, true, true, true, true, true],
  ],
  landmarkId: _landmark,
);

/// Fills every cell of [engine]'s grid with a 1x1 placement.
void _fillBoard(BoardEngine engine) {
  for (var row = 0; row < gridSize; row++) {
    for (var col = 0; col < gridSize; col++) {
      engine.place(_single, row, col);
    }
  }
}

void main() {
  group('LoseConditionChecker', () {
    test('an empty board with any tray is not a loss', () {
      final engine = BoardEngine();

      expect(isLoseConditionMet(engine, [_square, _domino, _lCorner]), isFalse);
    });

    test('a loss needs every tray piece blocked, not just some', () {
      final engine = BoardEngine();
      engine.place(_square, 4, 4);

      expect(
        isLoseConditionMet(engine, [_domino, _lCorner, _single]),
        isFalse,
        reason: 'the single still fits somewhere on a mostly empty board',
      );
    });

    test('a board with one free cell is lost only without the 1x1 piece', () {
      final engine = BoardEngine();
      _fillBoard(engine);
      engine.grid[3][5] = const BoardCell.empty();

      expect(isLoseConditionMet(engine, [_square, _domino, _lCorner]), isTrue);
      expect(
        isLoseConditionMet(engine, [_square, _domino, _single]),
        isFalse,
        reason: 'the 1x1 piece fits the single free cell',
      );
    });

    test(
      'guaranteed lose: isolated single-cell holes block every tray piece',
      () {
        final engine = BoardEngine();
        _fillBoard(engine);

        // Punch out four pairwise non-adjacent cells (no two share an edge),
        // so every hole is an isolated 1x1 pocket. The 2x2 square, the
        // domino, and the L-corner all need at least two neighbouring cells,
        // so none can be placed anywhere — a guaranteed loss per PRD 5.4.
        const holes = [(0, 0), (0, 2), (5, 3), (7, 7)];
        for (final (row, col) in holes) {
          engine.grid[row][col] = const BoardCell.empty();
        }

        expect(
          isLoseConditionMet(engine, [_square, _domino, _lCorner]),
          isTrue,
          reason: 'no multi-cell piece fits an isolated 1x1 hole',
        );
      },
    );

    test('negative control: making two holes adjacent lets the domino fit', () {
      final engine = BoardEngine();
      _fillBoard(engine);
      const holes = [(0, 0), (0, 2), (5, 3), (7, 7)];
      for (final (row, col) in holes) {
        engine.grid[row][col] = const BoardCell.empty();
      }

      engine.grid[0][1] = const BoardCell.empty();

      expect(
        isLoseConditionMet(engine, [_square, _domino, _lCorner]),
        isFalse,
        reason: 'the domino now fits horizontally across (0,0)-(0,1)',
      );
    });

    test('an empty tray is always a loss', () {
      final engine = BoardEngine();

      expect(isLoseConditionMet(engine, const []), isTrue);
    });

    test(
      'a tray piece larger than the grid is unplaceable even when empty',
      () {
        final engine = BoardEngine();
        final tooWide = Piece(
          id: 'row16',
          shapeMatrix: [
            [for (var i = 0; i < 2 * gridSize; i++) true],
          ],
          landmarkId: _landmark,
        );

        expect(isLoseConditionMet(engine, [tooWide]), isTrue);
        expect(
          isLoseConditionMet(engine, [tooWide, _row8]),
          isFalse,
          reason: 'the 8-wide piece still fits the empty board',
        );
      },
    );
  });
}
