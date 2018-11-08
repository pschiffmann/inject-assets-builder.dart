import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:inject_assets_builder/builder.dart';
import 'package:test/test.dart';

const defaultAssetId = 'dep|lib/_variables.default.txt';
const defaultAssetContents = 'default content from `dep`';
const overrideAssetId = 'app|lib/_variables.txt';
const overrideAssetContents = 'overridden content from `app`';

const sourceAssets = {
  defaultAssetId: defaultAssetContents,
  overrideAssetId: overrideAssetContents
};

const generatedAssetId = 'dep|lib/_variables.txt';

const buildExtensions = {
  '.default.txt': ['.txt']
};

void main() {
  group('InjectAssetsBuilder', () {
    test('copies the `.default` file if no override is configured', () async {
      await testBuilder(
          InjectAssetsBuilder(
              assetOverrides: {}, buildExtensions: buildExtensions),
          sourceAssets,
          outputs: {generatedAssetId: defaultAssetContents});
    });

    test('copies the override file if one is configured', () async {
      await testBuilder(
          InjectAssetsBuilder(assetOverrides: {
            AssetId.parse(defaultAssetId): AssetId.parse(overrideAssetId)
          }, buildExtensions: buildExtensions),
          sourceAssets,
          outputs: {generatedAssetId: overrideAssetContents});
    });
  });
}
