/// Progress controller (Phase 2, BUILD_PROMPTS 2.2): a Riverpod `Notifier`
/// tracking per-civilization stage unlocks and completed civilizations,
/// persisted via Hive (PRD 3/5.3).
///
/// Unlocks are stored as the highest unlocked stage index per civilization
/// (a civilization's first stage is index 1), so the persistence model stays
/// exactly PRD 11's `UserProgress` sketch: one `Map<String, int>` in a Hive
/// box keyed by civilization id. Civilization 1 is unlocked from the start;
/// completing civilization N's stage 30 unlocks the next civilization in
/// `civilizationsCatalog` (and marks N completed) — PRD 5.3.
///
/// Persistence timing (PRD 12): every mutation writes to Hive immediately,
/// not only on app close, so progress survives a crash. Hive writes on the
/// same isolate are synchronous-enough for this purpose; the controller does
/// not await them (fire-and-forget) to keep mutations synchronous.
///
/// Depends only on core/constants and Riverpod — no UI widgets, no Flutter
/// material imports (AI_RULES #2/#4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/data/datasources/civilizations_data.dart';
import 'package:block_civilizations/domain/models/civilization.dart';

/// Name of the Hive box holding progression data (PRD 3: Hive is the store
/// for structured progress data). Opened in main() and overridden into
/// [progressBoxProvider]; tests open their own temp-dir boxes.
const String progressBoxName = 'progress';

/// Id of the civilization that is unlocked from the start (PRD 5.3): the
/// first entry of `civilizationsCatalog` (currently `iraq`). The catalog
/// contains only civilization #1 so far; entries 2–8 join it in post-launch
/// content phases (PROJECT_STATE.md §5). Kept as a literal because
/// `firstCatalogCivilization.id` is not usable in a const context — add a
/// test when the catalog grows to assert it stays in sync.
const String firstCivilizationId = 'iraq';

/// Exposes the app-wide, pre-opened Hive [Box] for progression data.
///
/// The box is dynamically typed (`Box` = `Box<dynamic>`) because it holds
/// two differently shaped entries: the unlock map and the completed-civs
/// list — a typed box would reject one of them on `put`. Values are cast on
/// read in [ProgressController.build].
///
/// Must be overridden with an open box (main.dart does this after
/// `Hive.openBox(progressBoxName)`) before anything reads it; tests override
/// it with boxes from a temp directory (same DI pattern as
/// `sharedPreferencesProvider`).
final progressBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError(
    'progressBoxProvider must be overridden with an opened Hive box in '
    'main() (or a temp-dir box in tests).',
  );
});

/// Riverpod controller for stage/civilization unlock progress (PRD 5.3).
final progressProvider = NotifierProvider<ProgressController, UserProgress>(
  ProgressController.new,
);

/// Immutable snapshot of all progression data (PRD 11's `UserProgress`
/// sketch): the highest unlocked stage index per civilization id and the set
/// of civilization ids that finished all 30 stages.
class UserProgress {
  /// Highest unlocked stage index (1..[stagesPerCivilization]) per
  /// civilization id. A civilization missing from the map is locked entirely
  /// (except the first, which is always unlocked — see
  /// [ProgressController.isCivilizationUnlocked]).
  final Map<String, int> highestUnlockedStageIndexPerCivilization;

  /// Civilization ids that completed stage [stagesPerCivilization] (map
  /// checkmark on the map screen, PRD 5.3/6).
  final Set<String> completedCivilizations;

  const UserProgress({
    required this.highestUnlockedStageIndexPerCivilization,
    required this.completedCivilizations,
  });

  /// Fresh-install state: nothing unlocked, nothing completed. Civilization
  /// 1's "unlocked" status is a rule of the unlock logic, not stored state.
  const UserProgress.initial()
    : highestUnlockedStageIndexPerCivilization = const {},
      completedCivilizations = const {};

  /// Rebuilds with the given map/set; used by the controller instead of a
  /// hand-rolled copyWith (no partial-update call sites exist).
  UserProgress withData({
    required Map<String, int> highestUnlockedStageIndexPerCivilization,
    required Set<String> completedCivilizations,
  }) => UserProgress(
    highestUnlockedStageIndexPerCivilization:
        highestUnlockedStageIndexPerCivilization,
    completedCivilizations: completedCivilizations,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgress &&
          _mapsEqual(
            other.highestUnlockedStageIndexPerCivilization,
            highestUnlockedStageIndexPerCivilization,
          ) &&
          other.completedCivilizations.length ==
              completedCivilizations.length &&
          other.completedCivilizations.every(completedCivilizations.contains);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      highestUnlockedStageIndexPerCivilization.entries.map(
        (e) => Object.hash(e.key, e.value),
      ),
    ),
    Object.hashAllUnordered(completedCivilizations),
  );

  @override
  String toString() =>
      'UserProgress(unlocked: $highestUnlockedStageIndexPerCivilization, '
      'completed: $completedCivilizations)';

  static bool _mapsEqual(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}

class ProgressController extends Notifier<UserProgress> {
  @override
  UserProgress build() {
    final box = ref.watch(progressBoxProvider);
    final storedUnlocked = box.get(_highestUnlockedKey);
    final storedCompleted = box.get(_completedKey);
    return UserProgress(
      highestUnlockedStageIndexPerCivilization: storedUnlocked == null
          ? const {}
          : Map<String, int>.from(storedUnlocked),
      completedCivilizations: storedCompleted == null
          ? const {}
          : Set<String>.from(storedCompleted),
    );
  }

  /// Marks stage [stageIndex] (1..[stagesPerCivilization]) of civilization
  /// [civilizationId] as completed and unlocks the next thing (PRD 5.3):
  /// stage [stageIndex] + 1 of the same civilization — or, when
  /// [stageIndex] == [stagesPerCivilization], the first stage of the next
  /// civilization plus the completed checkmark for [civilizationId].
  ///
  /// Idempotent and monotonic: replaying an already-completed stage never
  /// lowers or rewrites the unlocked index, so a later replay of stage 2
  /// after stage 7 is unlocked is a no-op.
  Future<void> markStageCompleted(String civilizationId, int stageIndex) {
    return _mutate((progress) {
      final highest =
          progress.highestUnlockedStageIndexPerCivilization[civilizationId];
      if (stageIndex >= stagesPerCivilization) {
        // Final stage: this civilization completes and the next catalog
        // civilization's first stage unlocks, when one exists (PRD 5.3).
        // The stage-30 entry is also stored so stage select can render
        // "completed" for its node.
        final nextId = _nextCivilizationId(civilizationId);
        final nextUnlocked = <String, int>{
          ...progress.highestUnlockedStageIndexPerCivilization,
          civilizationId: stagesPerCivilization,
          ?nextId: 1,
        };
        return progress.withData(
          highestUnlockedStageIndexPerCivilization: nextUnlocked,
          completedCivilizations: {
            ...progress.completedCivilizations,
            civilizationId,
          },
        );
      }

      if (highest != null && highest > stageIndex) {
        // A later stage of this civilization is already unlocked (e.g. a
        // replay of an earlier stage) — keep the higher unlock.
        return progress;
      }

      return progress.withData(
        highestUnlockedStageIndexPerCivilization: {
          ...progress.highestUnlockedStageIndexPerCivilization,
          civilizationId: stageIndex + 1,
        },
        completedCivilizations: progress.completedCivilizations,
      );
    });
  }

  /// Whether the civilization is playable at all. The first civilization
  /// ([firstCivilizationId], the first [Civilization] in
  /// [civilizationsCatalog]) is unlocked from the start (PRD 5.3); every other
  /// one requires its first stage to have been unlocked by the previous
  /// civilization's completion.
  bool isCivilizationUnlocked(String civilizationId) {
    if (civilizationId == firstCivilizationId) return true;
    return state.highestUnlockedStageIndexPerCivilization.containsKey(
      civilizationId,
    );
  }

  /// Whether stage [stageIndex] of [civilizationId] is playable: the
  /// civilization must be unlocked and its highest unlocked index must be
  /// at least [stageIndex]. Out-of-range indices are never unlocked. The
  /// first civilization's stage 1 is unlocked on a fresh install (PRD 5.3),
  /// so a missing entry for it counts as stage 1 unlocked.
  bool isStageUnlocked(String civilizationId, int stageIndex) {
    if (stageIndex < 1 || stageIndex > stagesPerCivilization) return false;
    if (!isCivilizationUnlocked(civilizationId)) return false;
    final highest =
        state.highestUnlockedStageIndexPerCivilization[civilizationId] ??
        (civilizationId == firstCivilizationId ? 1 : null);
    return highest != null && highest >= stageIndex;
  }

  static const String _highestUnlockedKey = 'highestUnlockedStageIndex';

  /// Persists [mutate]'s result to state and to Hive in one place so every
  /// mutation is durable immediately (PRD 12: persist after every stage
  /// completion, not only on app close).
  Future<void> _mutate(
    UserProgress Function(UserProgress progress) mutate,
  ) async {
    final box = ref.read(progressBoxProvider);
    final next = mutate(state);
    state = next;

    await box.put(
      _highestUnlockedKey,
      Map<String, int>.of(next.highestUnlockedStageIndexPerCivilization),
    );
    await box.put(_completedKey, next.completedCivilizations.toList());
  }

  static const String _completedKey = 'completedCivilizations';

  /// Returns the id of the civilization following [civilizationId] in
  /// [civilizationsCatalog]'s unlock order, or null when [civilizationId]
  /// is unknown or is the last entry — in both cases completing it must not
  /// unlock anything further.
  static String? _nextCivilizationId(String civilizationId) {
    for (var i = 0; i < civilizationsCatalog.length; i++) {
      if (civilizationsCatalog[i].id == civilizationId) {
        if (i + 1 >= civilizationsCatalog.length) return null;
        return civilizationsCatalog[i + 1].id;
      }
    }
    return null;
  }
}
