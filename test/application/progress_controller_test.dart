/// Unit tests for the progress controller (Phase 2, BUILD_PROMPTS 2.2):
/// stage/civilization unlocking rules and Hive persistence across
/// controller recreation (PRD 5.3, PRD 11's UserProgress).
///
/// Hive has no mock mode like `SharedPreferences.setMockInitialValues`, so
/// real boxes are opened in a per-test temp directory (`Hive.init`) and
/// deleted in tearDown — the standard pure-Dart Hive test approach, no
/// widget tree involved.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:block_civilizations/application/progress_controller.dart';
import 'package:block_civilizations/core/constants/game_constants.dart';

/// Sequential ids matching the unlock-chain convention
/// (`civilization_1`, `civilization_2`, ...) that the map's civilization
/// ordering will use until the Phase 3 catalog defines it. The first is the
/// production [firstCivilizationId] the controller hard-unlocks.
const String _civ1 = firstCivilizationId;
const String _civ2 = 'civilization_2';
const String _civ3 = 'civilization_3';

late Directory _tempDir;
late Box _box;

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [progressBoxProvider.overrideWithValue(_box)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() async {
    _tempDir = await Directory.systemTemp.createTemp('progress_test');
    Hive.init(_tempDir.path);
    _box = await Hive.openBox(progressBoxName);
  });

  tearDown(() async {
    await _box.deleteFromDisk();
    await _tempDir.delete(recursive: true);
    Hive.resetAdapters();
  });

  group('ProgressController — fresh install', () {
    test('starts with nothing unlocked and nothing completed', () {
      final container = _container();
      final progress = container.read(progressProvider);

      expect(progress.highestUnlockedStageIndexPerCivilization, isEmpty);
      expect(progress.completedCivilizations, isEmpty);
      expect(progress, const UserProgress.initial());
    });

    test('the first civilization is unlocked with only its first stage', () {
      final container = _container();
      final controller = container.read(progressProvider.notifier);

      expect(controller.isCivilizationUnlocked(_civ1), isTrue);
      expect(controller.isStageUnlocked(_civ1, 1), isTrue);
      expect(controller.isStageUnlocked(_civ1, 2), isFalse);
    });

    test('no other civilization is unlocked', () {
      final container = _container();
      final controller = container.read(progressProvider.notifier);

      expect(controller.isCivilizationUnlocked(_civ2), isFalse);
      expect(controller.isCivilizationUnlocked(_civ3), isFalse);
      expect(controller.isStageUnlocked(_civ2, 1), isFalse);
    });
  });

  group('ProgressController — isStageUnlocked bounds', () {
    test('indices outside 1..stagesPerCivilization are never unlocked', () {
      final container = _container();
      final controller = container.read(progressProvider.notifier);

      expect(controller.isStageUnlocked(_civ1, 0), isFalse);
      expect(
        controller.isStageUnlocked(_civ1, stagesPerCivilization + 1),
        isFalse,
      );
      expect(controller.isStageUnlocked(_civ1, -3), isFalse);
    });
  });

  group('ProgressController — markStageCompleted', () {
    test(
      'completing a stage unlocks the next one, not the one after',
      () async {
        final container = _container();
        final controller = container.read(progressProvider.notifier);

        await controller.markStageCompleted(_civ1, 1);

        expect(controller.isStageUnlocked(_civ1, 1), isTrue);
        expect(controller.isStageUnlocked(_civ1, 2), isTrue);
        expect(controller.isStageUnlocked(_civ1, 3), isFalse);
        expect(
          container
              .read(progressProvider)
              .highestUnlockedStageIndexPerCivilization[_civ1],
          2,
        );
      },
    );

    test(
      'completion is monotonic: a replayed earlier stage is a no-op',
      () async {
        final container = _container();
        final controller = container.read(progressProvider.notifier);

        await controller.markStageCompleted(_civ1, 4);
        expect(controller.isStageUnlocked(_civ1, 5), isTrue);

        // Replaying stage 2 must not lower the unlock to 3.
        await controller.markStageCompleted(_civ1, 2);

        expect(controller.isStageUnlocked(_civ1, 5), isTrue);
        expect(controller.isStageUnlocked(_civ1, 6), isFalse);
        expect(
          container
              .read(progressProvider)
              .highestUnlockedStageIndexPerCivilization[_civ1],
          5,
        );
      },
    );

    test(
      'completing the final stage marks the civilization completed',
      () async {
        final container = _container();
        final controller = container.read(progressProvider.notifier);

        await controller.markStageCompleted(_civ1, stagesPerCivilization);

        expect(container.read(progressProvider).completedCivilizations, {
          _civ1,
        });
        // The final stage itself stays unlocked ("completed" node) but there
        // is no stage 31.
        expect(
          controller.isStageUnlocked(_civ1, stagesPerCivilization),
          isTrue,
        );
        expect(
          controller.isStageUnlocked(_civ1, stagesPerCivilization + 1),
          isFalse,
        );
      },
    );

    test(
      'completing the final stage unlocks the next civilization from stage 1',
      () async {
        final container = _container();
        final controller = container.read(progressProvider.notifier);

        await controller.markStageCompleted(_civ1, stagesPerCivilization);

        expect(controller.isCivilizationUnlocked(_civ2), isTrue);
        expect(controller.isStageUnlocked(_civ2, 1), isTrue);
        expect(controller.isStageUnlocked(_civ2, 2), isFalse);
        // Civilization 3 is still locked.
        expect(controller.isCivilizationUnlocked(_civ3), isFalse);
      },
    );

    test('a full civilization-to-civilization chain accumulates', () async {
      final container = _container();
      final controller = container.read(progressProvider.notifier);

      for (var stage = 1; stage <= stagesPerCivilization; stage++) {
        await controller.markStageCompleted(_civ1, stage);
      }
      await controller.markStageCompleted(_civ2, 1);

      final progress = container.read(progressProvider);
      expect(progress.completedCivilizations, {_civ1});
      expect(controller.isCivilizationUnlocked(_civ2), isTrue);
      expect(controller.isStageUnlocked(_civ2, 2), isTrue);
      expect(controller.isCivilizationUnlocked(_civ3), isFalse);
    });

    test(
      're-completing the final stage does not duplicate the completed mark',
      () async {
        final container = _container();
        final controller = container.read(progressProvider.notifier);

        await controller.markStageCompleted(_civ1, stagesPerCivilization);
        await controller.markStageCompleted(_civ1, stagesPerCivilization);

        expect(container.read(progressProvider).completedCivilizations, {
          _civ1,
        });
      },
    );
  });

  group('ProgressController — Hive persistence (PRD 12)', () {
    test('mutations are written to the box immediately', () async {
      final container = _container();
      final controller = container.read(progressProvider.notifier);

      await controller.markStageCompleted(_civ1, 2);
      await controller.markStageCompleted(_civ1, stagesPerCivilization);

      final stored = _box.get('highestUnlockedStageIndex');
      expect(stored, isA<Map>());
      expect(Map<String, int>.from(stored!)[_civ1], stagesPerCivilization);
      expect(_box.get('completedCivilizations'), [_civ1]);
    });

    test('state survives the controller being rebuilt from the box '
        '(app-restart simulation)', () async {
      final first = _container();
      await first.read(progressProvider.notifier).markStageCompleted(_civ1, 7);
      await first
          .read(progressProvider.notifier)
          .markStageCompleted(_civ1, stagesPerCivilization);
      await first.read(progressProvider.notifier).markStageCompleted(_civ2, 1);

      // A brand-new container reading the same box = an app restart.
      final restarted = _container();
      final controller = restarted.read(progressProvider.notifier);

      final progress = restarted.read(progressProvider);
      expect(progress.highestUnlockedStageIndexPerCivilization, {
        _civ1: stagesPerCivilization,
        _civ2: 2,
      });
      expect(progress.completedCivilizations, {_civ1});
      expect(controller.isCivilizationUnlocked(_civ2), isTrue);
      expect(controller.isStageUnlocked(_civ2, 2), isTrue);
      expect(controller.isStageUnlocked(_civ2, 3), isFalse);
    });
  });
}
