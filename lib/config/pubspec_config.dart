import 'package:yaml/yaml.dart';

class PubspecConfig {
  static const _defaultBaseDirectory = 'model/generated';
  static const _defaultConfigPath = 'model_generator/config.yaml';

  final String projectName;
  final String baseDirectory;
  final String configPath;
  final bool uppercaseEnums;

  const PubspecConfig({
    required this.projectName,
    this.configPath = _defaultConfigPath,
    this.baseDirectory = _defaultBaseDirectory,
    this.uppercaseEnums = true,
  });

  factory PubspecConfig.fromPubspecContent(String pubspecContent) {
    final doc = loadYaml(pubspecContent);
    if (doc is! YamlMap) {
      throw Exception('Could not parse the pubspec.yaml');
    }
    final projectName = doc['name'];

    return PubspecConfig(projectName: projectName);
  }
}
