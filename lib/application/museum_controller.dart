/// Museum controller (Phase 2, BUILD_PROMPTS 2.2): a Riverpod `Notifier`
/// tracking which landmarks (by reference id) the player has unlocked for
/// the museum collection, persisted via Hive (PRD 3/6).
///
/// The game controller calls `unlockLandmark(piece.landmarkId)` on every
/// successful placement, so the museum fills up as a side effect of normal
/// play. Idempotent: re-placing a known landmark is a no-op.
///
/// Persistence timing (PRD 12): every mutation writes to Hive immediately.
/// Depends only on Riverpod — no UI widgets, no Flutter material imports
/// (AI_RULES #2/#4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Name of the Hive box holding museum unlocks (PRD 3: Hive is the store
/// for structured data like unlocked museum pieces). Opened in main() and
/// overridden into [museumBoxProvider]; tests open their own temp-dir boxes.
const String museumBoxName = 'museum';

/// Exposes the app-wide, pre-opened Hive [Box] for museum unlocks.
///
/// Must be overridden with an open box (main.dart does this after
/// `Hive.openBox(museumBoxName)`) before anything reads it; tests override
/// it with boxes from a temp directory (same DI pattern as
/// `sharedPreferencesProvider`).
final museumBoxProvider = Provider<Box<List>>((ref) {
  throw UnimplementedError(
    'museumBoxProvider must be overridden with an opened Hive box in '
    'main() (or a temp-dir box in tests).',
  );
});

/// Riverpod controller for the museum collection (PRD 6).
final museumProvider = NotifierProvider<MuseumController, MuseumState>(
  MuseumController.new,
);

/// Immutable snapshot of the museum collection.
class MuseumState {
  /// Landmark reference ids unlocked so far (PRD 11's
  /// `unlockedLandmarkIds`); the museum screen renders one tile per entry.
  final Set<String> unlockedLandmarkIds;

  const MuseumState({required this.unlockedLandmarkIds});

  /// Fresh-install state: nothing discovered yet.
  const MuseumState.initial() : unlockedLandmarkIds = const {};

  MuseumState withLandmarks(Set<String> unlockedLandmarkIds) =>
      MuseumState(unlockedLandmarkIds: unlockedLandmarkIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuseumState &&
          other.unlockedLandmarkIds.length == unlockedLandmarkIds.length &&
          other.unlockedLandmarkIds.every(unlockedLandmarkIds.contains);

  @override
  int get hashCode => Object.hashAllUnordered(unlockedLandmarkIds);

  @override
  String toString() => 'MuseumState(unlocked: $unlockedLandmarkIds)';
}

class MuseumController extends Notifier<MuseumState> {
  @override
  MuseumState build() {
    final box = ref.watch(museumBoxProvider);
    final stored = box.get(_unlockedKey);
    return MuseumState(
      unlockedLandmarkIds: stored == null ? const {} : Set<String>.from(stored),
    );
  }

  /// Unlocks [landmarkId] for the museum and persists immediately. Returns
  /// whether this call newly unlocked it (i.e. it was not already in the
  /// collection) — the game flow does not branch on this today, but
  /// `attemptPlacePiece` relies on the idempotence, and a future
  /// "new discovery" toast can key off the return value.
  Future<bool> unlockLandmark(String landmarkId) async {
    final box = ref.read(museumBoxProvider);
    if (state.unlockedLandmarkIds.contains(landmarkId)) return false;

    final next = {...state.unlockedLandmarkIds, landmarkId};
    state = state.withLandmarks(next);
    await box.put(_unlockedKey, next.toList());
    return true;
  }

  static const String _unlockedKey = 'unlockedLandmarkIds';
}
