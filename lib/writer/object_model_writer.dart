import 'package:model_generator/config/pubspec_config.dart';
import 'package:model_generator/config/yml_generator_config.dart';
import 'package:model_generator/model/field.dart';
import 'package:model_generator/model/item_type/array_type.dart';
import 'package:model_generator/model/item_type/map_type.dart';
import 'package:model_generator/model/model/object_model.dart';
import 'package:model_generator/util/case_util.dart';
import 'package:model_generator/util/generic_type.dart';
import 'package:model_generator/util/type_checker.dart';

class ObjectModelWriter {
  final PubspecConfig pubspecConfig;
  final ObjectModel jsonModel;
  final YmlGeneratorConfig yamlConfig;

  ObjectModelWriter({
    required this.pubspecConfig,
    required this.jsonModel,
    required this.yamlConfig,
  });

  String write() {
    final sb = StringBuffer();
    final imports = <String>{}..add("import 'package:freezed_annotation/freezed_annotation.dart';");

    jsonModel.extraImports?.forEach((element) => imports.add('import \'$element\';'));

    for (final field in jsonModel.fields) {
      final type = field.type;
      if (!TypeChecker.isKnownDartType(type.name) && type.name != jsonModel.name) {
        imports.addAll(_getImportsFromPath(type.name));
      }
      if (type is MapType && !TypeChecker.isKnownDartType(type.valueName)) {
        imports.addAll(_getImportsFromPath(type.valueName));
      }
    }

    (imports.toList()..sort((i1, i2) => i1.compareTo(i2))).forEach(sb.writeln);

    sb
      ..writeln()
      ..writeln("part '${jsonModel.fileName}.g.dart';")
      ..writeln()
      ..writeln("part '${jsonModel.fileName}.freezed.dart';")
      ..writeln();

    final modelDescription = jsonModel.description?.trim();
    if (modelDescription != null && modelDescription.isNotEmpty) {
      sb.writeln("///$modelDescription");
    }

    sb.writeln('@freezed');

    sb.writeln('class ${jsonModel.name} with _\$${jsonModel.name} {');

    jsonModel.fields.sort((a, b) {
      final b1 = a.isRequired ? 1 : 0;
      final b2 = b.isRequired ? 1 : 0;
      return b2 - b1;
    });

    sb.writeln('  factory ${jsonModel.name}({');

    for (final key in jsonModel.fields.where((key) => (key.isRequired && !key.hasDefaultValue))) {
      sb.writeln('    required ${_getKeyType(key)} ${key.name},');
    }
    for (final key in jsonModel.fields.where((key) => !(key.isRequired && !key.hasDefaultValue))) {
      sb.writeln('    ${_getKeyType(key)} ${key.name}${_fillDefaultValue(key)},');
    }
    sb.writeln("  }) = _${jsonModel.name};");

    sb
      ..writeln()
      ..writeln(
        '  factory ${jsonModel.name}.fromJson(Map<String, dynamic> json) => _\$${jsonModel.name}FromJson(json);',
      )
      ..writeln("}");

    return sb.toString().replaceAll("\n", '\r\n');
  }

  Iterable<String> _getImportsFromPath(String name) {
    final imports = <String>{};
    for (final leaf in DartType(name).leaves) {
      final projectName = pubspecConfig.projectName;
      final reCaseFieldName = CaseUtil(leaf);
      final paths = yamlConfig.getPathsForName(pubspecConfig, leaf);
      for (final path in paths) {
        String pathWithPackage;
        if (path.startsWith('package:')) {
          pathWithPackage = path;
        } else {
          pathWithPackage = 'package:$projectName/$path';
        }

        if (path.endsWith('.dart')) {
          imports.add("import '$pathWithPackage';");
        } else {
          imports.add("import '$pathWithPackage/${reCaseFieldName.snakeCase}.dart';");
        }
      }
    }
    return imports.toList()..sort((i1, i2) => i1.compareTo(i2));
  }

  String _getKeyType(Field key) {
    final nullableFlag = key.isRequired || key.type.name == 'dynamic' ? '' : '?';
    final keyType = key.type;
    if (keyType is ArrayType) {
      return 'List<${keyType.name}>$nullableFlag';
    } else if (keyType is MapType) {
      return 'Map<${keyType.name}, ${keyType.valueName}>$nullableFlag';
    } else {
      return '${keyType.name}$nullableFlag';
    }
  }

  String _fillDefaultValue(Field key) {
    if (key.hasDefaultValue) {
      return ' = ${key.defaultValue}';
    } else {
      return '';
    }
  }
}
