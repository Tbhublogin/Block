/// Piece generator (PRD 5.2 / BUILD_PROMPTS 1.3): refills the tray with
/// [traySize] pieces drawn from the const shape library, replacing one of
/// them with the special "line/column clear" piece with probability
/// [SPECIAL_PIECE_SPAWN_RATE].
///
/// Pure Dart — no Flutter imports (AI_RULES #2); all tunables come from
/// core/constants, no inline magic numbers (AI_RULES #5).
///
/// `landmarkId` on generated pieces is [placeholderLandmarkId] for now;
/// actual landmark mapping arrives in a later phase once civilization
/// content is provided.
library;

import 'dart:math';

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/core/constants/piece_shapes.dart';
import 'package:block_civilizations/domain/models/piece.dart';

/// Generates trays of [traySize] pieces for the piece tray.
///
/// [random] is injectable so tests can seed it for deterministic,
/// statistically-stable assertions; production code uses the default
/// [`Random()`].
class PieceGenerator {
  /// Creates a generator; pass a seeded [random] in tests.
  PieceGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Builds one tray: [traySize] shapes picked uniformly from
  /// [pieceShapeLibrary] with replacement (duplicate shapes in one tray are
  /// standard block-blast behavior), then — with probability
  /// [SPECIAL_PIECE_SPAWN_RATE] — one random slot is swapped for the special
  /// piece.
  List<Piece> generateTray() {
    final tray = List<Piece>.generate(
      traySize,
      (_) => _instantiate(
        pieceShapeLibrary[_random.nextInt(pieceShapeLibrary.length)],
      ),
    );
    if (_random.nextDouble() < SPECIAL_PIECE_SPAWN_RATE) {
      tray[_random.nextInt(traySize)] = _instantiate(specialPiece);
    }
    return tray;
  }

  /// Copies a library piece so each normal tray piece owns a fresh,
  /// mutable-safe matrix instead of sharing the const library's lists.
  /// Special pieces must be rebuilt through [Piece.special] — the default
  /// constructor cannot produce `isSpecial: true` (see the Piece model's
  /// assert); their 1x1 matrix is the shared const `[[true]]` by design.
  static Piece _instantiate(Piece definition) => definition.isSpecial
      ? Piece.special(id: definition.id, landmarkId: definition.landmarkId)
      : Piece(
          id: definition.id,
          shapeMatrix: [
            for (final row in definition.shapeMatrix) List<bool>.of(row),
          ],
          landmarkId: definition.landmarkId,
        );
}
