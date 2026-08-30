/// LandmarkInfo model: id, civilizationId, nameKey, historicalFactKey,
/// imageAsset — pure Dart, no Flutter imports (AI_RULES #2), per PRD 11.
library;

/// A historical landmark belonging to one civilization (PRD 6/10/11): the
/// museum entry behind a piece's `landmarkId`, produced by the civilization
/// data phase (`data/datasources/civilizations_data.dart`).
class LandmarkInfo {
  /// The landmark's unique reference key — matches `Piece.landmarkId` and
  /// `MuseumState.unlockedLandmarkIds` (snake_case, e.g. `ziggurat_of_ur`).
  final String id;

  /// Id of the civilization this landmark belongs to.
  final String civilizationId;

  /// Localization key (ARB) for the landmark's display name.
  final String nameKey;

  /// Localization key (ARB) for the landmark's historical fact paragraph
  /// (ar/en, PRD 6/10).
  final String historicalFactKey;

  /// Asset path of the landmark artwork
  /// (`assets/civilizations/<civilization_id>/<landmark_id>.png`, PRD 10).
  final String imageAsset;

  const LandmarkInfo({
    required this.id,
    required this.civilizationId,
    required this.nameKey,
    required this.historicalFactKey,
    required this.imageAsset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandmarkInfo &&
          other.id == id &&
          other.civilizationId == civilizationId &&
          other.nameKey == nameKey &&
          other.historicalFactKey == historicalFactKey &&
          other.imageAsset == imageAsset;

  @override
  int get hashCode =>
      Object.hash(id, civilizationId, nameKey, historicalFactKey, imageAsset);

  @override
  String toString() =>
      'LandmarkInfo($id, civ: $civilizationId, image: $imageAsset)';
}
