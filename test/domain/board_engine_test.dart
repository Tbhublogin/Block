/// Unit tests for the board engine (BUILD_PROMPTS 1.2): placement
/// validation, full-line detection/clearing, and the special piece's
/// unconditional row+column clear (PRD 5.2, AI_RULES #17).
///
/// Uses `flutter_test` like the rest of the suite even though the engine is
/// pure Dart — no widget tree involved (AI_RULES #2/#10).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
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

const Piece _rowPiece = Piece(
  id: 'row8',
  shapeMatrix: [
    [true, true, true, true, true, true, true, true],
  ],
  landmarkId: _landmark,
);

const Piece _colPiece = Piece(
  id: 'col8',
  shapeMatrix: [
    [true],
    [true],
    [true],
    [true],
    [true],
    [true],
    [true],
    [true],
  ],
  landmarkId: _landmark,
);

const Piece _special = Piece.special(id: 'special', landmarkId: _landmark);

bool _rowIsEmpty(BoardEngine engine, int row) =>
    engine.grid[row].every((cell) => cell.isEmpty);

bool _colIsEmpty(BoardEngine engine, int col) =>
    [for (var row = 0; row < gridSize; row++) engine.grid[row][col]]
        .every((cell) => cell.isEmpty);

void main() {
  group('BoardEngine', () {
    test('starts with an empty grid using the shared grid-size constant', () {
      expect(gridSize, 8);

      final engine = BoardEngine();

      expect(engine.grid.length, gridSize);
      for (final row in engine.grid) {
        expect(row.length, gridSize);
        for (final cell in row) {
          expect(cell.isEmpty, isTrue);
        }
      }
    });

    test('places a normal piece and reports no cleared lines', () {
      final engine = BoardEngine();

      expect(engine.canPlace(_square, 2, 3), isTrue);

      final result = engine.place(_square, 2, 3);

      expect(result.fullRows, isEmpty);
      expect(result.fullCols, isEmpty);
      for (final (row, col) in [(2, 3), (2, 4), (3, 3), (3, 4)]) {
        expect(engine.grid[row][col].landmarkId, _landmark);
      }
      expect(engine.grid[2][2].isEmpty, isTrue);
      expect(engine.grid[4][3].isEmpty, isTrue);
    });

    test('rejects placements that hang off the board edges', () {
      final engine = BoardEngine();

      expect(engine.canPlace(_rowPiece, 0, 1), isFalse);
      expect(engine.canPlace(_colPiece, 1, 0), isFalse);
      expect(engine.canPlace(_single, gridSize, 0), isFalse);
      expect(engine.canPlace(_single, -1, 0), isFalse);
      expect(engine.canPlace(_domino, gridSize - 1, gridSize - 1), isFalse);

      expect(
        () => engine.place(_rowPiece, 0, 1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => engine.place(_single, -1, 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects placements overlapping filled cells', () {
      final engine = BoardEngine();
      engine.place(_domino, 3, 3);

      expect(engine.canPlace(_single, 3, 3), isFalse);
      expect(engine.canPlace(_single, 3, 4), isFalse);
      expect(engine.canPlace(_domino, 3, 2), isFalse);
      expect(engine.canPlace(_domino, 3, 4), isFalse);
      expect(engine.canPlace(_single, 2, 3), isTrue);
      expect(engine.canPlace(_domino, 3, 5), isTrue);

      expect(() => engine.place(_single, 3, 3), throwsA(isA<AssertionError>()));
    });

    test('reports a completed row and clears it', () {
      final engine = BoardEngine();
      engine.place(_single, 1, 0);

      final result = engine.place(_rowPiece, 2, 0);

      expect(result, PlacementResult(fullRows: [2], fullCols: []));
      for (var col = 0; col < gridSize; col++) {
        expect(engine.grid[2][col].isFilled, isTrue);
      }

      engine.clearLines([2], const []);

      expect(_rowIsEmpty(engine, 2), isTrue);
      expect(
        engine.grid[1][0].isFilled,
        isTrue,
        reason: 'neighbouring rows stay untouched',
      );
    });

    test('reports a completed column and clears it', () {
      final engine = BoardEngine();
      engine.place(_single, 0, 0);

      final result = engine.place(_colPiece, 0, 3);

      expect(result, PlacementResult(fullRows: [], fullCols: [3]));
      expect(engine.grid[0][3].isFilled, isTrue);

      engine.clearLines(const [], [3]);

      expect(_colIsEmpty(engine, 3), isTrue);
      expect(
        engine.grid[0][0].isFilled,
        isTrue,
        reason: 'neighbouring columns stay untouched',
      );
    });

    test('reports a row and column completed by the same placement', () {
      final engine = BoardEngine();
      // Fill row 4 and column 2 everywhere except their shared cell (4, 2).
      const gapRow = 4;
      const gapCol = 2;
      for (var col = 0; col < gridSize; col++) {
        if (col != gapCol) engine.place(_single, gapRow, col);
      }
      for (var row = 0; row < gridSize; row++) {
        if (row != gapRow) engine.place(_single, row, gapCol);
      }

      final result = engine.place(_single, gapRow, gapCol);

      expect(result, PlacementResult(fullRows: [gapRow], fullCols: [gapCol]));

      engine.clearLines([gapRow], [gapCol]);

      expect(_rowIsEmpty(engine, gapRow), isTrue);
      expect(_colIsEmpty(engine, gapCol), isTrue);
    });

    test(
      'special piece clears its row and column even when neither is full',
      () {
        final engine = BoardEngine();
        // Scattered, clearly-not-full occupants of row 4 and column 6, plus an
        // unrelated filled cell as a control.
        engine.place(_single, 4, 0);
        engine.place(_single, 4, 7);
        engine.place(_single, 0, 6);
        engine.place(_single, 7, 6);
        engine.place(_single, 0, 0);

        final result = engine.place(_special, 4, 6);

        expect(result, PlacementResult(fullRows: [4], fullCols: [6]));
        expect(_rowIsEmpty(engine, 4), isTrue);
        expect(_colIsEmpty(engine, 6), isTrue);
        expect(
          engine.grid[0][0].isFilled,
          isTrue,
          reason: 'unrelated cells stay untouched',
        );

        // A follow-up clear of the reported lines is a harmless no-op.
        engine.clearLines([4], [6]);
        expect(_rowIsEmpty(engine, 4), isTrue);
        expect(_colIsEmpty(engine, 6), isTrue);
      },
    );

    test(
      'special piece reports only its own lines even with other full lines',
      () {
        final engine = BoardEngine();
        // Row 0 is fully occupied before the special placement; row 4 and
        // column 6 are occupied everywhere except the special's target cell.
        for (var col = 0; col < gridSize; col++) {
          engine.place(_single, 0, col);
        }
        for (var col = 0; col < gridSize; col++) {
          if (col != 6) engine.place(_single, 4, col);
        }
        for (var row = 1; row < gridSize; row++) {
          if (row != 4) engine.place(_single, row, 6);
        }

        final result = engine.place(_special, 4, 6);

        expect(result.fullRows, [
          4,
        ], reason: 'the pre-existing full row 0 is not reported');
        expect(result.fullCols, [6]);
        expect(_rowIsEmpty(engine, 4), isTrue);
        expect(_colIsEmpty(engine, 6), isTrue);
        // Row 0 keeps its cells except where the column-6 clear reaches it.
        expect(engine.grid[0][0].isFilled, isTrue);
        expect(engine.grid[0][6].isEmpty, isTrue);
      },
    );

    test(
      'clearLines and reset empty the requested lines and the whole grid',
      () {
        final engine = BoardEngine();
        engine.place(_square, 0, 0);
        engine.place(_square, 4, 4);

        engine.clearLines([0], [4]);

        expect(_rowIsEmpty(engine, 0), isTrue);
        expect(_colIsEmpty(engine, 4), isTrue);
        expect(engine.grid[5][5].isFilled, isTrue);

        engine.reset();

        for (final row in engine.grid) {
          for (final cell in row) {
            expect(cell.isEmpty, isTrue);
          }
        }
      },
    );
  });
}
