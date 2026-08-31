/// Static content source: 8 civilizations, their stages, landmarks, and
/// historical facts (ar/en) — PRD 10.
///
/// Currently contains civilization #1 (Iraq / Mesopotamia), populated from
/// the user-provided finalized content (names + facts, 2026-08-30 — see
/// PROJECT_STATE.md §5.1); civilizations 2–8 are post-launch content
/// (PROJECT_STATE.md §5) and join this catalog as their content is provided.
///
/// Target-score curve (user-approved 2026-08-30): linear,
/// `targetScore = orderIndex * 1000` → 1000..30000 across the 30 stages.
///
/// Landmark image assets point at `assets/civilizations/iraq/<landmarkId>.png`
/// (PRD 10 path convention), via the [iraqLandmarkDir]-based constants in
/// `core/constants/asset_paths.dart`; the PNG files themselves are the
/// user-provided finalized artwork, copied verbatim in BUILD_PROMPTS 3.2.
///
/// Facts are NOT authored here — they live in the ARB files behind the
/// nameKey/historicalFactKey localization keys (AI_RULES #25: never invent
/// historical facts; the English strings are translations of the provided
/// Arabic in `app_ar.arb`, the template).
library;

import 'package:block_civilizations/core/constants/asset_paths.dart';
import 'package:block_civilizations/domain/models/civilization.dart';
import 'package:block_civilizations/domain/models/landmark_info.dart';
import 'package:block_civilizations/domain/models/stage.dart';

/// The full civilization catalog in map/unlock order (PRD 6: the map shows
/// the civilizations in sequence; civilization #1 is unlocked from the
/// start — see `progress_controller.dart`).
const List<Civilization> civilizationsCatalog = [iraq];

/// Convenience handle for the first (currently only) catalog entry, until
/// civilizations 2–8 join (PROJECT_STATE.md §5).
const Civilization firstCatalogCivilization = iraq;

/// Civilization #1: Iraq / Mesopotamia. The emblem has no source image and
/// is hand-drawn via CustomPainter on the map screen (`emblemAsset` null by
/// design, PRD 10/11); the theme color is the gold of the existing
/// app-wide gold/blue palette (see PROJECT_STATE.md's emblem decision).
const Civilization iraq = Civilization(
  id: 'iraq',
  nameKey: 'civIraqName',
  emblemAsset: null,
  themeColorHex: '#C9A227',
  stages: _iraqStages,
);

/// Iraq's 30 sub-stages: ids `iraq_01`..`iraq_30` (orderIndex 1..30,
/// PRD 5.3), linear target-score curve per the file header.
const List<Stage> _iraqStages = [
  Stage(id: 'iraq_01', orderIndex: 1, targetScore: 1000),
  Stage(id: 'iraq_02', orderIndex: 2, targetScore: 2000),
  Stage(id: 'iraq_03', orderIndex: 3, targetScore: 3000),
  Stage(id: 'iraq_04', orderIndex: 4, targetScore: 4000),
  Stage(id: 'iraq_05', orderIndex: 5, targetScore: 5000),
  Stage(id: 'iraq_06', orderIndex: 6, targetScore: 6000),
  Stage(id: 'iraq_07', orderIndex: 7, targetScore: 7000),
  Stage(id: 'iraq_08', orderIndex: 8, targetScore: 8000),
  Stage(id: 'iraq_09', orderIndex: 9, targetScore: 9000),
  Stage(id: 'iraq_10', orderIndex: 10, targetScore: 10000),
  Stage(id: 'iraq_11', orderIndex: 11, targetScore: 11000),
  Stage(id: 'iraq_12', orderIndex: 12, targetScore: 12000),
  Stage(id: 'iraq_13', orderIndex: 13, targetScore: 13000),
  Stage(id: 'iraq_14', orderIndex: 14, targetScore: 14000),
  Stage(id: 'iraq_15', orderIndex: 15, targetScore: 15000),
  Stage(id: 'iraq_16', orderIndex: 16, targetScore: 16000),
  Stage(id: 'iraq_17', orderIndex: 17, targetScore: 17000),
  Stage(id: 'iraq_18', orderIndex: 18, targetScore: 18000),
  Stage(id: 'iraq_19', orderIndex: 19, targetScore: 19000),
  Stage(id: 'iraq_20', orderIndex: 20, targetScore: 20000),
  Stage(id: 'iraq_21', orderIndex: 21, targetScore: 21000),
  Stage(id: 'iraq_22', orderIndex: 22, targetScore: 22000),
  Stage(id: 'iraq_23', orderIndex: 23, targetScore: 23000),
  Stage(id: 'iraq_24', orderIndex: 24, targetScore: 24000),
  Stage(id: 'iraq_25', orderIndex: 25, targetScore: 25000),
  Stage(id: 'iraq_26', orderIndex: 26, targetScore: 26000),
  Stage(id: 'iraq_27', orderIndex: 27, targetScore: 27000),
  Stage(id: 'iraq_28', orderIndex: 28, targetScore: 28000),
  Stage(id: 'iraq_29', orderIndex: 29, targetScore: 29000),
  Stage(id: 'iraq_30', orderIndex: 30, targetScore: 30000),
];

/// All landmark entries for every catalog civilization, keyed lookup order =
/// roster order (PROJECT_STATE.md §5.1). The museum resolves a piece's
/// `landmarkId` against this list (PRD 10).
const List<LandmarkInfo> landmarkCatalog = _iraqLandmarks;

/// Iraq / Mesopotamia's 10 landmarks (names + facts finalized 2026-08-30).
/// Image files live in `assets/civilizations/iraq/` (prompt 3.2).
const List<LandmarkInfo> _iraqLandmarks = [
  LandmarkInfo(
    id: 'hanging_gardens',
    civilizationId: 'iraq',
    nameKey: 'landmarkHangingGardensName',
    historicalFactKey: 'landmarkHangingGardensFact',
    imageAsset: hangingGardensAsset,
  ),
  LandmarkInfo(
    id: 'ziggurat_of_ur',
    civilizationId: 'iraq',
    nameKey: 'landmarkZigguratOfUrName',
    historicalFactKey: 'landmarkZigguratOfUrFact',
    imageAsset: zigguratOfUrAsset,
  ),
  LandmarkInfo(
    id: 'tower_of_babel',
    civilizationId: 'iraq',
    nameKey: 'landmarkTowerOfBabelName',
    historicalFactKey: 'landmarkTowerOfBabelFact',
    imageAsset: towerOfBabelAsset,
  ),
  LandmarkInfo(
    id: 'hammurabi_stele',
    civilizationId: 'iraq',
    nameKey: 'landmarkHammurabiSteleName',
    historicalFactKey: 'landmarkHammurabiSteleFact',
    imageAsset: hammurabiSteleAsset,
  ),
  LandmarkInfo(
    id: 'ishtar_gate',
    civilizationId: 'iraq',
    nameKey: 'landmarkIshtarGateName',
    historicalFactKey: 'landmarkIshtarGateFact',
    imageAsset: ishtarGateAsset,
  ),
  LandmarkInfo(
    id: 'lamassu',
    civilizationId: 'iraq',
    nameKey: 'landmarkLamassuName',
    historicalFactKey: 'landmarkLamassuFact',
    imageAsset: lamassuAsset,
  ),
  LandmarkInfo(
    id: 'golden_lyre_of_ur',
    civilizationId: 'iraq',
    nameKey: 'landmarkGoldenLyreOfUrName',
    historicalFactKey: 'landmarkGoldenLyreOfUrFact',
    imageAsset: goldenLyreOfUrAsset,
  ),
  LandmarkInfo(
    id: 'naram_sin_stele',
    civilizationId: 'iraq',
    nameKey: 'landmarkNaramSinSteleName',
    historicalFactKey: 'landmarkNaramSinSteleFact',
    imageAsset: naramSinSteleAsset,
  ),
  LandmarkInfo(
    id: 'cuneiform_tablet',
    civilizationId: 'iraq',
    nameKey: 'landmarkCuneiformTabletName',
    historicalFactKey: 'landmarkCuneiformTabletFact',
    imageAsset: cuneiformTabletAsset,
  ),
  LandmarkInfo(
    id: 'lion_of_babylon',
    civilizationId: 'iraq',
    nameKey: 'landmarkLionOfBabylonName',
    historicalFactKey: 'landmarkLionOfBabylonFact',
    imageAsset: lionOfBabylonAsset,
  ),
];
