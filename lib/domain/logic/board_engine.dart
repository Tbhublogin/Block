/// Board engine (BUILD_PROMPTS 1.2): grid state, placement validation
/// (`canPlace`/`place`), and row/column clearing — pure Dart, fully
/// unit-testable (AI_RULES #2: no Flutter imports).
///
/// Special piece (PRD 5.2, AI_RULES #17): placing it clears its entire row
/// and column unconditionally, even when neither is full — a deliberate
/// deviation from standard block-blast rules, not a bug.
library;

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/domain/models/board_cell.dart';
import 'package:block_civilizations/domain/models/piece.dart';

/// Immutable result of [BoardEngine.place]: the lines cleared by that
/// placement, ready to feed into [BoardEngine.clearLines].
///
/// For normal pieces these are the rows/columns the placement made full.
/// For the special piece they are its own row and column, reported
/// unconditionally (PRD 5.2, AI_RULES #17).
class PlacementResult {
  /// Indices of the rows cleared by the placement.
  final List<int> fullRows;

  /// Indices of the columns cleared by the placement.
  final List<int> fullCols;

  const PlacementResult({required this.fullRows, required this.fullCols});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementResult &&
          other.fullRows.length == fullRows.length &&
          other.fullCols.length == fullCols.length &&
          other.fullRows.every(fullRows.contains) &&
          other.fullCols.every(fullCols.contains);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(fullRows),
    Object.hashAllUnordered(fullCols),
  );

  @override
  String toString() =>
      'PlacementResult(fullRows: $fullRows, fullCols: $fullCols)';
}

/// Mutable 8x8 game board: placement validation, line-full detection, and
/// line clearing.
class BoardEngine {
  /// Current grid contents; `grid[row][col]`.
  final List<List<BoardCell>> grid;

  /// Creates a board whose every cell is empty.
  BoardEngine() : grid = _emptyGrid();

  static List<List<BoardCell>> _emptyGrid() => List.generate(
    gridSize,
    (_) => List.filled(gridSize, const BoardCell.empty()),
  );

  /// Whether [piece] fits at anchor (`row`, `col`) — every filled matrix
  /// cell inside the grid and targeting an empty cell.
  bool canPlace(Piece piece, int row, int col) {
    for (var r = 0; r < piece.rows; r++) {
      for (var c = 0; c < piece.cols; c++) {
        if (!piece.shapeMatrix[r][c]) continue;
        final boardRow = row + r;
        final boardCol = col + c;
        final inside =
            boardRow >= 0 &&
            boardRow < gridSize &&
            boardCol >= 0 &&
            boardCol < gridSize;
        if (!inside || grid[boardRow][boardCol].isFilled) return false;
      }
    }
    return true;
  }

  /// Applies [piece] at anchor (`row`, `col`) and returns the lines cleared
  /// by the placement.
  ///
  /// Throws [AssertionError] when [canPlace] is false; callers check
  /// [canPlace] first (the game controller guards every attempt).
  ///
  /// If [piece].isSpecial, its row and column are cleared unconditionally
  /// here — even when neither is full (PRD 5.2, AI_RULES #17) — and
  /// reported as the result, so a follow-up [clearLines] on the same lines
  /// is a harmless no-op.
  PlacementResult place(Piece piece, int row, int col) {
    assert(
      canPlace(piece, row, col),
      'place() called on an invalid placement; check canPlace() first',
    );

    for (var r = 0; r < piece.rows; r++) {
      for (var c = 0; c < piece.cols; c++) {
        if (piece.shapeMatrix[r][c]) {
          grid[row + r][col + c] = BoardCell.filled(piece.landmarkId);
        }
      }
    }

    if (piece.isSpecial) {
      _clearRow(row);
      _clearColumn(col);
      return PlacementResult(fullRows: [row], fullCols: [col]);
    }

    return PlacementResult(
      fullRows: [
        for (var r = 0; r < piece.rows; r++)
          if (_isRowFull(row + r)) row + r,
      ],
      fullCols: [
        for (var c = 0; c < piece.cols; c++)
          if (_isColFull(col + c)) col + c,
      ],
    );
  }

  /// Empties every cell of the given [rows] and [cols]; idempotent.
  void clearLines(List<int> rows, List<int> cols) {
    for (final row in rows) {
      _clearRow(row);
    }
    for (final col in cols) {
      _clearColumn(col);
    }
  }

  /// Empties the whole grid (e.g. the rewarded-ad continue flow,
  /// AI_RULES #19).
  void reset() {
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        grid[row][col] = const BoardCell.empty();
      }
    }
  }

  void _clearRow(int row) {
    for (var col = 0; col < gridSize; col++) {
      grid[row][col] = const BoardCell.empty();
    }
  }

  void _clearColumn(int col) {
    for (var row = 0; row < gridSize; row++) {
      grid[row][col] = const BoardCell.empty();
    }
  }

  bool _isRowFull(int row) {
    for (var col = 0; col < gridSize; col++) {
      if (grid[row][col].isEmpty) return false;
    }
    return true;
  }

  bool _isColFull(int col) {
    for (var row = 0; row < gridSize; row++) {
      if (grid[row][col].isEmpty) return false;
    }
    return true;
  }
}
