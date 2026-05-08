import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';

part 'equipment_category.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class EquipmentCategory with EquipmentCategoryMappable {
  final int? id;
  final String name;
  final bool isDeleted;

  const EquipmentCategory({
    this.id,
    required this.name,
    this.isDeleted = false,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final equipmentCategoryMap = toMap();
    if (removeId) equipmentCategoryMap.remove('id');
    return equipmentCategoryMap;
  }
}
