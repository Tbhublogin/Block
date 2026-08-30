/// Unit tests for the piece generator (BUILD_PROMPTS 1.3): tray size, shape
/// validity of the library and generated trays, placeholder landmark ids,
/// and the special-piece spawn rate matching SPECIAL_PIECE_SPAWN_RATE over
/// many seeded trials (PRD 5.2).
///
/// All randomness is seeded so the suite is deterministic — the statistical
/// assertion below is non-flaky by construction (~4.8 sigma margin).
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/core/constants/piece_shapes.dart';
import 'package:block_civilizations/domain/logic/piece_generator.dart';
import 'package:block_civilizations/domain/models/piece.dart';

/// True when [piece]'s matrix matches some shape-library definition, or it
/// is the special piece.
bool _isKnownShape(Piece piece) =>
    piece.isSpecial ||
    pieceShapeLibrary.any((definition) => definition == piece);

void main() {
  group('PieceGenerator', () {
    test('generates a tray of exactly traySize pieces on every refresh', () {
      final generator = PieceGenerator(random: Random(1));
      for (var i = 0; i < 100; i++) {
        final tray = generator.generateTray();
        expect(tray.length, traySize, reason: 'tray $i had the wrong size');
      }
    });

    test('shape library entries are all non-empty, rectangular, and fit the '
        'grid', () {
      expect(pieceShapeLibrary, isNotEmpty);
      for (final piece in pieceShapeLibrary) {
        expect(piece.rows, greaterThan(0), reason: '${piece.id} has no rows');
        expect(piece.cols, greaterThan(0), reason: '${piece.id} has no cols');
        expect(
          piece.filledCellCount,
          greaterThan(0),
          reason: '${piece.id} has no filled cells',
        );
        for (var r = 0; r < piece.rows; r++) {
          expect(
            piece.shapeMatrix[r].length,
            piece.cols,
            reason: '${piece.id} row $r is not rectangular',
          );
        }
        expect(
          piece.rows,
          lessThanOrEqualTo(gridSize),
          reason: '${piece.id} is taller than the grid',
        );
        expect(
          piece.cols,
          lessThanOrEqualTo(gridSize),
          reason: '${piece.id} is wider than the grid',
        );
        expect(
          piece.isSpecial,
          isFalse,
          reason: 'the library holds only normal shapes (AI_RULES #16)',
        );
      }
    });

    test('every piece in generated trays is a library shape or the special '
        'piece', () {
      final generator = PieceGenerator(random: Random(2));
      final knownIds = {
        for (final definition in pieceShapeLibrary) definition.id,
        specialPiece.id,
      };
      for (var i = 0; i < 200; i++) {
        for (final piece in generator.generateTray()) {
          expect(
            knownIds,
            contains(piece.id),
            reason: 'unknown id ${piece.id}',
          );
          expect(_isKnownShape(piece), isTrue, reason: '$piece is alien');
        }
      }
    });

    test('generated pieces carry the placeholder landmark id for now', () {
      final generator = PieceGenerator(random: Random(3));
      expect(
        generator.generateTray(),
        everyElement(
          isA<Piece>().having(
            (p) => p.landmarkId,
            'landmarkId',
            placeholderLandmarkId,
          ),
        ),
      );
    });

    test('generated tray pieces own independent mutable matrices', () {
      final generator = PieceGenerator(random: Random(4));
      final tray = generator.generateTray();
      for (final piece in tray) {
        if (piece.isSpecial) continue;
        piece.shapeMatrix[0][0] = false;
      }
      // The const library must be untouched by mutating a tray piece.
      for (final definition in pieceShapeLibrary) {
        expect(definition.filledCellCount, greaterThan(0));
      }
    });

    test('the special piece is a single small square when it spawns', () {
      final generator = PieceGenerator(random: Random(5));
      var special = generator.generateTray().firstWhere(
        (piece) => piece.isSpecial,
        orElse: () =>
            const Piece.special(id: 'sentinel', landmarkId: 'sentinel'),
      );
      // Seeded deterministically: generate until a real special appears.
      var guard = 0;
      while (special.id == 'sentinel' && guard < 1000) {
        final tray = generator.generateTray();
        special = tray.firstWhere(
          (piece) => piece.isSpecial,
          orElse: () => special,
        );
        guard++;
      }
      expect(special.isSpecial, isTrue);
      expect(special.rows, 1);
      expect(special.cols, 1);
      expect(special.shapeMatrix, [
        [true],
      ]);
      expect(special.id, 'special');
      expect(special.landmarkId, placeholderLandmarkId);
    });

    test('special piece spawn rate over many trials roughly matches '
        'SPECIAL_PIECE_SPAWN_RATE', () {
      const trials = 2000;
      final generator = PieceGenerator(random: Random(42));
      var traysWithSpecial = 0;
      for (var i = 0; i < trials; i++) {
        final tray = generator.generateTray();
        if (tray.any((piece) => piece.isSpecial)) traysWithSpecial++;
      }
      final frequency = traysWithSpecial / trials;
      // 0.04 tolerance at n=2000 is ~4.8 sigma for p = 1/6 — effectively
      // non-flaky while still catching real deviations.
      expect(
        frequency,
        closeTo(SPECIAL_PIECE_SPAWN_RATE, 0.04),
        reason:
            'spawn frequency was $frequency over $trials trays '
            '(expected ~$SPECIAL_PIECE_SPAWN_RATE)',
      );
      expect(traysWithSpecial, greaterThan(0));
      expect(traysWithSpecial, lessThan(trials));
    });

    test('generators with the same seed produce identical tray sequences', () {
      final a = PieceGenerator(random: Random(7));
      final b = PieceGenerator(random: Random(7));
      for (var i = 0; i < 50; i++) {
        expect(a.generateTray(), b.generateTray(), reason: 'tray $i diverged');
      }
    });
  });
}
