import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:temple_adventures_admin/utils/mapping_hooks/double_conversion.dart';

import 'equipment_item.model.dart';

part 'otp_validation.model.mapper.dart';

@immutable
@MappableClass(hook: DoubleConversionHook())
class OtpValidation with OtpValidationMappable {
  final String? renterID;
  final String? approverID;
  final List<EquipmentItem> equipmentItem;
  final String otp;
  final bool approve;

  const OtpValidation({
    required this.renterID,
    required this.approverID,
    required this.equipmentItem,
    required this.otp,
    required this.approve,
  });
}
