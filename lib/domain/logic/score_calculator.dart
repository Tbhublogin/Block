/// Pure scoring rules (BUILD_PROMPTS 1.4): placement points, line-clear
/// bonuses (named constants), and stage target handling (PRD 5.3) — pure
/// Dart, no Flutter imports (AI_RULES #2), no magic numbers (AI_RULES #5).
library;

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/logic/board_engine.dart';
import 'package:block_civilizations/domain/models/piece.dart';

/// Points earned for placing [piece], before any line-clear bonus: one
/// [pointsPerCellFilled] per filled cell of the piece.
int placementScore(Piece piece) => piece.filledCellCount * pointsPerCellFilled;

/// Bonus points earned for the lines cleared by [result]: one
/// [bonusPerLineCleared] per cleared row and per cleared column. For the
/// special piece the engine reports its own row and column
/// unconditionally, so they score like any other cleared line.
int clearBonus(PlacementResult result) =>
    (result.fullRows.length + result.fullCols.length) * bonusPerLineCleared;

/// Total points earned by one move: placing [piece] and clearing the lines
/// reported in [result].
int moveScore(Piece piece, PlacementResult result) =>
    placementScore(piece) + clearBonus(result);

/// Whether [score] has reached the sub-stage's [targetScore] (PRD 5.3:
/// reaching the target triggers the Stage Win state).
bool hasReachedTarget(int score, int targetScore) => score >= targetScore;
