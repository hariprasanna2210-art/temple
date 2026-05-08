import 'package:flutter/material.dart';

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }

  Color toNormalColor() {
    final hexCode = replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    } else if (hexCode.length == 8) {
      return Color(int.parse(hexCode, radix: 16));
    } else {
      return Colors.white;
    }
  }

  double toDoubleOrZero() {
    try {
      return double.parse(this);
    } catch (e) {
      return 0.0;
    }
  }

  DateTime? toDateTime() {
    try {
      final parts = split('-');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      return null; // Return null if parsing fails
    }
  }
}

extension StringX on String? {
  String? get stringOrNull {
    if (this == null) return null;
    if (this!.trim().isEmpty) return null;
    return this;
  }
}

extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
