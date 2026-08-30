/// One cell of the game grid (PRD §5.1): either empty, or holding a
/// reference to the `landmarkId` of the piece occupying it, which the
/// presentation layer resolves to artwork/color at render time.
///
/// Pure Dart — no Flutter imports (AI_RULES #2).
library;

/// Immutable value type for a single grid cell.
class BoardCell {
  /// The landmark occupying this cell, or `null` when the cell is empty.
  final String? landmarkId;

  /// An empty cell (no piece occupies it).
  const BoardCell.empty() : landmarkId = null;

  /// A cell occupied by a piece with the given [landmarkId].
  const BoardCell.filled(String this.landmarkId);

  bool get isEmpty => landmarkId == null;

  bool get isFilled => landmarkId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCell && other.landmarkId == landmarkId;

  @override
  int get hashCode => landmarkId.hashCode;

  @override
  String toString() =>
      isEmpty ? 'BoardCell.empty' : 'BoardCell.filled($landmarkId)';
}
