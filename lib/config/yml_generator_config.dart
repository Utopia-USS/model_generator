import 'package:model_generator/config/pubspec_config.dart';
import 'package:model_generator/model/field.dart';
import 'package:model_generator/model/item_type/array_type.dart';
import 'package:model_generator/model/item_type/boolean_type.dart';
import 'package:model_generator/model/item_type/date_time_type.dart';
import 'package:model_generator/model/item_type/double_type.dart';
import 'package:model_generator/model/item_type/dynamic_type.dart';
import 'package:model_generator/model/item_type/integer_type.dart';
import 'package:model_generator/model/item_type/item_type.dart';
import 'package:model_generator/model/item_type/map_type.dart';
import 'package:model_generator/model/item_type/object_type.dart';
import 'package:model_generator/model/item_type/string_type.dart';
import 'package:model_generator/model/model/model.dart';
import 'package:model_generator/model/model/object_model.dart';
import 'package:model_generator/util/case_util.dart';
import 'package:model_generator/util/generic_type.dart';
import 'package:model_generator/util/list_extensions.dart';
import 'package:model_generator/util/type_checker.dart';
import 'package:yaml/yaml.dart';

class YmlGeneratorConfig {
  final _models = <Model>[];

  List<Model> get models => _models;

  YmlGeneratorConfig(PubspecConfig pubspecConfig, String configContent) {
    loadYaml(configContent).forEach((key, value) {
      final String baseDirectory = value['base_directory'] ?? pubspecConfig.baseDirectory;
      final extraImports = value.containsKey('extra_imports') ? <String>[] : null;

      final description = value['description']?.toString();
      final dynamic properties = value['properties'];
      final String? type = value['type'];
      final YamlList? requiredFields = value['required'];
      if (properties == null && type != "array") {
        throw Exception('Properties can not be null. model: $key');
      }
      if (type == 'enum' || properties == null && type == "array") {
      } else {
        final fields = <Field>[];
        properties.forEach((propertyKey, propertyValue) {
          if (propertyValue is! YamlMap) {
            throw Exception('$propertyKey should be an object');
          }
          fields.add(getField(propertyKey, propertyValue, isRequired: requiredFields?.contains(propertyKey) ?? false));
        });
        models.add(ObjectModel(
          name: key,
          path: CaseUtil(key).snakeCase,
          baseDirectory: baseDirectory,
          fields: fields,
          extraImports: extraImports,
          description: description,
        ));
      }
    });

    checkIfTypesAvailable();
  }

  Field getField(String name, YamlMap property, {bool isRequired = false}) {
    try {
      final required = isRequired || property.containsKey('required') && property['required'] == true;
      final description = property.containsKey('description') ? property['description']!.toString() : null;
      final type = property['type'];
      var defaultValue = property['default_value']?.toString();
      ItemType itemType;

      if (type == null) {
        throw Exception('$name has no defined type');
      }
      if (type == 'object' || type == 'dynamic' || type == 'any') {
        if (property["\$ref"] != null) {
          itemType = ObjectType(getModelFromRef(property["\$ref"]));
        } else {
          itemType = DynamicType();
        }
      } else if (type == 'bool' || type == 'boolean') {
        itemType = BooleanType();
      } else if (type == 'string' || type == 'String') {
        itemType = StringType();
      } else if (type == 'date' || type == 'datetime') {
        itemType = DateTimeType();
      } else if (type == 'double' || type == 'number') {
        itemType = DoubleType();
      } else if (type == 'int' || type == 'integer') {
        itemType = IntegerType();
      } else if (type == 'array') {
        final items = property['items'];
        final arrayType = items['type'];
        itemType = ArrayType(_makeGenericName(arrayType));
      } else if (type == 'map') {
        final items = property['items'];
        final keyType = items['key'];
        final valueType = items['value'];
        itemType = MapType(
          key: _makeGenericName(keyType),
          valueName: _makeGenericName(valueType),
        );
      } else {
        itemType = ObjectType(type);
      }
      return Field(
        name: name,
        type: itemType,
        isRequired: required,
        description: description,
        defaultValue: defaultValue,
      );
    } catch (e) {
      print('Something went wrong with $name:\n\n${e.toString()}');
      rethrow;
    }
  }

  String _makeGenericName(String typeName) {
    if (typeName == 'string' || typeName == 'String') {
      return 'String';
    } else if (typeName == 'bool' || typeName == 'boolean') {
      return 'bool';
    } else if (typeName == 'double') {
      return 'double';
    } else if (typeName == 'date' || typeName == 'datetime') {
      return 'DateTime';
    } else if (typeName == 'int' || typeName == 'integer') {
      return 'int';
    } else if (typeName == 'object' || typeName == 'dynamic' || typeName == 'any') {
      return 'dynamic';
    } else {
      return typeName;
    }
  }

  Iterable<String> getPathsForName(PubspecConfig pubspecConfig, String name) {
    if (TypeChecker.isKnownDartType(name)) return [];

    final foundModel = models.firstWhereOrNull((model) => model.name == name);
    if (foundModel == null) {
      //Maybe a generic
      final dartType = DartType(name);
      if (dartType.generics.isEmpty) {
        throw Exception('getPathForName is null: because `$name` was not added to the config file');
      }
      final paths = <String>{};
      for (final element in dartType.generics) {
        paths.addAll(getPathsForName(pubspecConfig, element.toString()));
      }
      return paths;
    } else {
      final baseDirectory = foundModel.baseDirectory ?? pubspecConfig.baseDirectory;
      final path = foundModel.path;
      if (path == null) {
        return [baseDirectory];
      } else if (path.startsWith('package:')) {
        return [path];
      } else {
        return ['$baseDirectory/$path'];
      }
    }
  }

  void checkIfTypesAvailable() {
    final names = <String>{};
    final types = <String>{};
    final extendsModels = <String>{};
    for (final model in models) {
      names.add(model.name);
      if (model.extendsModel != null) {
        extendsModels.add(model.extendsModel!);
      }
      if (model is ObjectModel) {
        for (final field in model.fields) {
          final type = field.type;
          types.add(type.name);
          if (type is MapType) {
            types.add(type.valueName);
          }
        }
      }
    }

    print('Registered models:');
    print(names);
    print('=======');
    print('Models used as a field in another model:');
    print(types);
    if (extendsModels.isNotEmpty) {
      print('=======');
      print('Models being extended:');
      print(extendsModels);
    }
    for (final type in types) {
      DartType(type).checkTypesKnown(names);
    }
    for (final extendsType in extendsModels) {
      checkTypesKnown(names, extendsType);
    }
  }

  String getModelFromRef(dynamic ref) {
    return ref.toString().split("/").last;
  }

  Model? getModelByName(ItemType itemType) {
    if (itemType is! ObjectType) return null;
    final model = models.firstWhereOrNull((model) => model.name == itemType.name);
    if (model == null) {
      throw Exception('getModelByname is null: because `${itemType.name}` was not added to the config file');
    }
    return model;
  }

  void checkTypesKnown(final Set<String> names, String type) {
    if (!TypeChecker.isKnownDartType(type) && !names.contains(type)) {
      throw Exception(
          'Could not generate all models. `$type` is not added to the config file, but is extended. These types are known: ${names.join(',')}');
    }
  }
}
