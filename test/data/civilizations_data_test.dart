/// Unit tests for the static civilization catalog (BUILD_PROMPTS 3.1):
/// stage-count/curve invariants and landmark-integrity rules that the UI
/// and controllers rely on (PRD 5.3/6/10/11).
library;

import 'package:block_civilizations/core/constants/game_constants.dart';
import 'package:block_civilizations/data/datasources/civilizations_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('civilizationsCatalog', () {
    test('contains civilization #1 (iraq) as the first entry', () {
      expect(civilizationsCatalog, isNotEmpty);
      expect(firstCatalogCivilization.id, 'iraq');
    });

    test('civilization ids are unique', () {
      final ids = civilizationsCatalog.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('iraq', () {
    test(
      'has no emblem asset (hand-drawn CustomPainter emblem, PRD 10/11)',
      () {
        expect(iraq.emblemAsset, isNull);
      },
    );

    test('has exactly $stagesPerCivilization stages in order 1..30', () {
      expect(iraq.stages.length, stagesPerCivilization);
      for (var i = 0; i < iraq.stages.length; i++) {
        expect(iraq.stages[i].orderIndex, i + 1);
      }
    });

    test('stage ids are iraq_01..iraq_30 (zero-padded)', () {
      for (var i = 0; i < iraq.stages.length; i++) {
        expect(iraq.stages[i].id, 'iraq_${(i + 1).toString().padLeft(2, '0')}');
      }
    });

    test('target scores follow the approved linear curve '
        '(orderIndex * 1000, user-approved 2026-08-30)', () {
      for (final stage in iraq.stages) {
        expect(stage.targetScore, stage.orderIndex * 1000);
      }
      expect(iraq.stages.first.targetScore, 1000);
      expect(iraq.stages.last.targetScore, 30000);
    });
  });

  group('landmarkCatalog', () {
    test('contains the 10 finalized Iraq landmarks in roster order', () {
      expect(landmarkCatalog.length, 10);
      expect(landmarkCatalog.map((l) => l.id).toList(), [
        'hanging_gardens',
        'ziggurat_of_ur',
        'tower_of_babel',
        'hammurabi_stele',
        'ishtar_gate',
        'lamassu',
        'golden_lyre_of_ur',
        'naram_sin_stele',
        'cuneiform_tablet',
        'lion_of_babylon',
      ]);
    });

    test('landmark ids are unique', () {
      final ids = landmarkCatalog.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every landmark references an existing catalog civilization', () {
      final civIds = civilizationsCatalog.map((c) => c.id).toSet();
      for (final landmark in landmarkCatalog) {
        expect(civIds, contains(landmark.civilizationId));
      }
    });

    test('every landmark image points at assets/civilizations/<civId>/'
        '<landmarkId>.png (PRD 10 path convention)', () {
      for (final landmark in landmarkCatalog) {
        expect(
          landmark.imageAsset,
          'assets/civilizations/${landmark.civilizationId}/${landmark.id}.png',
        );
      }
    });

    test('every landmark has non-empty name/fact localization keys', () {
      for (final landmark in landmarkCatalog) {
        expect(landmark.nameKey, isNotEmpty);
        expect(landmark.historicalFactKey, isNotEmpty);
      }
    });
  });
}
