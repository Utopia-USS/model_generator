import 'dart:io';

import 'package:model_generator/config/pubspec_config.dart';
import 'package:model_generator/config/yml_generator_config.dart';
import 'package:model_generator/model/model/object_model.dart';
import 'package:model_generator/writer/object_model_writer.dart';
import 'package:path/path.dart';

void main(List<String> arguments) {
  final pubspecConfig = PubspecConfig(projectName: "model_gene");

  final file = File("assets/openapi.yaml");
  final modelGeneratorContent = file.readAsStringSync();
  final modelGeneratorConfig = YmlGeneratorConfig(pubspecConfig, modelGeneratorContent);
  writeToFiles(pubspecConfig, modelGeneratorConfig);
  generateJsonGeneratedModels();
}

void writeToFiles(PubspecConfig pubspecConfig, YmlGeneratorConfig modelGeneratorConfig) {
  for (final model in modelGeneratorConfig.models) {
    final modelDirectory = Directory(join('lib', model.baseDirectory));
    if (!modelDirectory.existsSync()) {
      modelDirectory.createSync(recursive: true);
    }
    String content = '';
    if (model is ObjectModel) {
      content = ObjectModelWriter(
        pubspecConfig: pubspecConfig,
        jsonModel: model,
        yamlConfig: modelGeneratorConfig,
      ).write();
    }
    File file;
    if (model.path == null) {
      file = File(join('lib', model.baseDirectory, '${model.fileName}.dart'));
    } else {
      file = File(join('lib', model.baseDirectory, model.path, '${model.fileName}.dart'));
    }
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.writeAsStringSync(content);
  }
}

Future<void> generateJsonGeneratedModels() async {
  final result = Process.runSync('flutter', [
    'packages',
    'pub',
    'run',
    'build_runner',
    'build',
    '--delete-conflicting-outputs',
  ]);
  if (result.exitCode == 0) {
    print('Successfully generated freezed files');
    print('');
  } else {
    print('Failed to run flutter packages pub run build_runner build --delete-conflicting-outputs`');
    print('StdErr: ${result.stderr}');
    print('StdOut: ${result.stdout}');
  }
}
