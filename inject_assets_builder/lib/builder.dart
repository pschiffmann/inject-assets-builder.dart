import 'dart:async';

import 'package:build/build.dart';

const substitutionsKey = 'substitutions';
const fileExtensionsKey = 'file_extensions';

/// Factory function used by the builder definition in `build.yaml`.
Builder injectAssetsBuilder(BuilderOptions options) {
  final unrecognizedKeys = options.config.keys.toSet()
    ..remove(substitutionsKey)
    ..remove(fileExtensionsKey);
  if (unrecognizedKeys.isNotEmpty) {
    log.warning('Ignoring unrecognized keys: ${unrecognizedKeys.join(" ")}');
  }

  return InjectAssetsBuilder(_extractSubstitutionsConfig(options),
      _extractFileExtensionsConfig(options));
}

Map<AssetId, AssetId> _extractSubstitutionsConfig(BuilderOptions options) {
  final result = <AssetId, AssetId>{};
  final rawSubstitutions = options.config[substitutionsKey];
  if (rawSubstitutions is Map) {
    rawSubstitutions.forEach((defaultAsset, substitution) {
      result[AssetId.parse(defaultAsset)] = AssetId.parse(substitution);
    });
  }
  return result;
}

Map<String, List<String>> _extractFileExtensionsConfig(BuilderOptions options) {
  final result = <String, List<String>>{};
  if (options.config is List) {
    for (final extension in options.config[fileExtensionsKey]) {
      result['.default$extension'] = [extension];
    }
  }
  return result;
}

///
class InjectAssetsBuilder implements Builder {
  InjectAssetsBuilder(this.substitutions, this.buildExtensions);

  final Map<AssetId, AssetId> substitutions;
  final Map<String, List<String>> buildExtensions;

  Future<dynamic> build(BuildStep buildStep) async {
    final defaultAsset = buildStep.inputId;
    var source = substitutions[defaultAsset];
    if (source == null) {
      log.info('No substitution configured for asset $defaultAsset, '
          'using the default asset');
      source = defaultAsset;
    }
    final target =
        AssetId(defaultAsset.package, _removeDefaultInfix(defaultAsset.path));
    log.info('Copying asset $source to $target');
    return buildStep.writeAsString(
        target, await buildStep.readAsString(source));
  }

  /// Converts a path `foo/bar.default.txt` to `foo/bar.txt`.
  String _removeDefaultInfix(String path) {
    const defaultFileInfix = '.default';
    final index = path.lastIndexOf(defaultFileInfix);
    return path.substring(0, index) +
        path.substring(index + defaultFileInfix.length);
  }
}
