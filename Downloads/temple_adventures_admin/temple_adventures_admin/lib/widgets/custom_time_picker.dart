import 'package:flutter/material.dart';

class TimePicker {
  static Future<DateTime?> show(BuildContext context, {required DateTime initialTime}) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
    );
    if (pickedTime == null) return null;
    final selectedDateTime = initialTime.copyWith(hour: pickedTime.hour, minute: pickedTime.minute);
    return selectedDateTime;
  }

  static Future<TimeOfDay?> showOnlyTime(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }
}
