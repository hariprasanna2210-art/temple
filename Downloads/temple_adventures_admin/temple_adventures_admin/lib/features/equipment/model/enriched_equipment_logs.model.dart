import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';

import '../../../utils/mapping_hooks/datetime_hooks.dart';
import 'equipment_item.model.dart';

part 'enriched_equipment_logs.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class EnrichedEquipmentLogs with EnrichedEquipmentLogsMappable {
  final int logId;
  final String approverName;
  final String? collectorName;
  final String renterName;
  final int renterPersonId;
  final int approverPersonId;
  final int? collectorPersonId;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime? collectedTime;
  @MappableField(hook: DateTimeToLocalHook())
  final DateTime rentedTime;
  final List<EquipmentItem> equipmentItems;

  const EnrichedEquipmentLogs({
    required this.logId,
    required this.approverName,
    required this.collectorName,
    required this.renterName,
    required this.renterPersonId,
    required this.approverPersonId,
    this.collectorPersonId,
    this.collectedTime,
    required this.rentedTime,
    required this.equipmentItems,
  });
}
