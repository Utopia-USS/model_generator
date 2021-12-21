import 'package:model_generator/model/item_type/item_type.dart';
import 'package:model_generator/util/case_util.dart';
import 'package:model_generator/util/keyword_helper.dart';

class Field {
  final String name;
  final ItemType type;
  final bool isRequired;
  final String? description;
  final String? defaultValue;

  bool get hasDefaultValue => defaultValue != null;

  Field({
    required String name,
    required this.type,
    required this.isRequired,
    this.description,
    this.defaultValue,
  }) : name = CaseUtil(KeywordHelper.instance.getCorrectKeyword(name)).camelCase;
}
