/// Central registry of asset file paths (emblems, landmark artwork).
///
/// Values mirror PRD 10's path convention
/// `assets/civilizations/<civilizationId>/<landmarkId>.png`; the underlying
/// PNG files are the user-provided finalized artwork, copied verbatim
/// (BUILD_PROMPTS 3.2). Referenced by `civilizations_data.dart`'s
/// `imageAsset` values; the folders are registered in `pubspec.yaml`.
library;

const String _iraqLandmarkDir = 'assets/civilizations/iraq';

/// Iraq / Mesopotamia landmark artwork (civilization #1), roster order
/// matching `landmarkCatalog` in `civilizations_data.dart`.
const String hangingGardensAsset = '$_iraqLandmarkDir/hanging_gardens.png';
const String zigguratOfUrAsset = '$_iraqLandmarkDir/ziggurat_of_ur.png';
const String towerOfBabelAsset = '$_iraqLandmarkDir/tower_of_babel.png';
const String hammurabiSteleAsset = '$_iraqLandmarkDir/hammurabi_stele.png';
const String ishtarGateAsset = '$_iraqLandmarkDir/ishtar_gate.png';
const String lamassuAsset = '$_iraqLandmarkDir/lamassu.png';
const String goldenLyreOfUrAsset = '$_iraqLandmarkDir/golden_lyre_of_ur.png';
const String naramSinSteleAsset = '$_iraqLandmarkDir/naram_sin_stele.png';
const String cuneiformTabletAsset = '$_iraqLandmarkDir/cuneiform_tablet.png';
const String lionOfBabylonAsset = '$_iraqLandmarkDir/lion_of_babylon.png';
