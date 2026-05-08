import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/cupertino.dart';
import 'package:temple_adventures_admin/features/equipment/model/equipment_category.model.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';

import '../../user/models/user.model.dart';

part 'equipment_item.model.mapper.dart';

@immutable
@MappableClass(hook: CombinedEquipmentItemHook())
class EquipmentItem with EquipmentItemMappable {
  final int? id;
  final EquipmentCategory category;
  final String equipmentName;
  final String remarks;
  final String? photo;
  final User? currentRentedPerson;
  final bool isDeleted;

  const EquipmentItem({
    this.id,
    required this.category,
    required this.remarks,
    required this.equipmentName,
    this.currentRentedPerson,
    this.photo,
    this.isDeleted = false,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final equipmentItemMap =
        toMap()
          ..remove('category')
          ..remove('current_rented_person');
    if (removeId) equipmentItemMap.remove('id');
    equipmentItemMap['category_id'] = category.id;
    equipmentItemMap['current_rented_person_id'] = currentRentedPerson?.id;
    return equipmentItemMap;
  }
}
