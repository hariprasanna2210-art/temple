import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

class TimeOfDayHook extends MappingHook {
  const TimeOfDayHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  @override
  Object? beforeEncode(Object? value) {
    if (value is TimeOfDay) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return "$hour:$minute:00";
    }
    return null;
  }
}
