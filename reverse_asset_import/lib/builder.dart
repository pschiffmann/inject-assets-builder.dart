import 'dart:async';

import 'package:build/build.dart';

const substitutionsKey = 'substitutions';
const fileExtensionsKey = 'file_extensions';

/// Factory function used by the builder definition in `build.yaml`.
Builder createFinalAssetsBuilder(BuilderOptions options) {
  final unrecognizedKeys = options.config.keys.toSet()
    ..remove(substitutionsKey)
    ..remove(fileExtensionsKey);
  if (unrecognizedKeys.isNotEmpty) {
    log.warning('Ignoring unrecognized keys: ${unrecognizedKeys.join(" ")}');
  }

  return CreateFinalAssetsBuilder(_extractSubstitutionsConfig(options),
      _extractFileExtensionsConfig(options));
}

Map<AssetId, AssetId> _extractSubstitutionsConfig(BuilderOptions options) {
  final result = <AssetId, AssetId>{};
  (options.config[substitutionsKey] as Map)
      .forEach((defaultAsset, substitution) {
    result[AssetId.parse(defaultAsset)] = AssetId.parse(substitution);
  });
  return result;
}

Map<String, List<String>> _extractFileExtensionsConfig(BuilderOptions options) {
  final result = <String, List<String>>{};
  for (final extension in options.config[fileExtensionsKey]) {
    result['.default$extension'] = [extension];
  }
  return result;
}

///
class CreateFinalAssetsBuilder implements Builder {
  CreateFinalAssetsBuilder(this.substitutions, this.buildExtensions);

  final Map<AssetId, AssetId> substitutions;
  final Map<String, List<String>> buildExtensions;

  FutureOr<void> build(BuildStep buildStep) async {
    final defaultFile = buildStep.inputId;
    var source = substitutions[defaultFile];
    if (source == null) {
      log.info('No substitution configured for asset ${buildStep.inputId}, '
          'using the default asset');
      source = defaultFile;
    }
    final content = await buildStep.readAsString(source);
    final output = defaultFile
        .changeExtension(buildExtensions[defaultFile.extension].single);
    return buildStep.writeAsString(output, content);
  }
}
