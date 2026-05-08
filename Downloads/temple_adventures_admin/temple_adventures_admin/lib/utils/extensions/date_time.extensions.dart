import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// Returns time in HH:mm format
  String get formatHHMM {
    final DateFormat formatter = DateFormat('hh:mm a');
    return formatter.format(this);
  }

  /// Returns date in dd-MM-yyyy format
  String get formatDDMMYYYY {
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    return formatter.format(this);
  }

  /// Optional: Returns full date and time (useful sometimes)
  String get formatFullDateTime {
    final DateFormat formatter = DateFormat('dd-MM-yyyy @ hh:mm a');
    return formatter.format(this);
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension DateTimeListX on List<DateTime> {
  bool containsDateOnly(DateTime date) {
    return any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String get formatTimeOfDay {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }
}
