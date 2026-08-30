/// Civilization model: id, nameKey, emblemAsset, themeColorHex, 30 stages.
/// Pure Dart, no Flutter imports (AI_RULES #2), per PRD 11.
library;

import 'package:block_civilizations/domain/models/stage.dart';

/// One playable civilization on the map screen (PRD 11), produced by the
/// civilization data phase (`data/datasources/civilizations_data.dart`).
class Civilization {
  /// Unique civilization identifier, referenced by
  /// `UserProgress.highestUnlockedStageIndexPerCivilization` and by
  /// [LandmarkInfo.civilizationId].
  final String id;

  /// Localization key (ARB) for the civilization's display name.
  final String nameKey;

  /// Map-screen emblem image path, or null when no source image exists and
  /// the emblem is hand-drawn via `civilization_emblem_painter.dart`
  /// (CustomPainter) instead — e.g. civilization #1 (Iraq/Mesopotamia) is
  /// null-by-design (PRD 10/11).
  final String? emblemAsset;

  /// Hex color string (e.g. `#C9A227`) driving the civilization's UI
  /// palette; parsed by the theme layer.
  final String themeColorHex;

  /// The civilization's 30 sub-stages in order (PRD 5.3).
  final List<Stage> stages;

  const Civilization({
    required this.id,
    required this.nameKey,
    required this.themeColorHex,
    required this.stages,
    this.emblemAsset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Civilization &&
          other.id == id &&
          other.nameKey == nameKey &&
          other.emblemAsset == emblemAsset &&
          other.themeColorHex == themeColorHex &&
          const ListEquality<Stage>().equals(other.stages, stages);

  @override
  int get hashCode => Object.hash(
    id,
    nameKey,
    emblemAsset,
    themeColorHex,
    Object.hashAll(stages),
  );

  @override
  String toString() =>
      'Civilization($id, nameKey: $nameKey, emblem: $emblemAsset, '
      'color: $themeColorHex, stages: ${stages.length})';
}

/// Element-wise list equality (no collection package dependency).
class ListEquality<T> {
  const ListEquality();

  bool equals(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
