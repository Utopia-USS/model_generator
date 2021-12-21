class PubspecConfig {
  static const _defaultBaseDirectory = 'model/generated';

  final String projectName;
  final String baseDirectory;
  final bool uppercaseEnums;

  const PubspecConfig({
    required this.projectName,
    this.baseDirectory = _defaultBaseDirectory,
    this.uppercaseEnums = true,
  });
}
