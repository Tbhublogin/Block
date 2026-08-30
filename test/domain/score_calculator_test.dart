/// Unit tests for the scoring rules (BUILD_PROMPTS 1.4): placement points,
/// line-clear bonuses, per-move totals, and stage target handling (PRD
/// 5.3).
///
/// Uses `flutter_test` like the rest of the suite even though the
/// calculator is pure Dart — no widget tree involved (AI_RULES #2/#10).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
import 'package:block_civilizations/domain/logic/score_calculator.dart';
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

const Piece _row8 = Piece(
  id: 'row8',
  shapeMatrix: [
    [true, true, true, true, true, true, true, true],
  ],
  landmarkId: _landmark,
);

void main() {
  group('ScoreCalculator', () {
    test(
      'scoring constants keep the chosen values (1 per cell, 10 per line)',
      () {
        expect(pointsPerCellFilled, 1, reason: 'placement points are per cell');
        expect(
          bonusPerLineCleared,
          10,
          reason: 'line bonus is a tunable constant',
        );
      },
    );

    test('placement score is one point per filled cell', () {
      expect(placementScore(_single), 1, reason: '1x1 piece');
      expect(placementScore(_domino), 2, reason: '1x2 piece');
      expect(placementScore(_square), 4, reason: '2x2 piece');
      expect(placementScore(_row8), 8, reason: '8x1 piece');
    });

    test('clear bonus is zero when a placement clears no lines', () {
      const result = PlacementResult(fullRows: [], fullCols: []);

      expect(clearBonus(result), 0);
    });

    test('clear bonus awards one constant per cleared line', () {
      expect(
        clearBonus(const PlacementResult(fullRows: [3], fullCols: [])),
        bonusPerLineCleared,
        reason: 'a single cleared row',
      );
      expect(
        clearBonus(const PlacementResult(fullRows: [], fullCols: [5])),
        bonusPerLineCleared,
        reason: 'a cleared column scores like a cleared row',
      );
      expect(
        clearBonus(const PlacementResult(fullRows: [2], fullCols: [4])),
        2 * bonusPerLineCleared,
        reason: 'a row and a column cleared by the same placement',
      );
      expect(
        clearBonus(const PlacementResult(fullRows: [1, 3, 6], fullCols: [])),
        3 * bonusPerLineCleared,
        reason: 'several rows cleared at once',
      );
    });

    test('move score combines placement and clear points', () {
      final engine = BoardEngine();
      // Fill column 4 everywhere except row 2, then drop the 8-wide row
      // piece across row 2: it scores 8 cell points plus two cleared lines
      // (the row itself and column 4).
      for (var row = 0; row < gridSize; row++) {
        if (row != 2) engine.place(_single, row, 4);
      }

      final piece = _row8;
      final result = engine.place(piece, 2, 0);

      expect(result, PlacementResult(fullRows: [2], fullCols: [4]));
      expect(moveScore(piece, result), 8 + 2 * bonusPerLineCleared);
      expect(
        moveScore(piece, result),
        placementScore(piece) + clearBonus(result),
        reason: 'the per-move total is the sum of its two parts',
      );
    });

    test('move score with no clears is just the placement points', () {
      final result = PlacementResult(fullRows: const [], fullCols: const []);

      expect(moveScore(_square, result), 4);
    });

    test('target reached exactly at the target score and above, not below', () {
      const target = 100;

      expect(hasReachedTarget(target - 1, target), isFalse);
      expect(
        hasReachedTarget(target, target),
        isTrue,
        reason: 'PRD 5.3: reaching the target triggers the stage win',
      );
      expect(hasReachedTarget(target + 1, target), isTrue);
    });
  });
}
