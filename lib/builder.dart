import 'dart:async';

import 'package:build/build.dart';
import 'package:meta/meta.dart';

const assetOverridesKey = 'asset_overrides';
const fileExtensionsKey = 'file_extensions';

const defaultInfix = '.default';

/// [BuilderFactory] used by the builder definition in `build.yaml`.
Builder injectAssetsBuilder(BuilderOptions options) {
  final unrecognizedKeys = options.config.keys.toSet()
    ..remove(assetOverridesKey)
    ..remove(fileExtensionsKey);
  if (unrecognizedKeys.isNotEmpty) {
    log.warning(
        'Ignoring unrecognized options: ${unrecognizedKeys.join(", ")}');
  }

  final buildExtensions = _extractFileExtensionsConfig(options);
  return InjectAssetsBuilder(
      assetOverrides:
          _extractAssetOverridesConfig(options, buildExtensions.keys),
      buildExtensions: buildExtensions);
}

Map<AssetId, AssetId> _extractAssetOverridesConfig(
    BuilderOptions options, Iterable<String> defaultFileExtensions) {
  final expectedFileEndings =
      RegExp('(${defaultFileExtensions.map(RegExp.escape).join("|")})\$');

  final result = <AssetId, AssetId>{};
  final rawAssetOverrides = options.config[assetOverridesKey];

  if (rawAssetOverrides is Map) {
    rawAssetOverrides.forEach((defaultAsset, overrideName) {
      if (!expectedFileEndings.hasMatch(defaultAsset)) {
        log.warning("This builder doesn't run on $defaultAsset");
      }
      result[AssetId.parse(defaultAsset)] = AssetId.parse(overrideName);
    });
  } else if (rawAssetOverrides != null) {
    log.warning('`$assetOverridesKey` must be Map<String, String>, '
        'but got ${rawAssetOverrides.runtimeType}');
  }
  return result;
}

Map<String, List<String>> _extractFileExtensionsConfig(BuilderOptions options) {
  final result = <String, List<String>>{};
  final rawFileExtensions = options.config[fileExtensionsKey];

  if (rawFileExtensions is List) {
    for (final extension in rawFileExtensions) {
      result['$defaultInfix$extension'] = [extension.toString()];
    }
  } else if (rawFileExtensions == null) {
    log.warning('No `$fileExtensionsKey` configured. '
        'This completely disables the builder!');
  } else {
    log.warning('`$fileExtensionsKey` must be a List<String>, '
        'but got ${rawFileExtensions.runtimeType}');
  }
  return result;
}

class InjectAssetsBuilder implements Builder {
  InjectAssetsBuilder(
      {@required this.assetOverrides, @required this.buildExtensions});

  final Map<AssetId, AssetId> assetOverrides;

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    final defaultAsset = buildStep.inputId;
    var source = assetOverrides[defaultAsset];
    if (source == null) {
      log.info('No substitution configured for asset $defaultAsset, '
          'using the default asset');
      source = defaultAsset;
    }
    final target =
        AssetId(defaultAsset.package, _removeDefaultInfix(defaultAsset.path));
    log.fine('Copying asset $source to $target');
    return buildStep.writeAsString(
        target, await buildStep.readAsString(source));
  }

  /// Converts a path `foo/bar.default.txt` to `foo/bar.txt`.
  String _removeDefaultInfix(String path) {
    final index = path.lastIndexOf(defaultInfix);
    return path.substring(0, index) +
        path.substring(index + defaultInfix.length);
  }
}
