
import 'package:model_generator/model/field.dart';
import 'package:model_generator/model/model/model.dart';

class ObjectModel extends Model {
  final List<Field> fields;

  ObjectModel({
    required String name,
    required String? path,
    required String? baseDirectory,
    required this.fields,
    List<String>? extraImports,
    List<String>? extraAnnotations,
    String? extendsModel,
    String? description,
  }) : super(
    name: name,
    path: path,
    extendsModel: extendsModel,
    baseDirectory: baseDirectory,
    extraAnnotations: extraAnnotations,
    extraImports: extraImports,
    description: description,
  );
}
