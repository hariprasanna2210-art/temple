import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';

import '../../../utils/mapping_hooks/double_conversion.dart';

part 'template.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class Template with TemplateMappable {
  final int? id;
  final String title;
  final List<ItemModel> items;

  const Template({
    this.id,
    required this.title,
    required this.items,
  });

  Map<String, dynamic> toRow({bool includeId = false}) {
    final templateMap = toMap()..remove('items');
    if (includeId == false) templateMap.remove('id');
    return templateMap;
  }
}

@immutable
@MappableClass(hook: DoubleConversionHook())
class ItemModel with ItemModelMappable {
  final int? templateId;
  final int index;
  final String name;

  const ItemModel({
    this.templateId,
    required this.index,
    required this.name,
  });
}
