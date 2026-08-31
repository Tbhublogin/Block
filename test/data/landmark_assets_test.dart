/// Asset-bundle tests for BUILD_PROMPTS 3.2: every landmark image path
/// declared in the catalog must exist as a real bundled asset, so a
/// missing/misspelled file fails here instead of rendering an empty box in
/// the museum at runtime (Flutter's asset manifest is available under
/// `flutter test`, including directory-registered assets).
library;

import 'package:block_civilizations/core/constants/asset_paths.dart';
import 'package:block_civilizations/data/datasources/civilizations_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('landmark image assets (prompt 3.2)', () {
    test('asset_paths constants follow the PRD 10 path convention', () {
      expect(
        hangingGardensAsset,
        'assets/civilizations/iraq/hanging_gardens.png',
      );
      expect(zigguratOfUrAsset, 'assets/civilizations/iraq/ziggurat_of_ur.png');
      expect(towerOfBabelAsset, 'assets/civilizations/iraq/tower_of_babel.png');
      expect(
        hammurabiSteleAsset,
        'assets/civilizations/iraq/hammurabi_stele.png',
      );
      expect(ishtarGateAsset, 'assets/civilizations/iraq/ishtar_gate.png');
      expect(lamassuAsset, 'assets/civilizations/iraq/lamassu.png');
      expect(
        goldenLyreOfUrAsset,
        'assets/civilizations/iraq/golden_lyre_of_ur.png',
      );
      expect(
        naramSinSteleAsset,
        'assets/civilizations/iraq/naram_sin_stele.png',
      );
      expect(
        cuneiformTabletAsset,
        'assets/civilizations/iraq/cuneiform_tablet.png',
      );
      expect(
        lionOfBabylonAsset,
        'assets/civilizations/iraq/lion_of_babylon.png',
      );
    });

    test('every catalog landmark resolves to a bundled asset', () async {
      expect(landmarkCatalog, isNotEmpty);
      for (final landmark in landmarkCatalog) {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        expect(
          manifest.getAssetVariants(landmark.imageAsset),
          isNotEmpty,
          reason:
              '${landmark.id}: ${landmark.imageAsset} is declared in '
              'civilizations_data.dart but missing from the asset bundle '
              '(pubspec registration or file missing).',
        );
      }
    });

    test('declared landmark PNGs load and decode as valid images', () async {
      for (final path in [
        hangingGardensAsset,
        zigguratOfUrAsset,
        towerOfBabelAsset,
        hammurabiSteleAsset,
        ishtarGateAsset,
        lamassuAsset,
        goldenLyreOfUrAsset,
        naramSinSteleAsset,
        cuneiformTabletAsset,
        lionOfBabylonAsset,
      ]) {
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(0), reason: '$path is empty.');
        // PNG magic number: every declared landmark file really is a PNG,
        // not a renamed JPEG or other format (the Pictures/ folder did
        // contain such mislabeled files).
        expect(
          data.getUint8(0),
          0x89,
          reason: '$path does not start with the PNG signature.',
        );
        expect(
          data.getUint8(1),
          0x50,
          reason: '$path does not start with the PNG signature.',
        );
      }
    });
  });
}
