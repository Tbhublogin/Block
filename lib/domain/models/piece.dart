/// Piece model (PRD §5.2 / §11): a block-blast shape with its bounding-box
/// `shapeMatrix`, plus the special single-square "line/column clear" piece.
///
/// Pure Dart — no Flutter imports (AI_RULES #2). `landmarkId` is a reference
/// key only; artwork assets are resolved by the presentation layer.
///
/// The constructor is const so `core/constants/piece_shapes.dart` can hold
/// the shape library as a compile-time constant list (BUILD_PROMPTS 1.3).
/// Const-assert rules forbid runtime checks like "matrix is rectangular"
/// here, so that invariant is by convention: a shape matrix is always
/// non-empty and rectangular, and special pieces can only be built through
/// [Piece.special], which guarantees their 1x1 `[[true]]` shape.
library;

/// Immutable value type for one tray piece or shape-library definition.
class Piece {
  /// Unique identifier for this piece/shape definition.
  final String id;

  /// Bounding-box occupancy matrix (`true` = filled cell), rectangular and
  /// at least 1x1. For the special piece this is exactly `[[true]]`.
  final List<List<bool>> shapeMatrix;

  /// `true` for the single small-square piece that clears its entire row and
  /// column unconditionally on placement (PRD §5.2, AI_RULES #16/#17).
  final bool isSpecial;

  /// Reference key linking this piece to its landmark artwork and museum
  /// entry — never an asset path.
  final String landmarkId;

  const Piece({
    required this.id,
    required this.shapeMatrix,
    this.isSpecial = false,
    required this.landmarkId,
  }) : assert(
         !isSpecial,
         'special pieces must use the Piece.special constructor',
       );

  /// The special "line/column clear" piece: a single small square whose
  /// `shapeMatrix` is a 1x1 `[[true]]` (per the build spec for prompt 1.1).
  const Piece.special({required this.id, required this.landmarkId})
    : shapeMatrix = const [
        [true],
      ],
      isSpecial = true;

  /// Number of rows in the shape's bounding box.
  int get rows => shapeMatrix.length;

  /// Number of columns in the shape's bounding box.
  int get cols => shapeMatrix.first.length;

  /// Number of filled cells in the shape.
  int get filledCellCount =>
      shapeMatrix.fold(0, (n, row) => n + row.where((c) => c).length);

  bool _matrixEquals(List<List<bool>> other) {
    if (shapeMatrix.length != other.length) return false;
    for (var r = 0; r < shapeMatrix.length; r++) {
      final rowA = shapeMatrix[r];
      final rowB = other[r];
      if (rowA.length != rowB.length) return false;
      for (var c = 0; c < rowA.length; c++) {
        if (rowA[c] != rowB[c]) return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece &&
          other.id == id &&
          other.isSpecial == isSpecial &&
          other.landmarkId == landmarkId &&
          other._matrixEquals(shapeMatrix);

  @override
  int get hashCode => Object.hash(
    id,
    isSpecial,
    landmarkId,
    Object.hashAll(shapeMatrix.map(Object.hashAll)),
  );

  @override
  String toString() => isSpecial
      ? 'Piece.special($id, landmarkId: $landmarkId)'
      : 'Piece($id, ${rows}x$cols, cells: $filledCellCount, '
            'landmarkId: $landmarkId)';
}
