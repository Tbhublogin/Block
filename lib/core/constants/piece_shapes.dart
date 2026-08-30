library;

/// Fixed shape library for normal pieces (standard block-blast shapes,
/// PRD 5.2 / BUILD_PROMPTS 1.3).
///
/// Every entry is a compile-time const with `landmarkId` set to
/// [placeholderLandmarkId] — real landmark assignment happens in the
/// civilization content phase. The special "line/column clear" piece
/// (PRD 5.2, AI_RULES #16) is defined here too so all piece definitions
/// live in core/constants and the generator stays pure selection logic.
///
/// Rectangularity of `shapeMatrix` is by convention (const-assert rules
/// forbid runtime checks — see the Piece model docs); every matrix below is
/// non-empty and rectangular, and every shape fits the 8x8 grid.

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/models/piece.dart';

/// All normal piece shapes, named `snake_case` per the existing test
/// convention (`l_shape`, `i3_horiz`, ...). Rotated shapes (L, T) are named
/// by the direction the corner/stem points. Tray generation picks uniformly
/// from this list with replacement.
const List<Piece> pieceShapeLibrary = [
  // Singles.
  Piece(
    id: 'single',
    shapeMatrix: [
      [true],
    ],
    landmarkId: placeholderLandmarkId,
  ),

  // I variants: horizontal and vertical, lengths 2–5.
  Piece(
    id: 'i2_horiz',
    shapeMatrix: [
      [true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i2_vert',
    shapeMatrix: [
      [true],
      [true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i3_horiz',
    shapeMatrix: [
      [true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i3_vert',
    shapeMatrix: [
      [true],
      [true],
      [true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i4_horiz',
    shapeMatrix: [
      [true, true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i4_vert',
    shapeMatrix: [
      [true],
      [true],
      [true],
      [true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i5_horiz',
    shapeMatrix: [
      [true, true, true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'i5_vert',
    shapeMatrix: [
      [true],
      [true],
      [true],
      [true],
      [true],
    ],
    landmarkId: placeholderLandmarkId,
  ),

  // Squares.
  Piece(
    id: 'square_2x2',
    shapeMatrix: [
      [true, true],
      [true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'square_3x3',
    shapeMatrix: [
      [true, true, true],
      [true, true, true],
      [true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),

  // Small L / corners (3 cells in a 2x2 box), all four rotations.
  Piece(
    id: 'l_small_bottom_left',
    shapeMatrix: [
      [true, false],
      [true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'l_small_bottom_right',
    shapeMatrix: [
      [false, true],
      [true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'l_small_top_left',
    shapeMatrix: [
      [true, true],
      [true, false],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'l_small_top_right',
    shapeMatrix: [
      [true, true],
      [false, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),

  // Large L (4 cells in a 3x3 box), all four rotations.
  Piece(
    id: 'l_large_bottom_left',
    shapeMatrix: [
      [true, false, false],
      [true, false, false],
      [true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'l_large_bottom_right',
    shapeMatrix: [
      [false, false, true],
      [false, false, true],
      [true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'l_large_top_left',
    shapeMatrix: [
      [true, true, true],
      [true, false, false],
      [true, false, false],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'l_large_top_right',
    shapeMatrix: [
      [true, true, true],
      [false, false, true],
      [false, false, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),

  // T (4 cells), named by the direction the stem points.
  Piece(
    id: 't_down',
    shapeMatrix: [
      [true, true, true],
      [false, true, false],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 't_up',
    shapeMatrix: [
      [false, true, false],
      [true, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 't_right',
    shapeMatrix: [
      [true, false],
      [true, true],
      [true, false],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 't_left',
    shapeMatrix: [
      [false, true],
      [true, true],
      [false, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),

  // S / Z, horizontal and vertical.
  Piece(
    id: 's_horiz',
    shapeMatrix: [
      [false, true, true],
      [true, true, false],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'z_horiz',
    shapeMatrix: [
      [true, true, false],
      [false, true, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 's_vert',
    shapeMatrix: [
      [true, false],
      [true, true],
      [false, true],
    ],
    landmarkId: placeholderLandmarkId,
  ),
  Piece(
    id: 'z_vert',
    shapeMatrix: [
      [false, true],
      [true, true],
      [true, false],
    ],
    landmarkId: placeholderLandmarkId,
  ),
];

/// The special "line/column clear" piece: a single small square that clears
/// its entire row and column unconditionally when placed (PRD 5.2,
/// AI_RULES #16/#17 — BoardEngine handles the clear in `place()`).
const Piece specialPiece = Piece.special(
  id: 'special',
  landmarkId: placeholderLandmarkId,
);
