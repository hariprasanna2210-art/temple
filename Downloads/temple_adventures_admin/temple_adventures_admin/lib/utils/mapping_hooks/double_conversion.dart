import 'package:dart_mappable/dart_mappable.dart';

class DoubleConversionHook extends MappingHook {
  const DoubleConversionHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is num) return value.toDouble();
    return value;
  }
}

class EquipmentItemIdHook extends MappingHook {
  const EquipmentItemIdHook();

  @override
  dynamic beforeDecode(dynamic value) {
    if (value is Map<String, dynamic>) {
      value['id'] ??= value['equipment_item_id'];
    }
    return value;
  }
}

/// Combined hook to apply both conversions
class CombinedEquipmentItemHook extends MappingHook {
  const CombinedEquipmentItemHook();

  @override
  dynamic beforeDecode(dynamic value) {
    value = const DoubleConversionHook().beforeDecode(value);
    value = const EquipmentItemIdHook().beforeDecode(value);
    return value;
  }
}