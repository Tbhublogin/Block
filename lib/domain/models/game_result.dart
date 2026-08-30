/// Game result model: immutable snapshot of a stage outcome (win/lose),
/// produced by the game controller and consumed by the stage result dialogs.
///
/// Pure Dart — no Flutter imports (AI_RULES #2).
library;

/// How a stage attempt ended.
enum GameOutcome { win, lose }

/// Immutable value type describing the outcome of one stage attempt.
class GameResult {
  /// The stage this result belongs to (matches `Stage.id`).
  final String stageId;

  /// Whether the stage was won or lost.
  final GameOutcome outcome;

  /// Final score reached during the stage attempt.
  final int score;

  /// The stage's target score, kept alongside the score for summary display.
  final int targetScore;

  const GameResult({
    required this.stageId,
    required this.outcome,
    required this.score,
    required this.targetScore,
  });

  bool get isWin => outcome == GameOutcome.win;

  bool get isLose => outcome == GameOutcome.lose;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameResult &&
          other.stageId == stageId &&
          other.outcome == outcome &&
          other.score == score &&
          other.targetScore == targetScore;

  @override
  int get hashCode => Object.hash(stageId, outcome, score, targetScore);

  @override
  String toString() =>
      'GameResult($stageId, $outcome, score: $score, '
      'target: $targetScore)';
}
