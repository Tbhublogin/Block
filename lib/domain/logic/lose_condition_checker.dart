/// Lose detection (BUILD_PROMPTS 1.4, PRD 5.4): true when NONE of the 3
/// tray pieces can be legally placed anywhere on the grid — pure Dart, no
/// Flutter imports (AI_RULES #2).
///
/// Orientation assumption: pieces are placed in their stored orientation
/// only. The shape library (`piece_shapes.dart`) pre-enumerates every
/// rotation as separate const entries (e.g. "all four rotations" for the L
/// and T shapes), and no runtime rotation exists anywhere, so there is
/// nothing to iterate here. If the library ever switches to canonical
/// shapes rotated at runtime, this checker must gain a rotation loop per
/// piece.
library;

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
import 'package:block_civilizations/domain/models/piece.dart';

/// Whether the stage is lost: [tray] is the current 3-piece tray and no
/// piece in it fits at any anchor position on [engine]'s grid.
///
/// Pieces are probed in their stored orientation only (see the
/// orientation assumption in the library docs). An empty tray, or a piece
/// larger than the grid itself, counts as unplaceable — both naturally
/// fall out of the probe loops below.
bool isLoseConditionMet(BoardEngine engine, List<Piece> tray) {
  for (final piece in tray) {
    for (var row = 0; row <= gridSize - piece.rows; row++) {
      for (var col = 0; col <= gridSize - piece.cols; col++) {
        if (engine.canPlace(piece, row, col)) return false;
      }
    }
  }
  return true;
}
