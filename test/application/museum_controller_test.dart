/// Unit tests for the museum controller (Phase 2, BUILD_PROMPTS 2.2):
/// landmark unlocking, idempotence, and Hive persistence across controller
/// recreation (PRD 6, PRD 11's unlockedLandmarkIds).
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

import 'package:block_civilizations/application/museum_controller.dart';

late Directory _tempDir;
late Box<List> _box;

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [museumBoxProvider.overrideWithValue(_box)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() async {
    _tempDir = await Directory.systemTemp.createTemp('museum_test');
    Hive.init(_tempDir.path);
    _box = await Hive.openBox<List>(museumBoxName);
  });

  tearDown(() async {
    await _box.deleteFromDisk();
    await _tempDir.delete(recursive: true);
    Hive.resetAdapters();
  });

  group('MuseumController — fresh install', () {
    test('starts with an empty collection', () {
      final container = _container();

      expect(container.read(museumProvider).unlockedLandmarkIds, isEmpty);
      expect(container.read(museumProvider), const MuseumState.initial());
    });
  });

  group('MuseumController — unlockLandmark', () {
    test(
      'a new landmark is added to the collection and reported as new',
      () async {
        final container = _container();
        final controller = container.read(museumProvider.notifier);

        expect(await controller.unlockLandmark('ziggurat_of_ur'), isTrue);

        expect(container.read(museumProvider).unlockedLandmarkIds, {
          'ziggurat_of_ur',
        });
      },
    );

    test('unlocking a second landmark keeps the first', () async {
      final container = _container();
      final controller = container.read(museumProvider.notifier);

      await controller.unlockLandmark('ziggurat_of_ur');
      await controller.unlockLandmark('ishtar_gate');

      expect(container.read(museumProvider).unlockedLandmarkIds, {
        'ziggurat_of_ur',
        'ishtar_gate',
      });
    });

    test('is idempotent: re-unlocking a known landmark is a no-op', () async {
      final container = _container();
      final controller = container.read(museumProvider.notifier);

      expect(await controller.unlockLandmark('ziggurat_of_ur'), isTrue);
      expect(await controller.unlockLandmark('ziggurat_of_ur'), isFalse);

      expect(container.read(museumProvider).unlockedLandmarkIds, {
        'ziggurat_of_ur',
      });
    });
  });

  group('MuseumController — Hive persistence (PRD 12)', () {
    test('unlocks are written to the box immediately', () async {
      final container = _container();
      final controller = container.read(museumProvider.notifier);

      await controller.unlockLandmark('ziggurat_of_ur');
      await controller.unlockLandmark('ishtar_gate');

      expect(_box.get('unlockedLandmarkIds'), [
        'ziggurat_of_ur',
        'ishtar_gate',
      ]);
    });

    test('collection survives the controller being rebuilt from the box '
        '(app-restart simulation)', () async {
      final first = _container();
      await first
          .read(museumProvider.notifier)
          .unlockLandmark('ziggurat_of_ur');
      await first.read(museumProvider.notifier).unlockLandmark('ishtar_gate');

      // A brand-new container reading the same box = an app restart.
      final restarted = _container();

      expect(restarted.read(museumProvider).unlockedLandmarkIds, {
        'ziggurat_of_ur',
        'ishtar_gate',
      });
    });
  });
}
