/// Stage model: id, orderIndex (1..30), targetScore — pure Dart, no Flutter
/// imports (AI_RULES #2), no magic numbers (AI_RULES #5; target values come
/// from the civilization data phase, not from logic).
library;

/// One of a civilization's 30 sub-stages (PRD 5.3 / PRD 11).
///
/// Immutable value type consumed by the game controller (`startStage`) and
/// the stage select screen; produced by the civilization data phase.
class Stage {
  /// Unique stage identifier, referenced by `GameResult.stageId`.
  final String id;

  /// Position within the civilization's stage list, 1..30 (PRD 5.3).
  final int orderIndex;

  /// Score the player must reach to pass the stage (PRD 5.3); checked via
  /// `hasReachedTarget`.
  final int targetScore;

  const Stage({
    required this.id,
    required this.orderIndex,
    required this.targetScore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stage &&
          other.id == id &&
          other.orderIndex == orderIndex &&
          other.targetScore == targetScore;

  @override
  int get hashCode => Object.hash(id, orderIndex, targetScore);

  @override
  String toString() => 'Stage($id, order: $orderIndex, target: $targetScore)';
}
