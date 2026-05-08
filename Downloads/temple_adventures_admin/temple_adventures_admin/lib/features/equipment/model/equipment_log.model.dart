import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';

import '../../../utils/mapping_hooks/datetime_hooks.dart';
import '../../user/models/user.model.dart';
import 'equipment_item.model.dart';

part 'equipment_log.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class EquipmentLog with EquipmentLogMappable {
  final int? id;
  final User approverId;
  final User renterId;
  final User? collectorId;
  final List<EquipmentItem> equipmentItem;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime rentedTime;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? collectedTime;

  EquipmentLog({
    this.id,
    required this.renterId,
    required this.approverId,
    required this.equipmentItem,
    this.collectorId,
    required this.rentedTime,
    this.collectedTime,
  });

  Map<String, dynamic> toRow({bool removeId = true}) {
    final equipmentLogMap =
        toMap()
          ..remove('equipment_item')
          ..remove('renter_id')
          ..remove('approver_id')
          ..remove('collector_id');
    if (removeId) equipmentLogMap.remove('id');

    equipmentLogMap['renter_person_id'] = renterId.id;
    equipmentLogMap['approver_person_id'] = approverId.id;
    equipmentLogMap['collector_person_id'] = collectorId?.id;
    return equipmentLogMap;
  }
}
